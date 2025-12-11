describe("meetupr_encrypt_setup()", {
  it("requires authentication", {
    mock_if_no_auth()
    local_mocked_bindings(
      has_auth = function(...) FALSE
    )
    expect_error(
      meetupr_encrypt_setup(),
      "No authentication found"
    )
  })

  it("generates password if NULL", {
    skip_if_not_installed("cyphr")
    skip_if_not_installed("sodium")
    mock_if_no_auth()
    local_mocked_bindings(
      has_auth = function(...) TRUE
    )
    local_mocked_bindings(
      oauth_token_cached = function(...) {
        structure(
          list(
            access_token = "test",
            refresh_token = "refresh"
          ),
          class = "httr2_token"
        )
      },
      .package = "httr2"
    )
    temp_path <- withr::local_tempfile(fileext = ".rds")
    expect_message(
      password <- meetupr_encrypt_setup(path = temp_path),
      "Encrypted Token Setup Complete"
    )
    expect_type(password, "character")
    expect_equal(nchar(password), 64)
  })

  it("uses provided password", {
    skip_if_not_installed("cyphr")
    skip_if_not_installed("sodium")
    mock_if_no_auth()
    local_mocked_bindings(
      has_auth = function(...) TRUE
    )
    local_mocked_bindings(
      oauth_token_cached = function(...) {
        structure(
          list(
            access_token = "test",
            refresh_token = "refresh"
          ),
          class = "httr2_token"
        )
      },
      .package = "httr2"
    )
    temp_path <- withr::local_tempfile(fileext = ".rds")
    test_pwd <- sodium::bin2hex(sodium::random(32))
    password <- meetupr_encrypt_setup(
      path = temp_path,
      password = test_pwd
    )
    expect_equal(password, test_pwd)
  })

  it("creates encrypted file", {
    skip_if_not_installed("cyphr")
    skip_if_not_installed("sodium")
    mock_if_no_auth()
    local_mocked_bindings(
      has_auth = function(...) TRUE
    )
    local_mocked_bindings(
      oauth_token_cached = function(...) {
        structure(
          list(
            access_token = "test",
            refresh_token = "refresh"
          ),
          class = "httr2_token"
        )
      },
      .package = "httr2"
    )
    temp_path <- withr::local_tempfile(fileext = ".rds")
    suppressMessages(
      meetupr_encrypt_setup(path = temp_path)
    )
    expect_true(file.exists(temp_path))
  })
})

