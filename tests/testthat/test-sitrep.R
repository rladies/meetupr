test_that("meetup_sitrep outputs as expected", {
  local_mocked_bindings(
    check_auth_methods = function() {
      list(
        jwt = list(
          available = TRUE,
          client_id = "test_client_id",
          member_id = "test_member_id",
          rsa_path = NULL,
          rsa_key = "test_key"
        ),
        oauth = list(available = FALSE, client_id = NULL, client_secret = NULL),
        active_method = "JWT",
        debug = list(enabled = FALSE)
      )
    },
    display_auth_status = function(auth_status) NULL,
    test_api_connectivity = function(auth_status) NULL
  )
  expect_invisible(meetup_sitrep())
})

test_that("cli_status behaves as expected with all message types", {
  expect_invisible(cli_status(
    TRUE,
    "True Message",
    "False Message",
    "success",
    "warning"
  ))
  expect_invisible(cli_status(
    FALSE,
    "True Message",
    "False Message",
    "info",
    "danger"
  ))
  expect_invisible(cli_status(
    TRUE,
    NULL,
    "False Message",
    "success",
    "warning"
  ))
  expect_invisible(cli_status(FALSE, "True Message", NULL, "info", "danger"))
})

test_that("show_config_item masks values and identifies missing items", {
  expect_invisible(show_config_item("Client ID", "12345678", mask = TRUE))
  expect_invisible(show_config_item("Client ID", "", mask = TRUE))
})

test_that("validate_rsa_key identifies valid and invalid keys", {
  expect_true(validate_rsa_key(
    "-----BEGIN PRIVATE KEY----- ... -----END PRIVATE KEY-----"
  ))
  expect_false(validate_rsa_key(""))
  expect_false(validate_rsa_key("INVALID_KEY"))
})

test_that("get_rsa_key_status reports file existence, valid keys, and errors", {
  file_path <- withr::local_tempfile()
  writeLines(
    c("-----BEGIN PRIVATE KEY-----", "-----END PRIVATE KEY-----"),
    file_path
  )

  expect_true(get_rsa_key_status(file_path, NULL)$valid)
  expect_false(get_rsa_key_status("nonexistent_path", NULL)$valid)
  expect_true(
    get_rsa_key_status(
      "",
      "-----BEGIN PRIVATE KEY----- ... -----END PRIVATE KEY-----"
    )$valid
  )
  expect_false(get_rsa_key_status("", "INVALID_KEY")$valid)
})

test_that("show_rsa_status correctly reports RSA status", {
  local_mocked_bindings(get_rsa_key_status = function(...) {
    list(valid = TRUE)
  })
  expect_invisible(
    expect_message(
      show_rsa_status("test_path", NULL),
      "RSA Key: "
    )
  )

  local_mocked_bindings(get_rsa_key_status = function(...) {
    list(valid = FALSE, message = "Invalid key")
  })
  expect_invisible(
    expect_message(
      show_rsa_status("", "INVALID_KEY"),
      "Invalid key"
    )
  )
})

test_that("check_auth_methods identifies JWT and OAuth states", {
  local_mocked_bindings(
    has_jwt_credentials = function() TRUE,
    has_oauth_credentials = function() FALSE
  )
  auth_methods <- check_auth_methods()
  expect_equal(auth_methods$active_method, "JWT")
})

test_that("display_auth_status processes both JWT and OAuth status", {
  auth_status <- list(
    jwt = list(
      available = TRUE,
      client_id = "test_client_id",
      member_id = "test_member_id",
      rsa_path = "",
      rsa_key = ""
    ),
    oauth = list(
      available = FALSE,
      client_id = "",
      client_secret = ""
    ),
    active_method = "JWT",
    debug = list(enabled = FALSE)
  )
  expect_invisible(
    expect_message(
      display_auth_status(auth_status),
      "JWT Authentication"
    )
  )
})

test_that("test_api_connectivity succeeds or catches API errors", {
  local_mocked_bindings(
    get_self = function() list(name = "Test User", id = 12345)
  )
  auth_status <- list(active_method = "JWT")
  expect_invisible(test_api_connectivity(auth_status))

  local_mocked_bindings(get_self = function() stop("Error"))
  expect_invisible(test_api_connectivity(auth_status))
})

test_that("meetup_sitrep returns auth status invisibly", {
  mock_auth_status <- list(
    jwt = list(available = TRUE),
    oauth = list(available = FALSE),
    active_method = "JWT",
    debug = list(enabled = FALSE)
  )

  local_mocked_bindings(
    check_auth_methods = function() mock_auth_status,
    display_auth_status = function(...) NULL,
    test_api_connectivity = function(...) NULL
  )

  result <- meetup_sitrep()
  expect_identical(result, mock_auth_status)
})

