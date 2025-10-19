test_that("meetup_client returns a valid oauth client", {
  mock_if_no_auth()
  local_mocked_bindings(
    meetup_key_get = function(key, error = TRUE) {
      switch(
        key,
        client_id = "client_id",
        client_secret = "client_secret",
      )
    }
  )
  withr::local_envvar(
    MEETUP_CLIENT_NAME = "test_client"
  )
  client <- meetup_client()
  expect_equal(client$id, "client_id")
  expect_equal(client$secret, "client_secret")
  expect_equal(client$name, "test_client")
})

test_that("meetup_client defaults built-ins", {
  client <- meetup_client()
  expect_equal(client$id, meetupr_client$id)
  expect_equal(client$secret, meetupr_client$secret)
})

test_that("token_path finds token", {
  temp_cache <- withr::local_tempdir()
  file <- file.path(temp_cache, "meetupr", "test_token.rds.enc")
  dir.create(dirname(file), recursive = TRUE)
  writeBin(raw(), file)

  local_mocked_bindings(
    oauth_cache_path = function() temp_cache,
    .package = "httr2"
  )
  expect_equal(token_path(client_name = "meetupr"), file)
})

test_that("token_path handles no or multiple tokens", {
  temp_cache <- withr::local_tempdir()
  local_mocked_bindings(
    oauth_cache_path = function() temp_cache,
    .package = "httr2"
  )

  expect_error(token_path(client_name = "meetupr"))

  file <- file.path(temp_cache, "meetupr", "token1.rds.enc")
  dir.create(dirname(file), recursive = TRUE)
  writeBin(raw(), file)

  file2 <- file.path(temp_cache, "meetupr", "token2.rds.enc")
  writeBin(raw(), file2)

  expect_error(token_path(client_name = "meetupr"))
})

test_that("meetup_auth_status returns FALSE", {
  local_mocked_bindings(
    oauth_cache_path = function() local_tempdir(),
    .package = "httr2"
  )
  expect_message(
    res <- meetup_auth_status(silent = FALSE),
    "Not authenticated: No token cache found"
  )
  expect_false(res)
})

test_that("meetup_auth_status returns FALSE if no tokens are found", {
  temp_dir <- local_tempdir()
  local_mocked_bindings(
    oauth_cache_path = function() temp_dir,
    .package = "httr2"
  )
  dir.create(file.path(temp_dir, "meetupr"))
  expect_message(
    res <- meetup_auth_status(silent = FALSE),
    "Not authenticated: No token found"
  )
  expect_false(res)
})

test_that("meetup_auth_status handles multiple tokens", {
  temp_dir <- local_tempdir()
  local_mocked_bindings(
    oauth_cache_path = function() temp_dir,
    .package = "httr2"
  )
  cache_path <- file.path(temp_dir, "meetupr")
  dir.create(cache_path)
  files <- sprintf(
    "%s/%s.rds.enc",
    cache_path,
    c("token1", "token2")
  )

  sapply(files, function(x) writeLines("", x))
  expect_warning(
    res <- meetup_auth_status(silent = FALSE),
    "Multiple tokens found in"
  )
  expect_true(res)
})

test_that("meetup_auth_status returns TRUE with single token", {
  temp_dir <- local_tempdir()
  local_mocked_bindings(
    oauth_cache_path = function() temp_dir,
    .package = "httr2"
  )
  cache_path <- file.path(temp_dir, "meetupr")
  dir.create(cache_path)
  token_path <- file.path(cache_path, "token.rds.enc")
  writeLines("", token_path)
  expect_message(
    res <- meetup_auth_status(silent = FALSE),
    "Token found:"
  )
  expect_true(res)
})

test_that("meetup_auth_status silent mode suppresses messages", {
  temp_dir <- local_tempdir()
  local_mocked_bindings(
    oauth_cache_path = function() temp_dir,
    .package = "httr2"
  )
  cache_path <- file.path(temp_dir, "meetupr")
  dir.create(cache_path)
  writeLines("", file.path(cache_path, "token.rds.enc"))
  expect_silent(res <- meetup_auth_status(silent = TRUE))
  expect_true(res)
})

test_that("meetup_client uses built-in credentials when env vars empty", {
  withr::local_envvar(
    `meetup:client_id` = "",
    `meetup:client_secret` = ""
  )

  local_mocked_bindings(
    meetupr_client = list(
      id = "builtin_key",
      secret = "builtin_secret"
    )
  )

  client <- meetup_client()

  expect_s3_class(client, "httr2_oauth_client")
})