describe("meetupr_encrypt_load()", {
  it("requires encrypted file", {
    skip_if_not_installed("cyphr")
    skip_if_not_installed("sodium")
    mock_if_no_auth()
    path <- withr::local_tempfile(fileext = ".rds")
    local_mocked_bindings(
      meetupr_key_get = function(...) "testpassword"
    )
    expect_error(
      meetupr_encrypt_load(
        path = path,
        client_name = "testclient"
      ),
      "Encrypted token file not found"
    )
  })

  it("requires password", {
    skip_if_not_installed("cyphr")
    skip_if_not_installed("sodium")
    mock_if_no_auth()
    path <- withr::local_tempfile(fileext = ".rds")
    writeLines("test", path)
    local_mocked_bindings(
      meetupr_key_get = function(...) NULL
    )
    withr::local_envvar(
      "testclient_encrypt_pwd" = "",
      "testclient_encrypt_path" = path
    )
    expect_error(
      meetupr_encrypt_load(
        path = path,
        client_name = "testclient"
      ),
      "Encryption password not found"
    )
  })

  it("decrypts token", {
    skip_if_not_installed("cyphr")
    skip_if_not_installed("sodium")
    mock_if_no_auth()
    temp_path <- withr::local_tempfile(fileext = ".rds")
    test_pwd <- sodium::bin2hex(sodium::random(32))
    token <- structure(
      list(
        access_token = "test_access",
        refresh_token = "test_refresh",
        expires_at = unclass(Sys.time() + 3600),
        token_type = "Bearer"
      ),
      class = "httr2_token"
    )
    temp_token <- withr::local_tempfile(fileext = ".rds")
    saveRDS(token, temp_token)
    key <- cyphr::key_sodium(sodium::hex2bin(test_pwd))
    cyphr::encrypt_file(temp_token, key = key, dest = temp_path)
    local_mocked_bindings(
      meetupr_key_get = function(...) test_pwd
    )
    loaded <- meetupr_encrypt_load(path = temp_path)
    expect_s3_class(loaded, "httr2_token")
    expect_equal(loaded$access_token, "test_access")
  })

  it("skips refresh if token valid", {
    skip_if_not_installed("cyphr")
    skip_if_not_installed("sodium")
    mock_if_no_auth()
    temp_path <- withr::local_tempfile(fileext = ".rds")
    test_pwd <- sodium::bin2hex(sodium::random(32))
    token <- structure(
      list(
        access_token = "test_access",
        refresh_token = "test_refresh",
        expires_at = unclass(Sys.time() + 3600),
        token_type = "Bearer"
      ),
      class = "httr2_token"
    )
    temp_token <- withr::local_tempfile(fileext = ".rds")
    saveRDS(token, temp_token)
    key <- cyphr::key_sodium(sodium::hex2bin(test_pwd))
    cyphr::encrypt_file(temp_token, key = key, dest = temp_path)
    local_mocked_bindings(
      meetupr_key_get = function(...) test_pwd,
      check_debug_mode = function() TRUE
    )
    expect_message(
      meetupr_encrypt_load(path = temp_path),
      "Token still valid"
    )
  })

  it("refreshes expired token", {
    skip_if_not_installed("cyphr")
    skip_if_not_installed("sodium")
    mock_if_no_auth()
    temp_path <- withr::local_tempfile(fileext = ".rds")
    test_pwd <- sodium::bin2hex(sodium::random(32))
    token <- structure(
      list(
        access_token = "old_access",
        refresh_token = "old_refresh",
        expires_at = unclass(Sys.time() - 3600),
        token_type = "Bearer"
      ),
      class = "httr2_token"
    )
    temp_token <- withr::local_tempfile(fileext = ".rds")
    saveRDS(token, temp_token)
    key <- cyphr::key_sodium(sodium::hex2bin(test_pwd))
    cyphr::encrypt_file(temp_token, key = key, dest = temp_path)
    local_mocked_bindings(
      meetupr_key_get = function(...) test_pwd,
      check_debug_mode = function() TRUE
    )
    local_mocked_bindings(
      request = function(...) structure(list(), class = "httr2_request"),
      req_body_form = function(req, ...) req,
      req_perform = function(req) structure(list(), class = "httr2_response"),
      resp_body_json = function(...) {
        list(
          access_token = "new_access",
          refresh_token = "new_refresh",
          expires_in = 3600,
          token_type = "Bearer"
        )
      },
      .package = "httr2"
    )
    expect_message(
      new_token <- meetupr_encrypt_load(path = temp_path),
      "Token expired"
    )
    expect_equal(new_token$access_token, "new_access")
  })

  it("handles refresh errors", {
    skip_if_not_installed("cyphr")
    skip_if_not_installed("sodium")
    mock_if_no_auth()
    encrypt_path <- withr::local_tempfile(fileext = ".rds")
    temp_token <- withr::local_tempfile(fileext = ".rds")
    encrypt_pwd <- sodium::bin2hex(sodium::random(32))
    token <- structure(
      list(
        access_token = "old_access",
        refresh_token = "old_refresh",
        expires_at = unclass(Sys.time() - 3600),
        token_type = "Bearer"
      ),
      class = "httr2_token"
    )
    saveRDS(token, temp_token)
    key <- cyphr::key_sodium(sodium::hex2bin(encrypt_pwd))
    cyphr::encrypt_file(
      temp_token,
      key = key,
      dest = encrypt_path
    )
    local_mocked_bindings(
      meetupr_key_get = function(key, ...) {
        if (key == "encrypt_pwd") {
          return(encrypt_pwd)
        }
        NULL
      }
    )
    local_mocked_bindings(
      request = function(...) stop("Network error"),
      .package = "httr2"
    )
    expect_error(
      meetupr_encrypt_load(path = encrypt_path),
      "Failed to refresh OAuth token"
    )
  })
})

