describe("meetupr_client()", {
  it("returns a valid oauth client", {
    mock_if_no_auth()
    local_mocked_bindings(
      meetupr_key_get = function(key, error = TRUE, ...) {
        switch(
          key,
          client_key = "client_key",
          client_secret = "client_secret",
          NULL
        )
      }
    )
    withr::local_envvar(MEETUPR_CLIENT_NAME = "test_client")
    client <- meetupr_client()
    expect_equal(client$id, "client_key")
    expect_equal(client$secret, "client_secret")
    expect_equal(client$name, "test_client")
  })

  it("defaults built-ins", {
    mock_auth()
    withr::local_envvar(
      "testclient_client_key" = NA
    )
    client <- meetupr_client()
    expect_equal(client$id, builtin_client$id)
    expect_equal(client$secret, builtin_client$secret)
  })

  it("falls back to builtin when keyring fails", {
    local_mocked_bindings(
      meetupr_key_get = function(key, error = TRUE, ...) {
        if (error) stop("No key found") else NULL
      }
    )
    client <- meetupr_client()
    expect_equal(client$id, builtin_client$id)
    expect_equal(client$secret, builtin_client$secret)
  })

  it("passes additional arguments to oauth_client", {
    client <- meetupr_client(
      client_key = "test_id",
      client_secret = "test_secret"
    )
    expect_equal(client$id, "test_id")
    expect_equal(client$secret, "test_secret")
  })

  it("uses provided client_key and client_secret", {
    client <- meetupr_client(
      client_key = "custom_id",
      client_secret = "custom_secret"
    )
    expect_equal(client$id, "custom_id")
    expect_equal(client$secret, "custom_secret")
  })

  it("uses builtin credentials", {
    mock_if_no_auth()
    client <- meetupr_client()
    expect_s3_class(client, "httr2_oauth_client")
    expect_equal(client$name, "testclient")
  })
})

