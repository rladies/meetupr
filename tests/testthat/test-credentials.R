test_that("meetup_key_set stores value in keyring", {
  stored <- NULL

  local_mocked_bindings(
    key_set_with_value = function(service, password) {
      stored <<- list(service = service, password = password)
    },
    .package = "keyring"
  )

  result <- meetup_key_set("client_id", "test_value")

  expect_true(result)
  expect_equal(stored$service, "MEETUP_CLIENT_ID")
  expect_equal(stored$password, "test_value")
})

test_that("meetup_key_set prompts when value is NULL", {
  local_mocked_bindings(
    key_set_with_value = function(...) NULL,
    .package = "keyring"
  )
  local_mocked_bindings(
    get_input = function(key) {
      expect_equal(key, "MEETUP_TOKEN")
    }
  )
  result <- meetup_key_set("token", NULL)
  expect_true(result)
})

test_that("meetup_key_get retrieves from keyring", {
  local_mocked_bindings(
    key_get = function(service) {
      if (service == "MEETUP_TOKEN") {
        return("token_value")
      }
      stop("Not found")
    },
    .package = "keyring"
  )

  expect_equal(meetup_key_get("token"), "token_value")
})

test_that("meetup_key_get handles missing keys with error = TRUE", {
  local_mocked_bindings(
    key_get = function(...) stop("Not found"),
    .package = "keyring"
  )

  expect_error(
    meetup_key_get("client_id", error = TRUE),
    "MEETUP_CLIENT_ID.*not found"
  )
})

test_that("meetup_key_get returns NULL with error = FALSE", {
  local_mocked_bindings(
    key_get = function(...) stop("Not found"),
    .package = "keyring"
  )

  expect_null(meetup_key_get("client_id", error = FALSE))
})

test_that("token_path finds token silently", {
  temp_cache <- withr::local_tempdir()
  file <- file.path(temp_cache, "meetupr", "test_token.rds.enc")
  dir.create(dirname(file), recursive = TRUE)
  writeBin(raw(), file)

  local_mocked_bindings(
    oauth_cache_path = function() temp_cache,
    .package = "httr2"
  )

  expect_silent(path <- token_path(client_name = "meetupr", silent = TRUE))
  expect_equal(path, file)
})

test_that("token_path shows message when not silent", {
  temp_cache <- withr::local_tempdir()
  file <- file.path(temp_cache, "meetupr", "test_token.rds.enc")
  dir.create(dirname(file), recursive = TRUE)
  writeBin(raw(), file)

  local_mocked_bindings(
    oauth_cache_path = function() temp_cache,
    .package = "httr2"
  )

  expect_message(
    token_path(client_name = "meetupr", silent = FALSE),
    "Token found"
  )
})

test_that("key_name validates input", {
  expect_equal(
    key_name("client_id"),
    "MEETUP_CLIENT_ID"
  )
  expect_equal(
    key_name("client_secret"),
    "MEETUP_CLIENT_SECRET"
  )
  expect_equal(
    key_name("token"),
    "MEETUP_TOKEN"
  )
  expect_equal(
    key_name("token_file"),
    "MEETUP_TOKEN_FILE"
  )
  expect_error(
    key_name("invalid")
  )
})

test_that("key_available returns TRUE if key exists", {
  local_mocked_bindings(
    key_list = function(key) data.frame(service = key),
    .package = "keyring"
  )
  expect_true(key_available("api_key"))
})

test_that("key_available returns FALSE if key does not exist", {
  local_mocked_bindings(
    key_list = function(key) data.frame(),
    .package = "keyring"
  )
  expect_false(key_available("nonexistent_key"))
})

test_that("get_input returns user input correctly", {
  local_mocked_bindings(
    readline = function(prompt) "user_input",
    .package = "base"
  )
  expect_equal(get_input("test_key"), "user_input")
})