test_that("cli_status handles all message types correctly", {
  expect_message(cli_status(
    TRUE,
    "success msg",
    "fail msg",
    "success",
    "warning"
  ))
  expect_message(cli_status(
    FALSE,
    "success msg",
    "fail msg",
    "success",
    "warning"
  ))
  expect_message(cli_status(TRUE, "info msg", "fail msg", "info", "danger"))
  expect_message(cli_status(
    FALSE,
    "success msg",
    "danger msg",
    "success",
    "danger"
  ))

  # Test default behavior
  expect_message(cli_status(TRUE, "default msg", "fail msg"))
  expect_message(cli_status(FALSE, "success msg", "default fail"))
})

test_that("show_config_item handles masking correctly", {
  expect_message(
    show_config_item("Test Key", "longvalue123", mask = TRUE),
    "Test Key.*longva\\.\\.\\."
  )
  expect_message(show_config_item("Test Key", "short", mask = TRUE), "short")
  expect_message(show_config_item("Test Key", "", mask = TRUE), "Not set")
  expect_message(show_config_item("Test Key", "value", mask = FALSE), "value")
})

test_that("validate_rsa_key validates different key formats", {
  # Valid keys
  expect_true(validate_rsa_key(
    "-----BEGIN PRIVATE KEY-----\nkey data\n-----END PRIVATE KEY-----"
  ))
  expect_true(validate_rsa_key(
    "-----BEGIN RSA PRIVATE KEY-----\nkey data\n-----END RSA PRIVATE KEY-----"
  ))

  # Invalid keys
  expect_false(validate_rsa_key(""))
  expect_false(validate_rsa_key("some random text"))
  expect_false(validate_rsa_key("-----BEGIN PRIVATE KEY-----"))
  expect_false(validate_rsa_key("-----END PRIVATE KEY-----"))
  expect_false(validate_rsa_key(
    "-----BEGIN PUBLIC KEY-----\ndata\n-----END PUBLIC KEY-----"
  ))
})

test_that("get_rsa_key_status handles file paths", {
  # Test with existing valid file
  temp_file <- withr::local_tempfile()
  writeLines(
    c(
      "-----BEGIN PRIVATE KEY-----",
      "key content",
      "-----END PRIVATE KEY-----"
    ),
    temp_file
  )

  result <- get_rsa_key_status(temp_file, "")
  expect_true(result$valid)
  expect_equal(result$message, "Valid RSA key file")

  # Test with existing invalid file
  temp_file2 <- withr::local_tempfile()
  writeLines("invalid content", temp_file2)

  result <- get_rsa_key_status(temp_file2, "")
  expect_false(result$valid)
  expect_match(result$message, "File exists, but doesn't contain valid RSA key")

  # Test with non-existent file
  result <- get_rsa_key_status("/nonexistent/file", "")
  expect_false(result$valid)
  expect_equal(result$message, "File not found")
})

test_that("get_rsa_key_status handles environment variables", {
  # nolint start
  valid_key <- "-----BEGIN PRIVATE KEY-----\nkey content\n-----END PRIVATE KEY-----"
  # nolint end
  result <- get_rsa_key_status("", valid_key)
  expect_true(result$valid)
  expect_equal(result$message, "Valid RSA key in environment")

  # Test with invalid environment key
  result <- get_rsa_key_status("", "invalid key")
  expect_false(result$valid)
  expect_match(result$message, "doesn't contain valid RSA key")

  # Test with empty values
  result <- get_rsa_key_status("", "")
  expect_false(result$valid)
  expect_equal(result$message, "Not set")
})

test_that("get_rsa_key_status handles file read errors", {
  # Create a directory instead of file to cause read error
  temp_dir <- withr::local_tempdir()

  result <- get_rsa_key_status(temp_dir, "")
  expect_false(result$valid)
  expect_match(result$message, "Path is a directory, not a file")

  result <- get_rsa_key_status("/path/somewhere", "")
  expect_false(result$valid)
  expect_match(result$message, "File not found")
})

test_that("show_rsa_status displays correct messages", {
  local_mocked_bindings(
    get_rsa_key_status = function(...) list(valid = TRUE, message = "Valid")
  )

  expect_message(show_rsa_status("/path/to/key", ""), "RSA Key.*path/to/key")
  expect_message(show_rsa_status("", "env_key"), "Set via environment")

  local_mocked_bindings(
    get_rsa_key_status = function(...) list(valid = FALSE, message = "Invalid")
  )

  expect_message(show_rsa_status("/bad/path", ""), "Invalid")
  expect_message(show_rsa_status("", ""), "Invalid")
})