describe("meetupr_auth_status()", {
  it("returns FALSE if no tokens found", {
    withr::local_envvar("test_client_jwt_token" = "")
    local_mocked_bindings(
      meetupr_key_get = function(key, error = FALSE, ...) NULL,
      list_token_files = function(...) character(0)
    )
    expect_message(
      res <- meetupr_auth_status(silent = FALSE),
      "Not authenticated"
    )
    expect_false(res$auth$any)
  })

  it("handles multiple tokens", {
    withr::local_envvar(
      "MEETUPR_CLIENT_NAME" = "testclient"
    )
    temp_dir <- withr::local_tempdir()
    local_mocked_bindings(
      oauth_cache_path = function() temp_dir,
      .package = "httr2"
    )
    local_mocked_bindings(
      meetupr_key_get = function(key, error = FALSE, ...) NULL
    )
    cache_path <- file.path(temp_dir, "testclient")
    dir.create(cache_path)
    files <- sprintf("%s/%s.rds.enc", cache_path, c("token1", "token2"))
    sapply(files, function(x) writeLines("", x))
    expect_message(
      res <- meetupr_auth_status(),
      "Multiple token files found in cache"
    )
    expect_true(res$auth$any)
    expect_length(res$cache$files, 2)
  })

  it("returns TRUE with single token", {
    temp_dir <- withr::local_tempdir()
    withr::local_envvar(
      "MEETUPR_CLIENT_NAME" = "testclient"
    )
    local_mocked_bindings(
      oauth_cache_path = function() temp_dir,
      .package = "httr2"
    )
    local_mocked_bindings(
      meetupr_key_get = function(key, error = FALSE, ...) NULL
    )
    cache_path <- file.path(temp_dir, "testclient")
    dir.create(cache_path)
    token_path <- file.path(cache_path, "token.rds.enc")
    writeLines("", token_path)
    expect_message(
      res <- meetupr_auth_status(silent = FALSE),
      "Token found"
    )
    expect_true(res$auth$any)
  })

  it("silent mode suppresses messages", {
    temp_dir <- withr::local_tempdir()
    withr::local_envvar(
      "MEETUPR_CLIENT_NAME" = "testclient"
    )
    local_mocked_bindings(
      oauth_cache_path = function() temp_dir,
      .package = "httr2"
    )
    local_mocked_bindings(
      meetupr_key_get = function(key, error = FALSE, ...) NULL
    )
    cache_path <- file.path(temp_dir, "testclient")
    dir.create(cache_path)
    writeLines("", file.path(cache_path, "token.rds.enc"))
    expect_silent(
      res <- meetupr_auth_status(silent = TRUE)
    )
    expect_true(res$auth$any)
  })

  it("returns TRUE with JWT token", {
    local_mocked_bindings(
      meetupr_key_get = function(key, ...) {
        switch(
          key,
          "jwt_token" = "header.payload.signature",
          "client_key" = "fake_client",
          "jwt_issuer" = "fake_issuer",
          NULL
        )
      }
    )
    res <- meetupr_auth_status(silent = FALSE)

    expect_true(res$auth$any)
    expect_true(res$jwt$available)
  })

  it("returns TRUE with legacy cache", {
    temp_dir <- withr::local_tempdir()
    withr::local_envvar(
      "MEETUPR_CLIENT_NAME" = "testclient"
    )
    cache_path <- file.path(temp_dir, "testclient")
    dir.create(cache_path)
    token_file <- file.path(cache_path, "token.rds.enc")
    writeLines("", token_file)
    local_mocked_bindings(
      get_jwt_token = function(...) NULL,
      meetupr_key_get = function(key, ...) NULL
    )
    local_mocked_bindings(
      oauth_cache_path = function() temp_dir,
      .package = "httr2"
    )
    expect_message(
      res <- meetupr_auth_status(silent = FALSE),
      "Token found"
    )
    expect_true(res$auth$any)
  })

  it("reports jwt available when meetupr_auth_jwt returns token", {
    mock_auth()
    local_mocked_bindings(
      get_cached_token = function(client) NULL
    )

    st <- meetupr_auth_status("testclient", silent = TRUE)
    expect_true(st$auth$any)
    expect_true(st$jwt$available)
  })
  it("returns no auth when none available", {
    local_mocked_bindings(
      meetupr_key_get = function(k, client_name, ...) NA_character_,
      get_cached_token = function(client) NULL
    )

    st <- meetupr_auth_status("testclient", silent = TRUE)
    expect_false(st$auth$any)
  })
})

describe("has_auth()", {
  it("returns TRUE when authenticated", {
    withr::local_envvar(
      "MEETUPR_CLIENT_NAME" = "testclient"
    )
    temp_dir <- withr::local_tempdir()
    temp_token <- file.path(temp_dir, "testclient", "token.rds.enc")
    dir.create(dirname(temp_token), recursive = TRUE)
    writeLines("token", temp_token)
    local_mocked_bindings(
      oauth_cache_path = function() temp_dir,
      .package = "httr2"
    )
    local_mocked_bindings(
      meetupr_key_get = function(key, error = FALSE, ...) NULL
    )
    result <- has_auth()
    expect_true(result)
  })

  it("returns TRUE with refresh token", {
    withr::local_envvar(
      "MEETUPR_CLIENT_NAME" = "test_client",
      "test_client_jwt_token" = "test_jwt_token"
    )

    result <- has_auth()
    expect_true(result)
  })

  it("returns FALSE when not authenticated", {
    withr::local_envvar("testclient_refresh_token" = "")
    local_mocked_bindings(
      meetupr_key_get = function(key, error = FALSE, ...) NULL,
      list_token_files = function(...) character(0)
    )
    result <- has_auth()
    expect_false(result)
  })
})