test_that("meetup_ci_setup encodes token successfully", {
  skip_on_cran()
  temp_dir <- withr::local_tempdir()
  temp_token <- file.path(temp_dir, "token.rds.enc")
  writeBin(charToRaw("test_token_data"), temp_token)

  local_mocked_bindings(
    meetup_auth_status = function() invisible(TRUE),
    token_path = function(...) temp_token
  )

  result <- meetup_ci_setup()

  expect_type(result, "character")
  expect_gt(nchar(result), 0)
})

test_that("meetup_ci_setup copies to clipboard when available", {
  skip_on_cran()
  temp_dir <- withr::local_tempdir()
  temp_token <- file.path(temp_dir, "token.rds.enc")
  writeBin(charToRaw("test_token_data"), temp_token)

  clipboard_called <- FALSE

  local_mocked_bindings(
    meetup_auth_status = function() invisible(TRUE),
    token_path = function(...) temp_token
  )

  withr::with_package("rlang", {
    local_mocked_bindings(
      is_installed = function(...) TRUE,
      .package = "rlang"
    )
  })

  withr::with_package("clipr", {
    local_mocked_bindings(
      clipr_available = function() TRUE,
      write_clip = function(...) {
        clipboard_called <<- TRUE
      },
      .package = "clipr"
    )
  })

  result <- meetup_ci_setup()

  expect_true(clipboard_called)
})

test_that("meetup_ci_load decodes and saves token successfully", {
  skip_on_cran()
  temp_dir <- withr::local_tempdir()

  test_token <- "test_token_content"
  encoded <- base64enc::base64encode(charToRaw(test_token))

  withr::local_envvar(
    `meetupr:token` = encoded,
    `meetupr:token_file` = "token.rds.enc"
  )

  local_mocked_bindings(
    oauth_cache_path = function() temp_dir,
    .package = "httr2"
  )
  expect_message(
    result <- meetup_ci_load(client_name = "test_client"),
    "Token loaded successfully"
  )
  expect_true(result)
})

test_that("meetup_client falls back to builtin when keyring fails", {
  local_mocked_bindings(
    meetup_key_get = function(key, error = TRUE, ...) {
      if (error) {
        stop("No key found")
      } else {
        NULL
      }
    }
  )

  client <- meetup_client()

  expect_equal(client$id, meetupr_client$id)
  expect_equal(client$secret, meetupr_client$secret)
})

test_that("meetup_deauth skips keyring when clear_keyring is FALSE", {
  temp_dir <- withr::local_tempdir()
  cache_path <- file.path(temp_dir, "meetupr")
  dir.create(cache_path)

  keyring_called <- FALSE

  local_mocked_bindings(
    oauth_cache_path = function() temp_dir,
    .package = "httr2"
  )

  local_mocked_bindings(
    key_delete = function(...) {
      keyring_called <<- TRUE
    },
    .package = "keyring"
  )

  meetup_deauth(clear_keyring = FALSE)

  expect_false(keyring_called)
})

test_that("has_auth returns TRUE when authenticated", {
  temp_dir <- withr::local_tempdir()
  temp_token <- file.path(temp_dir, "meetupr", "token.rds.enc")
  dir.create(dirname(temp_token), recursive = TRUE)
  writeLines("token", temp_token)

  local_mocked_bindings(
    oauth_cache_path = function() temp_dir,
    .package = "httr2"
  )

  result <- has_auth()

  expect_true(result)
})

test_that("has_auth returns FALSE when not authenticated", {
  temp_dir <- withr::local_tempdir()

  local_mocked_bindings(
    oauth_cache_path = function() temp_dir,
    .package = "httr2"
  )

  result <- has_auth()

  expect_false(result)
})

test_that("meetup_auth authenticates and displays user name", {
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
    meetup_req = function(...) {
      structure(list(), class = "httr2_request")
    },
    meetup_client = function(...) mock_client
  )

  local_mocked_bindings(
    req_body_json = function(req, ...) req,
    req_perform = function(req) structure(list(), class = "httr2_response"),
    resp_body_json = function(...) mock_resp,
    .package = "httr2"
  )

  expect_message(
    meetup_auth(),
    "Authenticated as"
  )
})

test_that("meetup_deauth removes cache directory", {
  temp_dir <- withr::local_tempdir()
  cache_dir <- file.path(temp_dir, "meetupr")
  dir.create(cache_dir, recursive = TRUE)
  writeLines("token", file.path(cache_dir, "token.rds.enc"))

  local_mocked_bindings(
    oauth_cache_path = function() temp_dir,
    .package = "httr2"
  )

  meetup_deauth(clear_keyring = FALSE)

  expect_false(dir.exists(cache_dir))
})

test_that("meetup_deauth handles missing cache directory", {
  temp_dir <- withr::local_tempdir()

  local_mocked_bindings(
    oauth_cache_path = function() temp_dir,
    .package = "httr2"
  )

  expect_message(
    meetup_deauth(clear_keyring = FALSE),
    "No authentication cache"
  )
})

