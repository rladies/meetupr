test_that("meetup_api_prefix returns the correct default URL", {
  withr::local_envvar(c(MEETUP_API_URL = NULL))
  expect_equal(meetup_api_prefix(), "https://api.meetup.com/gql-ext")
})

test_that("meetup_api_prefix returns custom URL if set", {
  withr::local_envvar(c(MEETUP_API_URL = "https://custom.meetup.com"))
  expect_equal(meetup_api_prefix(), "https://custom.meetup.com")
})

test_that("meetup_req configures request with proper headers", {
  mock_if_no_auth()
  req <- meetup_req()
  expect_equal(httr2::req_get_headers(req)$`Content-Type`, "application/json")
})

test_that("meetup_req handles OAuth authentication", {
  mock_if_no_auth()
  withr::local_envvar(c(
    MEETUP_AUTH_METHOD = "oauth",
    MEETUP_CLIENT_ID = "client_id",
    MEETUP_CLIENT_SECRET = "client_secret"
  ))
  req <- meetup_req(cache = FALSE)
  expect_equal(
    req$policies$auth_sign$params$flow,
    "oauth_flow_auth_code"
  )
})


test_that("meetup_req error handler formats API errors correctly", {
  mock_if_no_auth()

  req <- meetup_req()
  error_handler <- req$policies$error_body

  mock_resp <- structure(list(), class = "httr2_response")

  local_mocked_bindings(
    resp_body_json = function(resp) {
      list(
        errors = list(
          list(message = "Field 'user' not found"),
          list(message = "Invalid argument")
        )
      )
    },
    .package = "httr2"
  )

  result <- error_handler(mock_resp)
  expect_match(result, "Meetup API errors:")
  expect_match(result, "Field 'user' not found")
  expect_match(result, "Invalid argument")
})

test_that("meetup_req error handler handles unknown errors", {
  mock_if_no_auth()

  req <- meetup_req()
  error_handler <- req$policies$error_body

  mock_resp <- structure(list(), class = "httr2_response")

  local_mocked_bindings(
    resp_body_json = function(resp) {
      list(message = "Something went wrong")
    },
    .package = "httr2"
  )

  result <- error_handler(mock_resp)
  expect_equal(result, "Unknown Meetup API error")
})


test_that("meetup_req uses OAuth when method is oauth", {
  withr::local_envvar(
    MEETUP_AUTH_METHOD = "oauth",
    MEETUP_CLIENT_ID = "test_client",
    MEETUP_CLIENT_SECRET = "test_secret"
  )

  mock_client <- structure(
    list(name = "test_client"),
    class = "httr2_oauth_client"
  )

  local_mocked_bindings(
    meetup_auth_status = function(...) TRUE,
    meetup_client = function(...) mock_client
  )

  req <- meetup_req()

  expect_equal(
    req$policies$auth_sign$params$flow,
    "oauth_flow_auth_code"
  )
})


test_that("meetup_query executes GraphQL query successfully", {
  mock_if_no_auth()

  local_mocked_bindings(
    req_perform = function(req) {
      structure(list(status_code = 200), class = "httr2_response")
    },
    resp_body_json = function(resp) {
      list(data = list(user = list(id = "123", name = "Test User")))
    },
    .package = "httr2"
  )

  query <- "query GetUser($id: ID!) { user(id: $id) { id name } }"
  result <- meetup_query(query, id = "123")

  expect_equal(result$data$user$id, "123")
  expect_equal(result$data$user$name, "Test User")
})

test_that("meetup_query handles GraphQL errors", {
  mock_if_no_auth()

  local_mocked_bindings(
    req_perform = function(req) {
      structure(list(status_code = 200), class = "httr2_response")
    },
    resp_body_json = function(resp) {
      list(errors = list(list(message = "User not found")))
    },
    .package = "httr2"
  )

  query <- "query GetUser($id: ID!) { user(id: $id) { id name } }"
  expect_error(
    meetup_query(query, id = "invalid"),
    "Failed to execute GraphQL query"
  )
})

test_that("meetup_query compacts variables", {
  mock_if_no_auth()

  local_mocked_bindings(
    req_perform = function(req) {
      structure(list(status_code = 200), class = "httr2_response")
    },
    resp_body_json = function(resp) {
      list(data = list(user = list(id = "123")))
    },
    .package = "httr2"
  )

  query <- "query GetUser($id: ID!) { user(id: $id) { id } }"
  result <- meetup_query(
    query,
    id = "123",
    empty_var = NULL
  )

  expect_equal(result$data$user$id, "123")
})

test_that("build_request constructs proper GraphQL request", {
  mock_if_no_auth()

  query <- "query GetUser($id: ID!) { user(id: $id) { id } }"
  variables <- list(id = "123")

  req <- build_request(query, variables)

  expect_s3_class(req, "httr2_request")
  expect_equal(req$body$data$query, query)
  expect_equal(req$body$data$variables$id, "123")
})

test_that("build_request handles empty variables", {
  mock_if_no_auth()

  query <- "query { viewer { id } }"
  req <- build_request(query, list())

  expect_s3_class(req, "httr2_request")
  expect_equal(req$body$data$query, query)
  expect_equal(length(req$body$data$variables), 0)
})

test_that("build_request handles NULL variables", {
  mock_if_no_auth()

  query <- "query { viewer { id } }"
  req <- build_request(query, NULL)

  expect_s3_class(req, "httr2_request")
  expect_equal(req$body$data$query, query)
  expect_equal(length(req$body$data$variables), 0)
})

test_that("build_request shows debug output when MEETUPR_DEBUG is set", {
  mock_if_no_auth()

  withr::local_envvar(c(MEETUPR_DEBUG = "1"))

  expect_message(
    {
      query <- "query { viewer { id } }"
      build_request(query, list())
    },
    "DEBUG: JSON to be sent:"
  )
})