describe("meetupr_auth()", {
  it("authenticates and displays user name", {
    mock_resp <- list(
      data = list(
        self = list(name = "Test User")
      )
    )
    mock_client <- structure(
      list(name = "test_client"),
      class = "httr2_oauth_client"
    )
    local_mocked_bindings(
      meetupr_req = function(...) structure(list(), class = "httr2_request"),
      meetupr_client = function(...) mock_client
    )
    local_mocked_bindings(
      req_body_json = function(req, ...) req,
      req_perform = function(req) structure(list(), class = "httr2_response"),
      resp_body_json = function(...) mock_resp,
      .package = "httr2"
    )
    expect_message(
      meetupr_auth(),
      "Authenticated as"
    )
  })

  it("handles authentication failure gracefully", {
    local_mocked_bindings(
      get_self = function() stop("API error")
    )
    expect_message(
      result <- meetupr_auth(),
      "Authentication failed"
    )
    expect_null(result)
  })

  it("returns user object on success", {
    mock_user <- structure(
      list(
        id = "123",
        name = "Test User",
        email = "test@example.com"
      ),
      class = c("meetupr_user", "list")
    )
    local_mocked_bindings(
      get_self = function() mock_user
    )
    expect_message(
      result <- meetupr_auth(),
      "Authenticated as.*Test User"
    )
    expect_equal(result$name, "Test User")
  })

  it("returns user data on success", {
    mock_if_no_auth()
    local_mocked_bindings(
      get_self = function() {
        list(name = "Test User", id = "12345")
      }
    )
    user <- meetupr_auth()
    expect_type(user, "list")
    expect_equal(user$name, "Test User")
  })

  it("handles errors gracefully", {
    mock_if_no_auth()
    local_mocked_bindings(
      get_self = function() {
        stop("API error")
      }
    )
    expect_message(
      result <- meetupr_auth(),
      "Authentication failed"
    )
    expect_null(result)
  })
})

describe("meetupr_deauth()", {
  it("handles missing cache directory", {
    mock_auth()
    temp_dir <- withr::local_tempdir()
    local_mocked_bindings(
      oauth_cache_path = function() temp_dir,
      .package = "httr2"
    )
    expect_message(
      meetupr_deauth(),
      "No authentication cache"
    )
  })

  it("skips unavailable keys", {
    temp_dir <- withr::local_tempdir()
    cache_dir <- file.path(temp_dir, "testclient")
    dir.create(cache_dir, recursive = TRUE)
    local_mocked_bindings(
      oauth_cache_path = function() temp_dir,
      .package = "httr2"
    )
    local_mocked_bindings(
      key_available = function(key, ...) FALSE
    )
    expect_message(
      meetupr_deauth(),
      "Authentication cache removed"
    )
  })

  it("removes cache directory", {
    cache_dir <- withr::local_tempdir()
    local_mocked_bindings(
      oauth_cache_path = function() cache_dir,
      .package = "httr2"
    )
    dir.create(file.path(cache_dir, "test_client"))
    expect_message(
      meetupr_deauth(client_name = "test_client"),
      "Authentication cache removed"
    )
    expect_false(
      dir.exists(file.path(cache_dir, "test_client"))
    )
  })

  it("handles missing cache", {
    cache_dir <- withr::local_tempdir()
    local_mocked_bindings(
      oauth_cache_path = function() cache_dir,
      .package = "httr2"
    )
    expect_message(
      meetupr_deauth(),
      "No authentication cache to remove"
    )
  })

  it("reports when no cache dir exists", {
    td <- withr::local_tempdir()
    local_mocked_bindings(
      oauth_cache_path = function() td,
      .package = "httr2"
    )

    expect_message(meetupr_deauth("missing-client"))
  })

  it("removes cache dir and unsets env keys", {
    td <- withr::local_tempdir()
    client_dir <- file.path(td, "testclient")
    dir.create(client_dir, recursive = TRUE)
    file.create(file.path(client_dir, "t"))

    withr::local_envvar(
      "MEETUPR_CLIENT_NAME" = "testclient",
      "testclient_client_key" = "id",
      "testclient_jwt_token" = "j"
    )

    local_mocked_bindings(
      oauth_cache_path = function() td,
      .package = "httr2"
    )

    meetupr_deauth("testclient")
    expect_false(dir.exists(client_dir))
    expect_equal(
      Sys.getenv("testclient_client_key", unset = "notset"),
      "notset"
    )
    expect_equal(Sys.getenv("testclient_jwt_token", unset = "notset"), "notset")
  })
})

