library(testthat)
library(meetupr)
library(httr2)
library(openssl)

describe("meetupr_api_urls()", {
  it("returns the correct default URL", {
    withr::local_envvar(c(MEETUP_API_URL = NA))
    urls <- meetupr_api_urls()
    expect_equal(urls$api, "https://api.meetup.com/gql-ext")
    expect_named(urls, c("api", "auth", "token", "redirect"))
  })

  it("returns custom URL if set", {
    withr::local_envvar(
      c(MEETUP_API_URL = "https://custom.meetup.com")
    )
    expect_equal(
      meetupr_api_urls()$api,
      "https://custom.meetup.com"
    )
  })
})

describe("build_request()", {
  it("constructs proper GraphQL request with variables", {
    local_mocked_bindings(
      meetupr_req = function() structure(list(), class = "httr2_request")
    )
    local_mocked_bindings(
      req_body_json = function(req, body_list, auto_unbox = TRUE) {
        req$body <- list(data = body_list)
        req
      },
      .package = "httr2"
    )

    query <- "query { viewer { id } }"
    variables <- list(id = "123")
    req <- build_request(query, variables)
    expect_s3_class(req, "httr2_request")
    expect_equal(req$body$data$query, query)
    expect_equal(req$body$data$variables$id, "123")
  })

  it("handles empty and NULL variables as empty object", {
    local_mocked_bindings(
      meetupr_req = function() structure(list(), class = "httr2_request")
    )
    local_mocked_bindings(
      req_body_json = function(req, body_list, auto_unbox = TRUE) {
        req$body <- list(data = body_list)
        req
      },
      .package = "httr2"
    )

    q <- "query { viewer { id } }"
    r1 <- build_request(q, list())
    expect_equal(length(r1$body$data$variables), 0)

    r2 <- build_request(q, NULL)
    expect_equal(length(r2$body$data$variables), 0)
  })
})

describe("handle_api_error()", {
  it("formats GraphQL errors", {
    local_mocked_bindings(
      resp_body_json = function(resp) {
        list(
          errors = list(
            list(message = "Field 'x' not found"),
            list(message = "Invalid input")
          )
        )
      },
      .package = "httr2"
    )
    mock_resp <- structure(list(), class = "httr2_response")
    msg <- handle_api_error(mock_resp)
    expect_match(msg, "Meetup API errors:")
    expect_match(msg, "Field 'x' not found")
    expect_match(msg, "Invalid input")
  })

  it("returns generic message for unknown shapes", {
    local_mocked_bindings(
      resp_body_json = function(resp) {
        list(message = "Something went wrong")
      },
      .package = "httr2"
    )
    mock_resp <- structure(list(), class = "httr2_response")
    expect_equal(handle_api_error(mock_resp), "Unknown Meetup API error")
  })
})

describe("meetupr_query()", {
  it("executes GraphQL query successfully", {
    local_mocked_bindings(
      req_perform = function(req) {
        structure(list(status_code = 200), class = "httr2_response")
      },
      resp_body_json = function(resp) {
        list(data = list(user = list(id = "123", name = "X")))
      },
      .package = "httr2"
    )

    q <- "query { user { id name } }"
    res <- meetupr_query(q)
    expect_equal(res$data$user$id, "123")
    expect_equal(res$data$user$name, "X")
  })

  it("errors on GraphQL errors", {
    local_mocked_bindings(
      req_perform = function(req) {
        structure(list(status_code = 200), class = "httr2_response")
      },
      resp_body_json = function(resp) {
        list(errors = list(list(message = "User not found")))
      },
      .package = "httr2"
    )

    q <- "query { user { id } }"
    expect_error(
      meetupr_query(q),
      "Failed to execute GraphQL query"
    )
  })

  it("compacts variables by removing NULLs", {
    local_mocked_bindings(
      req_perform = function(req) {
        structure(list(status_code = 200), class = "httr2_response")
      },
      resp_body_json = function(resp) {
        list(data = list(user = list(id = "1")))
      },
      .package = "httr2"
    )

    q <- "query { user { id } }"
    res <- meetupr_query(q, id = "1", empty = NULL)
    expect_equal(res$data$user$id, "1")
  })
})