test_that("check_auth_methods determines active method correctly", {
  local_mocked_bindings(
    has_jwt_credentials = function() TRUE,
    has_oauth_credentials = function() TRUE
  )

  withr::local_envvar(c(
    MEETUP_CLIENT_ID = "test_client",
    MEETUP_MEMBER_ID = "test_member",
    MEETUP_CLIENT_SECRET = "test_secret",
    MEETUP_RSA_PATH = "/test/path",
    MEETUP_RSA_KEY = "test_key",
    MEETUPR_DEBUG = "1"
  ))

  auth_status <- check_auth_methods()

  expect_equal(auth_status$active_method, "JWT")
  expect_true(auth_status$jwt$available)
  expect_true(auth_status$oauth$available)
  expect_equal(auth_status$jwt$client_id, "test_client")
  expect_equal(auth_status$jwt$member_id, "test_member")
  expect_equal(auth_status$oauth$client_secret, "test_secret")
  expect_true(auth_status$debug$enabled)
})

test_that("check_auth_methods handles no authentication", {
  local_mocked_bindings(
    has_jwt_credentials = function() FALSE,
    has_oauth_credentials = function() FALSE
  )

  withr::local_envvar(c(
    MEETUP_CLIENT_ID = "",
    MEETUP_MEMBER_ID = "",
    MEETUP_CLIENT_SECRET = "",
    MEETUPR_DEBUG = ""
  ))

  auth_status <- check_auth_methods()

  expect_equal(auth_status$active_method, "None")
  expect_false(auth_status$jwt$available)
  expect_false(auth_status$oauth$available)
  expect_false(auth_status$debug$enabled)
})

test_that("check_auth_methods prefers OAuth when JWT not available", {
  local_mocked_bindings(
    has_jwt_credentials = function() FALSE,
    has_oauth_credentials = function() TRUE
  )

  auth_status <- check_auth_methods()
  expect_equal(auth_status$active_method, "OAuth")
})

test_that("display_auth_status shows JWT configuration", {
  auth_status <- list(
    jwt = list(
      available = TRUE,
      client_id = "jwt_client_id",
      member_id = "jwt_member_id",
      rsa_path = "/path/to/key",
      rsa_key = ""
    ),
    oauth = list(available = FALSE),
    active_method = "JWT",
    debug = list(enabled = TRUE, value = "1")
  )

  local_mocked_bindings(
    show_rsa_status = function(...) NULL
  )

  expect_message(
    display_auth_status(auth_status),
    "JWT Authentication"
  )
  expect_message(
    display_auth_status(auth_status),
    "JWT Configuration"
  )
  expect_message(
    display_auth_status(auth_status),
    "Debug Mode.*Enabled"
  )
})

test_that("display_auth_status shows OAuth configuration", {
  auth_status <- list(
    jwt = list(available = FALSE),
    oauth = list(
      available = TRUE,
      client_id = "client_id",
      client_secret = "oauth_secret"
    ),
    active_method = "OAuth",
    debug = list(enabled = FALSE, value = "")
  )

  expect_message(
    display_auth_status(auth_status),
    "OAuth Authentication"
  )
  expect_message(
    display_auth_status(auth_status),
    "OAuth Configuration"
  )
  expect_message(
    display_auth_status(auth_status),
    "Debug Mode.*Disabled"
  )
})

test_that("display_auth_status shows missing configuration", {
  auth_status <- list(
    jwt = list(
      available = FALSE,
      client_id = "",
      member_id = "",
      rsa_path = "",
      rsa_key = ""
    ),
    oauth = list(
      available = FALSE,
      client_id = "",
      client_secret = ""
    ),
    active_method = "None",
    debug = list(enabled = FALSE, value = "")
  )

  expect_message(
    display_auth_status(auth_status),
    "No Authentication Configured"
  )
  expect_message(
    display_auth_status(auth_status),
    "JWT: Not configured"
  )
  expect_message(
    display_auth_status(auth_status),
    "OAuth: Not configured"
  )
  expect_message(
    display_auth_status(auth_status),
    "MEETUP_CLIENT_ID"
  )
  expect_message(
    display_auth_status(auth_status),
    "MEETUP_MEMBER_ID"
  )
  expect_message(
    display_auth_status(auth_status),
    "MEETUP_RSA_PATH"
  )
  expect_message(
    display_auth_status(auth_status),
    "MEETUP_CLIENT_SECRET"
  )
})

test_that("display_auth_status shows custom API endpoint", {
  auth_status <- list(
    jwt = list(available = FALSE),
    oauth = list(available = FALSE),
    active_method = "None",
    debug = list(enabled = FALSE, value = "")
  )

  withr::local_envvar(
    MEETUP_API_URL = "https://custom.api.com"
  )

  expect_message(
    display_auth_status(auth_status),
    "custom.api.com"
  )
})