test_that("meetup_deauth clears keyring when requested", {
  temp_dir <- withr::local_tempdir()
  cache_dir <- file.path(temp_dir, "meetupr")
  dir.create(cache_dir, recursive = TRUE)

  local_mocked_bindings(
    oauth_cache_path = function() temp_dir,
    .package = "httr2"
  )

  local_mocked_bindings(
    key_available = function(key, ...) TRUE
  )

  local_mocked_bindings(
    key_delete = function(key, ...) {
      TRUE
    },
    has_keyring_support = function() TRUE,
    .package = "keyring"
  )

  expect_message(
    meetup_deauth(clear_keyring = TRUE),
    "removed from keyring"
  )
})

test_that("meetup_deauth skips unavailable keys", {
  temp_dir <- withr::local_tempdir()
  cache_dir <- file.path(temp_dir, "meetupr")
  dir.create(cache_dir, recursive = TRUE)

  keys_checked <- character()

  local_mocked_bindings(
    oauth_cache_path = function() temp_dir,
    .package = "httr2"
  )
  local_mocked_bindings(
    key_available = function(key, ...) {
      FALSE
    }
  )

  expect_message(
    meetup_deauth(clear_keyring = TRUE),
    "Authentication cache removed"
  )
})

test_that("meetup_ci_setup works when clipr is not installed", {
  skip_on_cran()
  temp_dir <- withr::local_tempdir()
  temp_token <- file.path(temp_dir, "token.rds.enc")
  writeBin(charToRaw("test_token_data"), temp_token)

  local_mocked_bindings(
    meetup_auth_status = function() invisible(TRUE),
    token_path = function(...) temp_token
  )

  withr::with_package("rlang", {
    local_mocked_bindings(
      is_installed = function(...) FALSE,
      .package = "rlang"
    )
  })

  result <- meetup_ci_setup()

  expect_type(result, "character")
  expect_gt(nchar(result), 0)
})

test_that("meetup_ci_setup works when clipboard is unavailable", {
  skip_on_cran()
  temp_dir <- withr::local_tempdir()
  temp_token <- file.path(temp_dir, "token.rds.enc")
  writeBin(charToRaw("test_token_data"), temp_token)

  local_mocked_bindings(
    meetup_auth_status = function() invisible(TRUE),
    token_path = function(...) temp_token
  )

  withr::with_package("rlang", {
    local_mocked_bindings(
      is_installed = function(...) TRUE,
      .package = "rlang"
    )
  })

  withr::with_package("clipr", {
    local_mocked_bindings(
      clipr_available = function() FALSE,
      .package = "clipr"
    )
  })

  result <- meetup_ci_setup()

  expect_type(result, "character")
})

test_that("meetup_client passes additional arguments to oauth_client", {
  local_mocked_bindings(
    meetup_key_get = function(key, error = TRUE) {
      switch(
        key,
        client_id = "test_id",
        client_secret = "test_secret"
      )
    }
  )

  client <- meetup_client(auth = "header")

  expect_equal(client$id, "test_id")
  expect_equal(client$secret, "test_secret")
})

test_that("meetup_client uses provided client_id and client_secret", {
  client <- meetup_client(
    client_id = "custom_id",
    client_secret = "custom_secret"
  )

  expect_equal(client$id, "custom_id")
  expect_equal(client$secret, "custom_secret")
})

test_that("meetup_deauth handles case when keyring has no support", {
  temp_dir <- withr::local_tempdir()
  cache_dir <- file.path(temp_dir, "meetupr")
  dir.create(cache_dir, recursive = TRUE)

  local_mocked_bindings(
    oauth_cache_path = function() temp_dir,
    .package = "httr2"
  )

  local_mocked_bindings(
    has_keyring_support = function() FALSE,
    .package = "keyring"
  )

  expect_message(
    meetup_deauth(clear_keyring = TRUE),
    "Authentication cache removed"
  )
})

test_that("meetup_auth handles authentication failure gracefully", {
  local_mocked_bindings(
    get_self = function() stop("API error")
  )

  expect_message(
    result <- meetup_auth(),
    "Authentication failed"
  )

  expect_null(result)
})

test_that("meetup_auth returns user object on success", {
  mock_user <- structure(
    list(
      id = "123",
      name = "Test User",
      email = "test@example.com"
    ),
    class = c("meetup_user", "list")
  )

  local_mocked_bindings(
    get_self = function() mock_user
  )

  expect_message(
    result <- meetup_auth(),
    "Authenticated as.*Test User"
  )

  expect_equal(result$name, "Test User")
})

