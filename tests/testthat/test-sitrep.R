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

test_that("show_config_item masks values and identifies missing items", {
  expect_invisible(show_config_item("Client ID", "12345678", mask = TRUE))
  expect_invisible(show_config_item("Client ID", "", mask = TRUE))
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

test_that("meetup_sitrep runs with OAuth active", {
  withr::local_envvar(
    MEETUP_CLIENT_ID = "test_client",
    MEETUP_CLIENT_SECRET = "test_secret",
    MEETUPR_DEBUG = ""
  )

  local_mocked_bindings(
    meetup_auth_status = function(...) TRUE,
    token_path = function(...) "/fake/path/token.rds.enc",
    get_self = function() list(name = "Test User", id = "12345")
  )

  result <- meetup_sitrep()

  expect_type(result, "list")
  expect_true(result$oauth$available)
})


test_that("check_auth_methods detects CI mode", {
  withr::local_envvar(
    MEETUP_TOKEN = "encoded_token",
    MEETUP_TOKEN_FILE = "token.rds.enc",
    MEETUP_CLIENT_ID = "test_client",
    MEETUP_CLIENT_SECRET = "test_secret"
  )

  local_mocked_bindings(
    meetup_auth_status = function(...) TRUE,
    token_path = function(...) "/fake/token.rds.enc"
  )

  result <- check_auth_methods()

  expect_true(result$oauth$ci_mode)
  expect_equal(result$active_method, "OAuth")
})


test_that("check_auth_methods handles debug mode", {
  withr::local_envvar(MEETUPR_DEBUG = "1")

  local_mocked_bindings(
    meetup_auth_status = function(...) FALSE,
    token_path = function(...) stop("No token")
  )

  result <- check_auth_methods()

  expect_true(result$debug$enabled)
})

test_that("check_debug_mode returns FALSE for non-1 values", {
  withr::local_envvar(MEETUPR_DEBUG = "true")

  result <- check_debug_mode()

  expect_false(result)
})

test_that("test_api_connectivity handles API errors", {
  auth_status <- list(active_method = "oAuth")

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

test_that("test_api_connectivity succeeds or catches API errors", {
  local_mocked_bindings(
    get_self = function() list(name = "Test User", id = 12345)
  )
  auth_status <- list(active_method = "oAuth")
  expect_invisible(test_api_connectivity(auth_status))

  local_mocked_bindings(get_self = function() stop("Error"))
  expect_invisible(test_api_connectivity(auth_status))
})


test_that("test_api_connectivity shows setup for no auth", {
  auth_status <- list(active_method = "None")

  result <- test_api_connectivity(auth_status)

  expect_null(result)
})

test_that("test_api_connectivity skips for not authenticated", {
  auth_status <- list(active_method = "OAuth (not authenticated)")

  result <- test_api_connectivity(auth_status)

  expect_null(result)
})

test_that("test_api_connectivity succeeds with valid auth", {
  auth_status <- list(
    active_method = "OAuth"
  )

  local_mocked_bindings(
    get_self = function() {
      list(
        name = "Test User",
        id = "12345"
      )
    }
  )

  expect_message(
    test_api_connectivity(auth_status),
    "Test User"
  )
})

test_that("test_api_connectivity handles unexpected response", {
  auth_status <- list(
    active_method = "OAuth"
  )

  local_mocked_bindings(
    get_self = function() NULL
  )

  expect_message(
    test_api_connectivity(auth_status),
    "Unexpected response"
  )
})


test_that("test_api_connectivity shows setup for no auth", {
  auth_status <- list(active_method = "None")

  result <- test_api_connectivity(auth_status)

  expect_null(result)
})

test_that("test_api_connectivity skips for not authenticated", {
  auth_status <- list(active_method = "OAuth (not authenticated)")

  result <- test_api_connectivity(auth_status)

  expect_null(result)
})

test_that("meetup_sitrep runs with OAuth active", {
  withr::local_envvar(
    MEETUP_CLIENT_ID = "test_client",
    MEETUP_CLIENT_SECRET = "test_secret",
    MEETUPR_DEBUG = ""
  )

  local_mocked_bindings(
    meetup_auth_status = function(...) TRUE,
    token_path = function(...) "/fake/path/token.rds.enc",
    get_self = function() list(name = "Test User", id = "12345")
  )

  result <- meetup_sitrep()

  expect_type(result, "list")
  expect_true(result$oauth$available)
})

test_that("check_auth_methods detects CI mode with keyring", {
  local_mocked_bindings(
    meetup_auth_status = function(...) TRUE,
    token_path = function(...) "/fake/token.rds.enc",
    meetup_key_get = function(key, error = TRUE) {
      if (key == "token") {
        return("encoded_token_value")
      }
      if (key == "token_file") {
        return("token.rds.enc")
      }
      if (key == "client_id") {
        return(NULL)
      }
      if (key == "client_secret") {
        return(NULL)
      }
      NULL
    }
  )

  result <- check_auth_methods()

  expect_true(result$oauth$ci_mode)
  expect_equal(result$active_method, "OAuth")
})

test_that("check_auth_methods detects custom client credentials", {
  local_mocked_bindings(
    meetup_auth_status = function(...) TRUE,
    token_path = function(...) "/fake/token.rds.enc",
    meetup_key_get = function(key, error = TRUE) {
      if (key == "client_id") {
        return("custom_client_id")
      }
      if (key == "client_secret") {
        return("custom_secret")
      }
      if (key == "token") {
        return(NULL)
      }
      if (key == "token_file") {
        return(NULL)
      }
      NULL
    }
  )

  result <- check_auth_methods()

  expect_true(result$oauth$uses_custom_client)
  expect_equal(result$oauth$client_id, "custom_client_id")
  expect_equal(result$oauth$client_secret, "custom_secret")
})

test_that("check_auth_methods handles missing keyring gracefully", {
  local_mocked_bindings(
    meetup_auth_status = function(...) FALSE,
    token_path = function(...) stop("No token"),
    meetup_key_get = function(key, error = TRUE) NULL
  )

  result <- check_auth_methods()

  expect_false(result$oauth$uses_custom_client)
  expect_null(result$oauth$client_id)
  expect_null(result$oauth$client_secret)
})


test_that("display_auth_status shows CI mode detection", {
  auth_status <- list(
    active_method = "OAuth",
    oauth = list(
      ci_mode = TRUE,
      has_cached_token = TRUE,
      client_id = NULL,
      client_secret = NULL,
      uses_custom_client = FALSE
    ),
    debug = list(enabled = FALSE, value = "")
  )

  expect_message(
    display_auth_status(auth_status),
    "CI environment detected"
  )
})

test_that("display_auth_status shows custom client configuration", {
  auth_status <- list(
    active_method = "OAuth",
    oauth = list(
      ci_mode = FALSE,
      has_cached_token = TRUE,
      client_id = "custom_client_id",
      client_secret = "custom_secret",
      uses_custom_client = TRUE
    ),
    debug = list(enabled = FALSE, value = "")
  )

  expect_message(
    display_auth_status(auth_status),
    "custom..."
  )
})

test_that("display_auth_status hides config when using builtin client", {
  auth_status <- list(
    active_method = "OAuth",
    oauth = list(
      ci_mode = FALSE,
      has_cached_token = TRUE,
      client_id = NULL,
      client_secret = NULL,
      uses_custom_client = FALSE
    ),
    debug = list(enabled = FALSE, value = "")
  )
  output <- capture.output({
    display_auth_status(auth_status)
  })

  output_text <- paste(output, collapse = "\n")

  expect_false(grepl("Client ID", output_text))
  expect_false(grepl("Client Secret", output_text))
})

test_that("display_auth_status shows OAuth not authenticated", {
  auth_status <- list(
    active_method = "OAuth (not authenticated)",
    oauth = list(
      ci_mode = FALSE,
      has_cached_token = FALSE,
      client_id = "test_client",
      client_secret = "secret",
      uses_custom_client = FALSE
    ),
    debug = list(enabled = FALSE, value = "")
  )

  expect_message(
    display_auth_status(auth_status),
    "OAuth credentials configured but not authenticated"
  )
})

test_that("display_auth_status shows no auth", {
  auth_status <- list(
    active_method = "None",
    oauth = list(
      ci_mode = FALSE,
      has_cached_token = FALSE,
      client_id = NULL,
      client_secret = NULL,
      uses_custom_client = FALSE
    ),
    debug = list(enabled = FALSE, value = "")
  )

  expect_message(
    display_auth_status(auth_status),
    "No Authentication Configured"
  )
})

test_that("display_auth_status shows debug enabled", {
  auth_status <- list(
    active_method = "OAuth",
    oauth = list(
      ci_mode = FALSE,
      has_cached_token = TRUE,
      client_id = "test_client",
      client_secret = "secret",
      uses_custom_client = FALSE
    ),
    debug = list(enabled = TRUE, value = "1")
  )

  expect_message(
    display_auth_status(auth_status),
    "Enabled"
  )
})

test_that("check_debug_mode returns FALSE for non-1 values", {
  withr::local_envvar(MEETUPR_DEBUG = "true")

  result <- check_debug_mode()

  expect_false(result)
})
