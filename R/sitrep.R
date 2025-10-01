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

  # Check OAuth credentials
  oauth_available <- meetup_auth_status(silent = TRUE)

  # Check for cached token
  has_token <- tryCatch(
    {
      token_path(pattern = ".rds.enc$")
      TRUE
    },
    error = function(e) FALSE
  )

  # Check CI environment
  ci_token <- nzchar(Sys.getenv("MEETUP_TOKEN")) &&
    nzchar(Sys.getenv("MEETUP_TOKEN_FILE"))

  auth_status$oauth <- list(
    available = oauth_available,
    client_id = Sys.getenv("MEETUP_CLIENT_ID"),
    client_secret = Sys.getenv("MEETUP_CLIENT_SECRET"),
    has_cached_token = has_token,
    ci_mode = ci_token
  )

  # Determine active method
  auth_status$active_method <- if (has_token || ci_token) {
    "OAuth"
  } else if (oauth_available) {
    "OAuth (not authenticated)"
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
    cli::cli_text("   Run {.code meetup_auth()} to authenticate")
  } else {
    cli::cli_alert_danger("No Authentication Configured")
  }

  # Show OAuth configuration
  cli::cli_h2("OAuth Configuration")

  show_config_item("Client ID", auth_status$oauth$client_id, mask = TRUE)
  show_config_item(
    "Client Secret",
    if (nzchar(auth_status$oauth$client_secret)) "Set" else ""
  )

  cli_status(
    auth_status$oauth$has_cached_token,
    "Cached Token: Available",
    "Cached Token: None - run {.code meetup_auth()}",
    "success",
    "info"
  )

  if (auth_status$oauth$ci_mode) {
    cli::cli_alert_info("CI environment detected (MEETUP_TOKEN set)")
  }

  # Package settings
  cli::cli_h2("Package Settings")

  cli_status(
    auth_status$debug$enabled,
    "Debug Mode: {cli::col_yellow('Enabled')}",
    "Debug Mode: Disabled - Set {.envvar MEETUPR_DEBUG=1} or use {.code local_meetupr_debug(1)}",
    "info",
    "info"
  )

  api_endpoint <- Sys.getenv("MEETUP_API_URL", meetup_api_prefix())
  cli::cli_alert_info("API endpoint: {.url {api_endpoint}}")
}

#' Test API connectivity
#' @keywords internal
#' @noRd
test_api_connectivity <- function(auth_status) {
  if (auth_status$active_method == "None") {
    cli::cli_h2("Setup Instructions")

    cli::cli_h3("Interactive Setup:")
    cli::cli_ol(c(
      "Create OAuth client at {.url https://www.meetup.com/api/oauth/list}",
      "Set redirect URI to: {.strong http://localhost:1410}",
      "Set environment variables in {.code .Renviron}:",
      "  {.envvar MEETUP_CLIENT_ID=your_client_id}",
      "  {.envvar MEETUP_CLIENT_SECRET=your_secret}",
      "Restart R and run {.code meetup_auth()}"
    ))

    cli::cli_h3("CI/CD Setup:")
    cli::cli_ol(c(
      "Authenticate locally first with {.code meetup_auth()}",
      "Run {.code meetup_auth_setup_ci()} to get encoded token",
      "Set secrets in your CI: {.envvar MEETUP_TOKEN} and {.envvar MEETUP_TOKEN_FILE}"
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

# Helper functions from original remain the same
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