test_that("list_token_files returns empty vector when cache_path doesn't exist", {
  non_existent_path <- file.path(tempdir(), "does-not-exist-12345")

  result <- list_token_files(non_existent_path)

  expect_type(result, "character")
  expect_length(result, 0)
})

test_that("list_token_files finds encrypted token files with default pattern", {
  temp_cache <- withr::local_tempdir()

  # Create test token files
  token_file <- file.path(temp_cache, "test_token.rds.enc")
  other_file <- file.path(temp_cache, "other_file.txt")
  writeBin(raw(), token_file)
  writeBin(raw(), other_file)

  result <- list_token_files(temp_cache)

  expect_length(result, 1)
  expect_equal(basename(result), "test_token.rds.enc")
  expect_true(grepl("\\.rds\\.enc$", result))
})

test_that("list_token_files finds multiple token files", {
  temp_cache <- withr::local_tempdir()

  # Create multiple token files
  token1 <- file.path(temp_cache, "token1.rds.enc")
  token2 <- file.path(temp_cache, "token2.rds.enc")
  writeBin(raw(), token1)
  writeBin(raw(), token2)

  result <- list_token_files(temp_cache)

  expect_length(result, 2)
  expect_true(all(grepl("\\.rds\\.enc$", result)))
})

test_that("list_token_files searches recursively", {
  temp_cache <- withr::local_tempdir()

  # Create nested directory structure
  subdir <- file.path(temp_cache, "meetupr", "tokens")
  dir.create(subdir, recursive = TRUE)

  token_top <- file.path(temp_cache, "top.rds.enc")
  token_nested <- file.path(subdir, "nested.rds.enc")
  writeBin(raw(), token_top)
  writeBin(raw(), token_nested)

  result <- list_token_files(temp_cache)

  expect_length(result, 2)
  expect_true(any(grepl("top\\.rds\\.enc$", result)))
  expect_true(any(grepl("nested\\.rds\\.enc$", result)))
})

test_that("list_token_files respects custom pattern", {
  temp_cache <- withr::local_tempdir()

  # Create files with different extensions
  enc_file <- file.path(temp_cache, "token.rds.enc")
  json_file <- file.path(temp_cache, "token.json")
  txt_file <- file.path(temp_cache, "token.txt")
  writeBin(raw(), enc_file)
  writeBin(raw(), json_file)
  writeBin(raw(), txt_file)

  # Search for JSON files only
  result <- list_token_files(temp_cache, pattern = "\\.json$")

  expect_length(result, 1)
  expect_equal(basename(result), "token.json")
})

test_that("list_token_files returns full paths", {
  temp_cache <- withr::local_tempdir()

  token_file <- file.path(temp_cache, "token.rds.enc")
  writeBin(raw(), token_file)

  result <- list_token_files(temp_cache)

  expect_true(file.exists(result))
  expect_equal(normalizePath(result), normalizePath(token_file))
})

test_that("list_token_files returns empty vector when no matching files", {
  temp_cache <- withr::local_tempdir()

  # Create non-matching files
  other_file <- file.path(temp_cache, "not_a_token.txt")
  writeBin(raw(), other_file)

  result <- list_token_files(temp_cache)

  expect_type(result, "character")
  expect_length(result, 0)
})

test_that("list_token_files handles empty directory", {
  temp_cache <- withr::local_tempdir()

  # Directory exists but is empty
  result <- list_token_files(temp_cache)

  expect_type(result, "character")
  expect_length(result, 0)
})

test_that("list_token_files is used correctly in meetup_auth_status", {
  temp_cache <- withr::local_tempdir()
  client_cache <- file.path(temp_cache, "meetupr")
  dir.create(client_cache, recursive = TRUE)

  # Create a token file
  token_file <- file.path(client_cache, "token.rds.enc")
  writeBin(raw(), token_file)

  local_mocked_bindings(
    oauth_cache_path = function() temp_cache,
    .package = "httr2"
  )

  # Should find the token and return TRUE
  expect_true(meetup_auth_status(client_name = "meetupr", silent = TRUE))
})

test_that("list_token_files integration with meetup_auth_status warns on multiple tokens", {
  temp_cache <- withr::local_tempdir()
  client_cache <- file.path(temp_cache, "meetupr")
  dir.create(client_cache, recursive = TRUE)

  # Create multiple token files
  token1 <- file.path(client_cache, "token1.rds.enc")
  token2 <- file.path(client_cache, "token2.rds.enc")
  writeBin(raw(), token1)
  writeBin(raw(), token2)

  local_mocked_bindings(
    oauth_cache_path = function() temp_cache,
    .package = "httr2"
  )

  expect_warning(
    meetup_auth_status(client_name = "meetupr", silent = FALSE),
    "Multiple tokens found"
  )
})