describe("meetupr_req() and req_auth()", {
  it("applies headers and throttling", {
    local_mocked_bindings(
      req_auth = function(req, ...) req
    )
    local_mocked_bindings(
      request = function(url) {
        structure(list(url = url), class = "httr2_request")
      },
      req_headers = function(req, ...) {
        req$headers <- list(...)
        req
      },
      req_error = function(req, body) req,
      req_throttle = function(req, rate) {
        req$rate <- rate
        req
      },
      .package = "httr2"
    )

    r <- meetupr_req(rate_limit = 1, cache = FALSE)
    expect_s3_class(r, "httr2_request")
    expect_equal(r$headers[["Content-Type"]], "application/json")
    expect_equal(r$rate, 1)
  })

  it("uses JWT auth when available", {
    local_mocked_bindings(
      meetupr_auth_status = function(...) {
        list(
          jwt = list(
            available = TRUE,
            value = "path/to/jwt.pem",
            issuer = "issuer-id",
            id = "KID123",
            client_key = "client-key"
          )
        )
      }
    )

    base <- structure(list(), class = "httr2_request")
    res <- req_auth(base)
    expect_s3_class(res, "httr2_request")
    expect_true(res$policies$auth_oauth)
    expect_s3_class(
      res$policies$auth_sign$params$flow_params$claim,
      "jwt_claim"
    )
  })

  it("uses encrypted token when available", {
    local_mocked_bindings(
      meetupr_key_get = function(...) NULL,
      meetupr_encrypt_load = function(...) "path/to/encrypted_token",
    )
    local_mocked_bindings(
      req_auth_bearer_token = function(req, ...) {
        message("Using encrypted token auth")
        req$auth_token <- "enc-token"
        req
      },
      .package = "httr2"
    )

    base <- structure(list(), class = "httr2_request")
    res <- req_auth(base)

    expect_equal(res$auth_token, "enc-token")
  })

  it("falls back to oauth auth code flow when no tokens", {
    local_mocked_bindings(
      meetupr_key_get = function(...) NULL,
      meetupr_encrypt_load = function(...) NULL,
      meetupr_oauth_flow_params = function() {
        list(
          auth_url = "https://a",
          redirect_uri = "http://r"
        )
      }
    )
    local_mocked_bindings(
      req_oauth_auth_code = function(
        req,
        client,
        auth_url,
        redirect_uri,
        cache_disk = TRUE
      ) {
        list(oauth = TRUE, auth_url = auth_url, redirect = redirect_uri)
      },
      .package = "httr2"
    )

    base <- structure(list(), class = "httr2_request")
    res <- req_auth(base)
    expect_true(is.list(res))
    expect_true(res$oauth)
    expect_equal(res$auth_url, "https://a")
  })

  test_that("meetupr_req uses JWT auth when jwt available", {
    # generate a temporary RSA key (written to a temp pem file)
    pem_path <- withr::local_tempfile(fileext = ".pem")
    key <- openssl::rsa_keygen()
    openssl::write_pem(key, pem_path)

    fake_auth <- list(
      jwt = list(
        available = TRUE,
        value = pem_path,
        issuer = "251470805",
        id = "TESTKID",
        client_key = "sr_test_client"
      )
    )

    local_mocked_bindings(
      meetupr_auth_status = function(...) fake_auth
    )

    local_mocked_bindings(
      req_oauth_bearer_jwt = function(req, ...) {
        attr(req, "jwt_attached") <- TRUE
        req
      },
      .package = "httr2"
    )

    req <- meetupr_req(cache = FALSE)
    expect_true(inherits(req, "httr2_request"))
    expect_true(isTRUE(attr(req, "jwt_attached")))
  })

  test_that("meetupr_query aborts on GraphQL errors", {
    # Mock build_request to produce a harmless request object
    local_mocked_bindings(
      build_request = function(graphql, variables = list()) {
        httr2::request("https://api.meetup.test/gql")
      }
    )

    # Mock httr2::resp_body_json to return a GraphQL error payload
    local_mocked_bindings(
      resp_body_json = function(resp, ...) {
        list(errors = list(list(message = "simulated graphql error")))
      },
      .package = "httr2"
    )

    expect_error(
      meetupr_query("query { dummy }"),
      "Failed to execute GraphQL query"
    )
  })
})
