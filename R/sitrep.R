#' Show meetupr authentication status
#'
#' This function checks the authentication status for
#' the Meetup API by attempting
#' to create an OAuth client using the `meetupr` package.
#' It provides feedback on whether
#' the credentials are configured correctly or if there are any issues.
#' If there are issues with the credentials, it provides
#' setup instructions to help
#' the user configure their environment correctly.
#'
#' It also informs the user that authentication is handled
#' automatically when making requests
#' and checks if debug mode is enabled via the
#' `MEETUPR_DEBUG` environment variable.
#' @return Invisibly returns `NULL`. The primary purpose of
#' this function is to display
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

# Custom helper functions
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

#' Display configuration item with optional masking
#' @keywords internal
#' @noRd
show_config_item <- function(
  name,
  value,
  mask = FALSE
) {
  has_value <- nzchar_null(value)
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

#' Check RSA Key Status
#' @keywords internal
#' @noRd
get_rsa_key_status <- function(rsa_path, rsa_key) {
  if (nzchar_null(rsa_path)) {
    if (!file.exists(rsa_path)) {
      return(list(
        valid = FALSE,
        message = "File not found"
      ))
    } else if (file.info(rsa_path)$isdir) {
      return(list(
        valid = FALSE,
        message = "Path is a directory, not a file"
      ))
    }

    tryCatch(
      {
        key_content <- paste(readLines(rsa_path, warn = FALSE), collapse = "\n")
        if (validate_rsa_key(key_content)) {
          return(list(valid = TRUE, message = "Valid RSA key file"))
        }
        list(
          valid = FALSE,
          message = "File exists but doesn't contain valid RSA key"
        )
      },
      error = function(e) {
        list(
          valid = FALSE,
          message = paste("Cannot read file:", e$message)
        )
      }
    )
  } else if (nzchar_null(rsa_key)) {
    if (validate_rsa_key(rsa_key)) {
      return(list(
        valid = TRUE,
        message = "Valid RSA key in environment"
      ))
    }
    return(list(
      valid = FALSE,
      message = "Environment variable set but doesn't contain valid RSA key"
    ))
  }
  list(
    valid = FALSE,
    message = "Not set"
  )
}

#' Validate RSA Key
#' @keywords internal
#' @noRd
validate_rsa_key <- function(key_content) {
  if (!nzchar_null(key_content)) {
    return(FALSE)
  }

  # Check for PEM format markers
  has_begin <- grepl("-----BEGIN", key_content)
  has_end <- grepl("-----END", key_content)
  has_rsa_markers <- grepl("(PRIVATE KEY|RSA PRIVATE KEY)", key_content)

  has_begin && has_end && has_rsa_markers
}

#' Show RSA Key Status
#' @keywords internal
#' @noRd
show_rsa_status <- function(rsa_path, rsa_key) {
  status <- get_rsa_key_status(rsa_path, rsa_key)

  if (status$valid) {
    if (nzchar_null(rsa_path)) {
      cli::cli_alert_success(
        "RSA Key: {.path {rsa_path}}"
      )
    } else {
      cli::cli_alert_success(
        "RSA Key: Set via environment"
      )
    }
  } else {
    if (nzchar_null(rsa_path)) {
      cli::cli_alert_danger(
        "RSA Key: {.path {rsa_path}} {status$message}"
      )
    } else {
      cli::cli_alert_danger("RSA Key: {status$message}")
    }
  }
}

#' Check available authentication methods
#' @keywords internal
#' @noRd
check_auth_methods <- function() {
  auth_status <- list()

  # Check JWT credentials
  jwt_available <- has_jwt_credentials()

  auth_status$jwt <- list(
    available = jwt_available,
    client_id = Sys.getenv("MEETUP_CLIENT_ID"),
    member_id = Sys.getenv("MEETUP_MEMBER_ID"),
    rsa_path = Sys.getenv("MEETUP_RSA_PATH"),
    rsa_key = Sys.getenv("MEETUP_RSA_KEY")
  )

  # Check OAuth credentials
  oauth_available <- has_oauth_credentials()

  auth_status$oauth <- list(
    available = oauth_available,
    client_id = Sys.getenv("MEETUP_CLIENT_ID"),
    client_secret = Sys.getenv("MEETUP_CLIENT_SECRET")
  )

  # Determine active method (JWT takes priority)
  auth_status$active_method <- if (jwt_available) {
    "JWT"
  } else if (oauth_available) {
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
  # Active authentication method
  cli::cli_h2("Active Authentication Method")

  cli_status(
    auth_status$active_method == "JWT",
    "JWT Authentication - {.val Active} - Perfect for M2M workflows",
    NULL,
    "success"
  )

  cli_status(
    auth_status$active_method == "OAuth",
    "OAuth Authentication - {.val Active} - Interactive browser auth",
    NULL,
    "success"
  )

  cli_status(
    auth_status$active_method == "None",
    "No Authentication Configured",
    NULL,
    true_type = "danger"
  )

  # Show configuration details
  if (auth_status$active_method == "JWT") {
    cli::cli_h3("JWT Configuration:")
    show_config_item("Client ID", auth_status$jwt$client_id, mask = TRUE)
    show_config_item("Member ID", auth_status$jwt$member_id)
    show_rsa_status(auth_status$jwt$rsa_path, auth_status$jwt$rsa_key)
  } else if (auth_status$active_method == "OAuth") {
    cli::cli_h3("OAuth Configuration:")
    show_config_item("Client ID", auth_status$oauth$client_id, mask = TRUE)
    show_config_item(
      "Client Secret",
      if (nzchar_null(auth_status$oauth$client_secret)) "Set" else ""
    )
  }

  # Available methods summary
  cli::cli_h2("Available Authentication Methods")

  cli_status(
    auth_status$jwt$available,
    "JWT: Available' (Machine-to-Machine)",
    "JWT: Not configured'",
    "success",
    "warning"
  )

  # Show missing JWT variables if not available
  if (!auth_status$jwt$available) {
    missing_jwt <- c()
    if (!nzchar_null(auth_status$jwt$client_id)) {
      missing_jwt <- c(missing_jwt, "MEETUP_CLIENT_ID")
    }
    if (!nzchar_null(auth_status$jwt$member_id)) {
      missing_jwt <- c(missing_jwt, "MEETUP_MEMBER_ID")
    }
    if (
      !nzchar_null(auth_status$jwt$rsa_path) &&
        !nzchar_null(auth_status$jwt$rsa_key)
    ) {
      missing_jwt <- c(missing_jwt, "MEETUP_RSA_PATH or MEETUP_RSA_KEY")
    }
    cli::cli_text("   Missing: {.envvar {missing_jwt}}")
  }

  cli_status(
    auth_status$oauth$available,
    "OAuth: Available (Interactive)",
    "OAuth: Not configured",
    "success",
    "warning"
  )

  # Show missing OAuth variables if not available
  if (!auth_status$oauth$available) {
    missing_oauth <- c()
    if (!nzchar_null(auth_status$oauth$client_id)) {
      missing_oauth <- c(missing_oauth, "MEETUP_CLIENT_ID")
    }
    if (!nzchar_null(auth_status$oauth$client_secret)) {
      missing_oauth <- c(missing_oauth, "MEETUP_CLIENT_SECRET")
    }
    cli::cli_text("   Missing: {.envvar {missing_oauth}}")
  }

  cli::cli_h2("Package Settings")

  cli_status(
    auth_status$debug$enabled,
    "Debug Mode: {cli::col_yellow('Enabled')}",
    "Debug Mode: {cli::col_red('Disabled')} - 
      Set {.envvar MEETUPR_DEBUG=1} to enable verbose logging",
    "success",
    "info"
  )

  api_endpoint <- Sys.getenv(
    "MEETUP_API_URL",
    meetup_api_prefix()
  )
  cli::cli_alert_info("API endpoint in use: {.url {api_endpoint}}")
}

#' Test API connectivity
#' @keywords internal
#' @noRd
test_api_connectivity <- function(auth_status) {
  if (auth_status$active_method == "None") {
    cli::cli_h2("Setup Instructions")

    cli::cli_h3("For automated workflows (recommended):")
    cli::cli_ol(c(
      "See vignette: 
        {.code vignette('jwt-authentication', package = 'meetupr')}",
      "Create OAuth client at 
      {.url https://secure.meetup.com/meetup_api/oauth_consumers/}",
      "Generate RSA signing keys in your OAuth client settings",
      "Set environment variables: {.envvar MEETUP_CLIENT_ID},
       {.envvar MEETUP_MEMBER_ID}, {.envvar MEETUP_RSA_PATH}"
    ))

    cli::cli_h3("For interactive development:")
    cli::cli_ol(c(
      "Create OAuth client at 
      {.url https://secure.meetup.com/meetup_api/oauth_consumers/}",
      "Set redirect URI to: 
        {.strong http://localhost:1410}",
      "Set environment variables: 
        {.envvar MEETUP_CLIENT_ID}",
      " {.envvar MEETUP_CLIENT_SECRET}"
    ))

    return(invisible(NULL))
  }

  cli::cli_h2("API Connectivity Test")

  tryCatch(
    {
      user_info <- get_self()

      # Check if we got self data back
      if (!is.null(user_info)) {
        cli_status(
          TRUE,
          "API Connection: Working",
          NULL,
          "success"
        )
        cli::cli_alert_info(
          "Authenticated as: {.strong {user_info$name}} (ID: {user_info$id})"
        )
      } else {
        cli_status(
          FALSE,
          NULL,
          "API Connection: Unexpected response",
          false_type = "warning"
        )
      }
    },
    error = function(e) {
      cli::cli_alert_danger(
        "API Connection: Failed - {e$message}"
      )
    }
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
  nzchar_null(debug)
}