describe("list_token_files()", {
  it("returns empty vector when no cache_path", {
    non_existent_path <- file.path(
      tempdir(),
      "does-not-exist-12345"
    )
    result <- list_token_files(non_existent_path)
    expect_type(result, "character")
    expect_length(result, 0)
  })

  it("finds encrypted token files with default pattern", {
    temp_cache <- withr::local_tempdir()
    token_file <- file.path(temp_cache, "test_token.rds.enc")
    other_file <- file.path(temp_cache, "other_file.txt")
    writeBin(raw(), token_file)
    writeBin(raw(), other_file)
    result <- list_token_files(temp_cache)
    expect_length(result, 1)
    expect_equal(basename(result), "test_token.rds.enc")
    expect_true(grepl("\\.rds\\.enc$", result))
  })

  it("finds multiple token files", {
    temp_cache <- withr::local_tempdir()
    token1 <- file.path(temp_cache, "token1.rds.enc")
    token2 <- file.path(temp_cache, "token2.rds.enc")
    writeBin(raw(), token1)
    writeBin(raw(), token2)
    result <- list_token_files(temp_cache)
    expect_length(result, 2)
    expect_true(all(grepl("\\.rds\\.enc$", result)))
  })

  it("respects custom pattern", {
    temp_cache <- withr::local_tempdir()
    enc_file <- file.path(temp_cache, "token.rds.enc")
    json_file <- file.path(temp_cache, "token.json")
    txt_file <- file.path(temp_cache, "token.txt")
    writeBin(raw(), enc_file)
    writeBin(raw(), json_file)
    writeBin(raw(), txt_file)
    result <- list_token_files(
      temp_cache,
      pattern = "\\.json$"
    )
    expect_length(result, 1)
    expect_equal(basename(result), "token.json")
  })

  it("returns full paths", {
    temp_cache <- withr::local_tempdir()
    token_file <- file.path(temp_cache, "token.rds.enc")
    writeBin(raw(), token_file)
    result <- list_token_files(temp_cache)
    expect_true(file.exists(result))
    expect_equal(
      normalize_path(result),
      normalize_path(token_file)
    )
  })

  it("returns empty vector when no matching files", {
    temp_cache <- withr::local_tempdir()
    other_file <- file.path(temp_cache, "not_a_token.txt")
    writeBin(raw(), other_file)
    result <- list_token_files(temp_cache)
    expect_type(result, "character")
    expect_length(result, 0)
  })

  it("handles empty directory", {
    temp_cache <- withr::local_tempdir()
    result <- list_token_files(temp_cache)
    expect_type(result, "character")
    expect_length(result, 0)
  })

  it("finds multiple tokens", {
    temp_cache <- withr::local_tempdir()
    client_cache <- file.path(temp_cache, "meetupr")
    dir.create(client_cache, recursive = TRUE)
    token1 <- file.path(client_cache, "token1.rds.enc")
    token2 <- file.path(client_cache, "token2.rds.enc")
    writeBin(raw(), token1)
    writeBin(raw(), token2)
    local_mocked_bindings(
      oauth_cache_path = function() temp_cache,
      .package = "httr2"
    )
    local_mocked_bindings(
      meetupr_key_get = function(key, ...) NULL
    )
    toks <- list_token_files(client_cache)
    expect_length(toks, 2)
  })
})

describe("get_client_name()", {
  it("returns default", {
    withr::local_envvar(MEETUPR_CLIENT_NAME = NA)
    expect_equal(get_client_name(), "meetupr")
  })

  it("respects env var", {
    withr::local_envvar(MEETUPR_CLIENT_NAME = "custom")
    expect_equal(get_client_name(), "custom")
  })
})
