test_that("meetup_client returns a valid oauth client", {
  mock_if_no_auth()
  withr::local_envvar(c(
    MEETUP_CLIENT_ID = "client_id",
    MEETUP_CLIENT_SECRET = "client_secret",
    MEETUP_CLIENT_NAME = "meetupr"
  ))
  client <- meetup_client()
  expect_equal(client$id, "client_id")
  expect_equal(client$secret, "client_secret")
  expect_equal(client$name, "meetupr")
})

test_that("meetup_client defaults to environment variables", {
  withr::local_envvar(
    MEETUP_CLIENT_ID = "test_id",
    MEETUP_CLIENT_SECRET = "test_secret"
  )
  client <- meetup_client()
  expect_equal(client$id, "test_id")
  expect_equal(client$secret, "test_secret")
})

test_that("meetup_auth_load_ci handles missing variables", {
  withr::local_envvar(MEETUP_TOKEN = "", MEETUP_TOKEN_FILE = "")
  expect_error(meetup_auth_load_ci())
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

test_that("meetup_auth_status returns FALSE if cache directory does not exist", {
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
    MEETUP_CLIENT_ID = "",
    MEETUP_CLIENT_SECRET = ""
  )

  local_mocked_bindings(
    meetup_builtin_key = "builtin_key",
    meetup_builtin_secret = "builtin_secret"
  )

  client <- meetup_client()

  expect_s3_class(client, "httr2_oauth_client")
})

test_that("meetup_auth_setup_ci encodes token successfully", {
  temp_dir <- withr::local_tempdir()
  temp_token <- file.path(temp_dir, "token.rds.enc")
  writeBin(charToRaw("test_token_data"), temp_token)

  local_mocked_bindings(
    meetup_auth_status = function() invisible(TRUE),
    token_path = function(...) temp_token
  )

  result <- meetup_auth_setup_ci()

  expect_type(result, "character")
  expect_gt(nchar(result), 0)
})

test_that("meetup_auth_setup_ci copies to clipboard when available", {
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

  result <- meetup_auth_setup_ci()

  expect_true(clipboard_called)
})

test_that("meetup_auth_load_ci fails without MEETUP_TOKEN", {
  withr::local_envvar(
    MEETUP_TOKEN = "",
    MEETUP_TOKEN_FILE = "token.rds.enc"
  )

  expect_error(
    meetup_auth_load_ci(),
    "MEETUP_TOKEN"
  )
})

test_that("meetup_auth_load_ci fails without MEETUP_TOKEN_FILE", {
  withr::local_envvar(
    MEETUP_TOKEN = "dGVzdA==",
    MEETUP_TOKEN_FILE = ""
  )

  expect_error(
    meetup_auth_load_ci(),
    "MEETUP_TOKEN_FILE"
  )
})

test_that("meetup_auth_load_ci decodes and saves token successfully", {
  temp_dir <- withr::local_tempdir()

  test_token <- "test_token_content"
  encoded <- base64enc::base64encode(charToRaw(test_token))

  withr::local_envvar(
    MEETUP_TOKEN = encoded,
    MEETUP_TOKEN_FILE = "token.rds.enc"
  )

  local_mocked_bindings(
    oauth_cache_path = function() temp_dir,
    .package = "httr2"
  )
  expect_message(
    result <- meetup_auth_load_ci(client_name = "test_client"),
    "Token loaded successfully"
  )
  expect_true(result)
})
