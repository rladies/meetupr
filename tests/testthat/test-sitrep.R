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