describe("get_encrypted_path()", {
  it("returns default when no key is set", {
    local_mocked_bindings(
      meetupr_key_get = function(key, ..., error = FALSE) NULL
    )

    expect_equal(
      get_encrypted_path("test_client"),
      normalize_path(".test_client.rds", mustWork = FALSE)
    )
  })

  it("returns env value if set", {
    withr::local_envvar(
      "testclient_encrypt_path" = "custom_token.rds"
    )
    expect_equal(
      get_encrypted_path("testclient"),
      normalize_path("custom_token.rds", mustWork = FALSE)
    )
  })

  it("errors when no token to encrypt", {
    local_mocked_bindings(
      meetupr_key_get = function(key, client_name, ...) NA_character_
    )

    expect_error(
      meetupr_encrypt_setup(client_name = "testclient"),
      "No authentication found"
    )
  })
})

describe("get_jwt_token()", {
  it("returns jwt_token argument if supplied", {
    token <- get_jwt_token(jwt_token = "header.payload.signature")
    expect_equal(
      token,
      "header.payload.signature"
    )
  })

  it("returns from env if jwt_token is empty", {
    withr::local_envvar(
      "MEETUPR_CLIENT_NAME" = "testclient",
      "testclient_jwt_token" = "header.payload.signature"
    )
    token <- get_jwt_token()
    expect_equal(as.character(token), "header.payload.signature")
  })

  it("reads from default path if all else fails", {
    temp_dir <- withr::local_tempdir()
    default_path <- file.path(temp_dir, ".ssh/meetupr.rsa")
    dir.create(dirname(default_path), recursive = TRUE)
    writeLines("header.payload.signature", default_path)
    withr::local_envvar(
      MEETUPR_CLIENT_NAME = NA
    )
    local_mocked_bindings(
      meetupr_key_get = function(...) NA
    )
    local_mocked_bindings(
      path_home = function() temp_dir,
      .package = "fs"
    )
    token <- get_jwt_token(jwt_token = NULL)
    expect_equal(
      normalize_path(token),
      normalize_path(default_path)
    )
  })

  it("returns NA if no token found", {
    temp_dir <- withr::local_tempdir()
    local_mocked_bindings(
      meetupr_key_get = function(...) NA,
    )
    local_mocked_bindings(
      path_home = function() temp_dir,
      .package = "fs"
    )
    expect_true(is.na(get_jwt_token(jwt_token = NULL)))
  })
})

describe("get_jwt_path()", {
  it("returns path if set", {
    tmp <- withr::local_tempfile()
    writeLines("header.payload.signature", tmp)
    tmp <- normalize_path(tmp)
    withr::local_envvar(
      "testclient_jwt_token" = tmp
    )
    expect_equal(
      get_jwt_path("testclient"),
      tmp
    )
  })

  it("returns default path if not set", {
    temp_dir <- withr::local_tempdir() |>
      normalize_path(mustWork = FALSE)
    default_path <- file.path(temp_dir, ".ssh/testclient.rsa")
    default_path <- normalize_path(default_path)
    dir.create(dirname(default_path), recursive = TRUE)

    local_mocked_bindings(
      meetupr_key_get = function(...) NA
    )
    local_mocked_bindings(
      path_home = function() temp_dir,
      .package = "fs"
    )
    expect_equal(
      get_jwt_path("testclient"),
      default_path
    )
  })
})
