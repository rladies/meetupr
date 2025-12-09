describe("get_client_name()", {
  it("returns client name", {
    withr::local_envvar(MEETUPR_CLIENT_NAME = "test_client")
    expect_equal(get_client_name(), "test_client")
  })
})


describe("meetupr_oauth_flow_params()", {
  it("returns URLs", {
    params <- meetupr_oauth_flow_params()
    expect_type(params, "list")
    expect_true("auth_url" %in% names(params))
    expect_true("redirect_uri" %in% names(params))
  })
})

describe("list_token_files()", {
  it("returns empty for missing dir", {
    temp_dir <- withr::local_tempdir()
    missing_dir <- file.path(temp_dir, "nonexistent")
    expect_equal(list_token_files(missing_dir), character(0))
  })

  it("finds token files", {
    temp_dir <- withr::local_tempdir()
    file.create(file.path(temp_dir, "token1.rds.enc"))
    file.create(file.path(temp_dir, "token2.rds.enc"))
    file.create(file.path(temp_dir, "other.txt"))
    files <- list_token_files(temp_dir)
    expect_length(files, 2)
    expect_true(all(grepl("\\.rds\\.enc$", basename(files))))
  })
})

describe("mock_if_no_auth()", {
  it("mocks when auth is missing", {
    local_mocked_bindings(
      has_auth = function() FALSE
    )
    expect_true(mock_if_no_auth())
    token <- get_jwt_token()
    expect_match(token, "BEGIN RSA PRIVATE KEY")
  })

  it("works end-to-end with meetupr_query", {
    local_mocked_bindings(
      has_auth = function() FALSE
    )

    local_mocked_bindings(
      jwt_encode_sig = function(claims, key, ...) "signed.jwt.mock",
      .package = "httr2"
    )

    mocked <- mock_if_no_auth(force = TRUE)
    expect_true(mocked)

    local_mocked_bindings(
      req_perform = function(req) {
        structure(
          list(status_code = 200),
          class = "httr2_response"
        )
      },
      resp_body_json = function(resp) {
        list(
          data = list(
            viewer = list(id = "123")
          )
        )
      },
      .package = "httr2"
    )
    result <- meetupr_query("query { viewer { id } }")
    expect_equal(result$data$viewer$id, "123")
  })

  it("sets mock env vars when not authenticated", {
    local_mocked_bindings(
      has_auth = function(...) FALSE
    )
    result <- mock_if_no_auth()
    expect_true(result)
    expect_match(Sys.getenv("testclient_jwt_token"), "BEGIN RSA PRIVATE KEY")
    expect_equal(Sys.getenv("testclient_client_key"), "fake_client_key")
    expect_equal(Sys.getenv("testclient_client_secret"), "")
    expect_equal(Sys.getenv("testclient_refresh_token"), "")
    expect_equal(Sys.getenv("testclient_encrypt_pwd"), "")
    expect_equal(Sys.getenv("testclient_encrypt_path"), "")
    expect_equal(Sys.getenv("testclient_jwt_path"), "")
  })

  it("does not set env vars if already authenticated and force = FALSE", {
    local_mocked_bindings(
      has_auth = function(...) TRUE
    )
    env <- new.env()
    result <- mock_if_no_auth(force = FALSE)
    expect_false(result)
    # Should not overwrite existing env vars
    expect_equal(
      Sys.getenv("testclient_jwt_path", unset = "notset"),
      "notset"
    )
  })

  it("forces mocking even if authenticated when force = TRUE", {
    local_mocked_bindings(
      has_auth = function(...) TRUE
    )
    result <- mock_if_no_auth(force = TRUE)
    expect_true(result)
    expect_match(Sys.getenv("testclient_jwt_token"), "BEGIN RSA PRIVATE KEY")
  })

  it("returns invisible TRUE when mocking is applied", {
    local_mocked_bindings(
      has_auth = function(...) FALSE
    )
    expect_invisible(mock_if_no_auth())
  })

  it("returns invisible FALSE when not applied", {
    local_mocked_bindings(
      has_auth = function(...) TRUE
    )
    expect_invisible(mock_if_no_auth(force = FALSE))
  })
})
