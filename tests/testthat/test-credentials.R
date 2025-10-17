test_that("meetup_key_set stores value in keyring", {
  stored <- NULL

  mock_backend <- list(
    set_with_value = function(service, username, password) {
      stored <<- list(
        service = service,
        username = username,
        password = password
      )
      invisible(NULL)
    }
  )

  local_mocked_bindings(
    get_keyring_backend = function() mock_backend
  )

  result <- meetup_key_set("client_id", "test_value")

  expect_true(is.null(result))
  expect_equal(stored$service, "meetupr")
  expect_equal(stored$username, "client_id")
  expect_equal(stored$password, "test_value")
})

test_that("meetup_key_set prompts when value is NULL", {
  mock_backend <- list(
    set_with_value = function(service, username, password) {
      invisible(NULL)
    }
  )

  local_mocked_bindings(
    get_keyring_backend = function() mock_backend,
    get_input = function(key) {
      expect_equal(key, "token")
      "prompted_value"
    }
  )

  result <- meetup_key_set("token", NULL)
  expect_true(is.null(result))
})

test_that("meetup_key_get retrieves from keyring", {
  mock_backend <- list(
    get = function(service, username) {
      if (service == "meetupr" && username == "token") {
        return("token_value")
      }
      stop("Not found")
    }
  )

  local_mocked_bindings(
    get_keyring_backend = function() mock_backend
  )

  expect_equal(meetup_key_get("token"), "token_value")
})

test_that("meetup_key_get handles missing keys with error = TRUE", {
  mock_backend <- list(
    get = function(...) stop("Not found")
  )

  local_mocked_bindings(
    get_keyring_backend = function(...) mock_backend
  )

  expect_error(
    meetup_key_get("client_id", error = TRUE),
    "client_id.*not found"
  )
})

test_that("meetup_key_get returns NULL with error = FALSE", {
  mock_backend <- list(
    get = function(...) stop("Not found")
  )

  local_mocked_bindings(
    get_keyring_backend = function() mock_backend
  )

  expect_null(meetup_key_get("client_id", error = FALSE))
})

test_that("meetup_key_delete removes key from keyring", {
  deleted <- NULL

  mock_backend <- list(
    delete = function(service, username) {
      deleted <<- list(service = service, username = username)
      invisible(NULL)
    }
  )

  local_mocked_bindings(
    get_keyring_backend = function() mock_backend
  )

  meetup_key_delete("token")
  expect_equal(deleted$service, "meetupr")
  expect_equal(deleted$username, "token")
})

test_that("key_name validates input", {
  expect_equal(key_name("client_id"), "client_id")
  expect_equal(key_name("client_secret"), "client_secret")
  expect_equal(key_name("token"), "token")
  expect_equal(key_name("token_file"), "token_file")
  expect_error(key_name("invalid"))
})

test_that("key_available returns TRUE if key exists", {
  local_mocked_bindings(
    key_list = function(service) {
      data.frame(
        service = "meetupr",
        username = "token"
      )
    },
    .package = "keyring"
  )
  expect_true(key_available("token"))
})

test_that("key_available returns FALSE if key does not exist", {
  local_mocked_bindings(
    key_list = function(service) {
      data.frame(
        service = character(0),
        username = character(0)
      )
    },
    .package = "keyring"
  )
  expect_false(key_available("token"))
})

test_that("get_input returns user input correctly", {
  local_mocked_bindings(
    readline = function(prompt) "user_input",
    .package = "base"
  )
  expect_equal(get_input("token"), "user_input")
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
