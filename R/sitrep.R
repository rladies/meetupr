#' Show meetupr authentication status
#'
#' This function checks the authentication status for the Meetup API.
#' It provides feedback on whether credentials are configured correctly,
#' tests API connectivity, and shows available authentication methods.
#'
#' @return Invisibly returns a list with authentication status details.
#' @examples
#' meetup_sitrep()
#'
#' @export
meetup_sitrep <- function() {
  cli::cli_h1("meetupr Situation Report")

  # Check authentication methods
  auth_status <- check_auth_methods()

  # Display results
  display_auth_status(auth_status)

  # Test connectivity if possible
  test_api_connectivity(auth_status)

  invisible(auth_status)
}

#' Check available authentication methods
#' @keywords internal
#' @noRd
check_auth_methods <- function() {
  auth_status <- list()

  oauth_available <- meetup_auth_status(silent = TRUE)

  has_token <- tryCatch(
    {
      token_path(pattern = ".rds.enc$")
      TRUE
    },
    error = function(e) FALSE
  )

  token_vars <- sapply(
    c("token", "token_file", "client_id", "client_secret"),
    meetup_key_get,
    error = FALSE
  )

  ci_token <- !is.null(token_vars$token) &&
    !is.null(token_vars$token_file)

  auth_status$oauth <- list(
    available = oauth_available,
    client_id = token_vars$client_id,
    client_secret = token_vars$client_secret,
    has_cached_token = has_token,
    ci_mode = ci_token,
    uses_custom_client = !is.null(token_vars$client_id)
  )

  auth_status$active_method <- if (has_token || ci_token) {
    "OAuth"
  } else {
    "None"
  }

  auth_status$debug <- list(
    enabled = check_debug_mode(),
    value = Sys.getenv("MEETUPR_DEBUG")
  )

  auth_status
}

#' Display authentication status
#' @keywords internal
#' @noRd
display_auth_status <- function(auth_status) {
  cli::cli_h2("Active Authentication Method")

  if (auth_status$active_method == "OAuth") {
    if (auth_status$oauth$ci_mode) {
      cli::cli_alert_success("OAuth (CI Mode) - {.val Active}")
    } else {
      cli::cli_alert_success("OAuth - {.val Active}")
    }
  } else if (auth_status$active_method == "OAuth (not authenticated)") {
    cli::cli_alert_warning("OAuth credentials configured but not authenticated")
    cli::cli_text("   Run {.code get_self()} to authenticate")
  } else {
    cli::cli_alert_danger("No Authentication Configured")
  }

  if (auth_status$oauth$uses_custom_client) {
    cli::cli_h2("OAuth Configuration")

    show_config_item("Client ID", auth_status$oauth$client_id, mask = TRUE)
    show_config_item(
      "Client Secret",
      auth_status$oauth$client_secret,
      mask = TRUE
    )
  }

  cli_status(
    auth_status$oauth$has_cached_token,
    "Cached Token: Available",
    "Cached Token: None - run {.code get_self()}",
    "success",
    "info"
  )

  if (auth_status$oauth$ci_mode) {
    cli::cli_alert_info("CI environment detected")
  }

  cli::cli_h2("Package Settings")

  cli_status(
    auth_status$debug$enabled,
    "Debug Mode: {cli::col_green('Enabled')}",
    "Debug Mode: {cli::col_red('Disabled')}",
    "info",
    "info"
  )

  # nolint start
  api_endpoint <- Sys.getenv(
    "MEETUP_API_URL",
    meetup_api_prefix()
  )
  cli::cli_alert_info("API endpoint: {.url {api_endpoint}}")
  # nolint end
}

#' Test API connectivity
#' @keywords internal
#' @noRd
test_api_connectivity <- function(auth_status) {
  if (auth_status$active_method == "None") {
    cli::cli_h2("Setup Instructions")

    cli::cli_h3("Interactive Setup:")
    cli::cli_ol(c(
      "Run {.code get_self()} to authenticate"
    ))

    cli::cli_h3("CI/CD Setup:")
    cli::cli_ol(c(
      "Authenticate locally first with {.code get_self()}",
      "Run {.code meetup_ci_setup()} to get encoded token",
      "Set secrets in your CI (quote the names in YAML):",
      "  {.code \"meetupr:token\": ${{ secrets.meetupr_token }}}",
      "  {.code \"meetupr:token_file\": ${{ secrets.meetupr_token_file }}}"
    ))

    return(invisible(NULL))
  }

  if (auth_status$active_method == "OAuth (not authenticated)") {
    return(invisible(NULL))
  }

  cli::cli_h2("API Connectivity Test")

  tryCatch(
    {
      user_info <- get_self()

      if (!is.null(user_info)) {
        cli::cli_alert_success("API Connection: Working")
        cli::cli_alert_info(
          "Authenticated as: {.strong {user_info$name}} (ID: {user_info$id})"
        )
      } else {
        cli::cli_alert_warning("API Connection: Unexpected response")
      }
    },
    error = function(e) {
      cli::cli_alert_danger("API Connection: Failed - {e$message}")
    }
  )
}

#' Display status messages using cli
#'
#' A helper function to display status messages based on a condition.
#' It uses the `cli` package to format messages with different alert types.
#' If the condition is TRUE, it shows the `true_msg`
#' with the specified `true_type`.
#' If FALSE, it shows the `false_msg` with the specified `false_type`.
#' If either message is NULL, it does not display anything for that case.
#' @return Nothing. Messages are printed to the console.
#' @keywords internal
#' @noRd
cli_status <- function(
  condition,
  true_msg,
  false_msg,
  true_type = "success",
  false_type = "warning"
) {
  if (condition) {
    if (is.null(true_msg)) {
      return(invisible(NULL))
    }
    switch(
      true_type,
      "info" = cli::cli_alert_info(true_msg),
      "success" = cli::cli_alert_success(true_msg),
      "warning" = cli::cli_alert_warning(true_msg),
      "danger" = cli::cli_alert_danger(true_msg),
      cli::cli_text(true_msg)
    )
  } else {
    if (is.null(false_msg)) {
      return(invisible(NULL))
    }
    switch(
      false_type,
      "info" = cli::cli_alert_info(false_msg),
      "success" = cli::cli_alert_success(false_msg),
      "warning" = cli::cli_alert_warning(false_msg),
      "danger" = cli::cli_alert_danger(false_msg),
      cli::cli_text(false_msg)
    )
  }
}

#' Show configuration item with optional masking
#'
#' Displays a configuration item, masking its value if specified.
#' If the value is not set, it indicates that as well.
#' @param name The name of the configuration item.
#' @param value The value of the configuration item.
#' @param mask Logical indicating whether to mask the value (default is FALSE).
#' @return Invisibly returns NULL after displaying the item.
#' @keywords internal
#' @noRd
show_config_item <- function(name, value, mask = FALSE) {
  has_value <- nzchar(value) && !is.null(value)
  display_value <- if (mask && has_value) {
    paste0(substr(value, 1, 6), "...")
  } else {
    value
  }

  cli_status(
    has_value,
    glue::glue("{name}: {cli::col_blue(display_value)}"),
    glue::glue("{name}: Not set")
  )
}


#' Check if debug mode is enabled
#' @keywords internal
#' @noRd
check_debug_mode <- function() {
  debug <- Sys.getenv("MEETUPR_DEBUG")
  if (debug == 1) {
    return(TRUE)
  }
  FALSE
}