test_that("test_api_connectivity shows setup instructions when no auth", {
  auth_status <- list(active_method = "None")

  expect_message(test_api_connectivity(auth_status), "Setup Instructions")
  expect_message(test_api_connectivity(auth_status), "automated workflows")
  expect_message(test_api_connectivity(auth_status), "interactive development")
})

test_that("test_api_connectivity tests connection successfully", {
  auth_status <- list(active_method = "JWT")

  local_mocked_bindings(
    get_self = function() list(name = "Test User", id = "123")
  )

  expect_message(test_api_connectivity(auth_status), "API Connection: Working")
  expect_message(
    test_api_connectivity(auth_status),
    "Authenticated as: Test User"
  )
})

test_that("test_api_connectivity handles API errors", {
  auth_status <- list(active_method = "JWT")

  local_mocked_bindings(
    get_self = function() stop("API Error occurred")
  )

  expect_message(
    test_api_connectivity(auth_status),
    "API Connection: Failed"
  )
  expect_message(
    test_api_connectivity(auth_status),
    "API Error occurred"
  )
})

test_that("test_api_connectivity handles unexpected response", {
  auth_status <- list(active_method = "OAuth")

  local_mocked_bindings(
    get_self = function() NULL
  )

  expect_message(test_api_connectivity(auth_status), "Unexpected response")
})

test_that("cli_status handles all condition combinations", {
  # Test all true_type variations
  expect_message(cli_status(TRUE, "msg", "fail", "info"), "msg")
  expect_message(cli_status(TRUE, "msg", "fail", "success"), "msg")
  expect_message(cli_status(TRUE, "msg", "fail", "warning"), "msg")
  expect_message(cli_status(TRUE, "msg", "fail", "danger"), "msg")
  expect_message(cli_status(TRUE, "msg", "fail", "other"), "msg")

  # Test all false_type variations
  expect_message(cli_status(FALSE, "msg", "fail", "success", "info"), "fail")
  expect_message(cli_status(FALSE, "msg", "fail", "success", "success"), "fail")
  expect_message(cli_status(FALSE, "msg", "fail", "success", "warning"), "fail")
  expect_message(cli_status(FALSE, "msg", "fail", "success", "danger"), "fail")
  expect_message(cli_status(FALSE, "msg", "fail", "success", "other"), "fail")
})

test_that("show_config_item handles edge cases", {
  # Test very short values with masking
  expect_message(
    show_config_item("Short", "abc", mask = TRUE),
    "abc"
  )
  expect_message(
    show_config_item("Six", "123456", mask = TRUE),
    "123456\\.\\.\\."
  )

  # Test whitespace handling
  expect_message(
    show_config_item("Spaces", "   ", mask = FALSE),
    "   "
  )
  expect_message(
    show_config_item("Tab", "\t", mask = FALSE),
    "\t"
  )
})

test_that("show_config_item handles value with mask TRUE", {
  local_mocked_bindings(
    cli_status = function(...) list(...)
  )
  result <- show_config_item(
    "TestName",
    "123456789",
    mask = TRUE
  )
  expect_equal(
    result[[2]],
    "TestName: 123456..."
  )
})

test_that("show_config_item handles value with mask FALSE", {
  local_mocked_bindings(
    cli_status = function(...) list(...)
  )
  result <- show_config_item("TestName", "123456789", mask = FALSE)
  expect_equal(result[[2]], "TestName: 123456789")
})

test_that("show_config_item handles NULL value", {
  local_mocked_bindings(
    cli_status = function(...) list(...)
  )
  result <- show_config_item("TestName", NULL, mask = TRUE)
  expect_equal(result[[3]], "TestName: Not set")
})

test_that("show_config_item handles empty string value", {
  local_mocked_bindings(
    cli_status = function(...) list(...)
  )
  result <- show_config_item("TestName", "", mask = TRUE)
  expect_equal(result[[3]], "TestName: Not set")
})

test_that("get_rsa_key_status handles file not found", {
  temp_path <- withr::local_tempfile()

  result <- get_rsa_key_status(temp_path, NULL)

  expect_false(result$valid)
  expect_equal(result$message, "File not found")
})

test_that("get_rsa_key_status handles directory path", {
  temp_dir <- withr::local_tempdir()

  result <- get_rsa_key_status(temp_dir, NULL)

  expect_false(result$valid)
  expect_equal(result$message, "Path is a directory, not a file")
})

test_that("get_rsa_key_status handles invalid RSA key in file", {
  temp_file <- withr::local_tempfile()
  writeLines("invalid key content", temp_file)

  local_mocked_bindings(
    validate_rsa_key = function(key) FALSE
  )

  result <- get_rsa_key_status(temp_file, NULL)

  expect_false(result$valid)
  expect_equal(result$message, "File exists, but doesn't contain valid RSA key")
})
