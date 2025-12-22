#' Show meetupr authentication status
#'
#' This function checks the authentication status for the Meetup API.
#' It provides feedback on whether credentials are configured
#' correctly, tests API connectivity, and shows available
#' authentication methods.
#'
#' @return Invisibly returns a list with authentication status
#'   details.
#' @examples
#' meetupr_sitrep()
#'
#' @export
meetupr_sitrep <- function() {
  cli::cli_h1("meetupr Situation Report")

  auth_status <- meetupr_auth_status(silent = TRUE)

  display_auth_status(auth_status)

  test_api_connectivity()

  invisible(auth_status)
}

#' Display authentication status
#' @keywords internal
#' @noRd
display_auth_status <- function(auth_status) {
  cli::cli_h2("Active Authentication Method")

  if (auth_status$auth$any) {
    cli::cli_alert_success("Authentication available")
    cli::cli_alert_info(
      "Active method: {.strong {auth_status$auth$method}}"
    )
    cli::cli_alert_info("Client name: {.strong {auth_status$auth$client_name}}")
  } else {
    cli::cli_alert_danger("No Authentication Configured")
  }

  # Show details for each method
  if (auth_status$jwt$available) {
    cli::cli_alert_success("JWT token: Available and valid")
    if (!is.na(auth_status$jwt$issuer)) {
      cli::cli_alert_success(
        "JWT issuer: {.strong {auth_status$jwt$issuer}}"
      )
    } else {
      cli::cli_alert_danger(
        "JWT issuer: {.strong (unknown)}"
      )
    }

    if (!is.na(auth_status$jwt$client_key)) {
      cli::cli_alert_success(
        "Client key: {.strong {substr(auth_status$jwt$client_key, 1, 6)}}..."
      )
    } else {
      cli::cli_alert_danger(
        "Client key: {.strong (unknown)}"
      )
    }
  } else if (auth_status$encrypted$available) {
    cli::cli_alert_success("Encrypted token: Available")
    if (!is.na(auth_status$encrypted$path)) {
      cli::cli_alert_success(
        "Encrypted token path: {.strong {auth_status$encrypted$path}}"
      )
    }
    if (auth_status$encrypted$pwd) {
      cli::cli_alert_success(
        "Password for decryption: Set"
      )
    } else {
      cli::cli_alert_danger(
        "Password for decryption: Not set"
      )
    }
  } else if (auth_status$cache$available) {
    cli::cli_alert_success("OAuth cache: Available")
  }
}

#' Test API connectivity
#' @keywords internal
#' @noRd
test_api_connectivity <- function() {
  if (!has_auth()) {
    cli::cli_h2("Setup Instructions")
    cli::cli_h3("Interactive Setup:")
    cli::cli_ol(c(
      "Run {.code meetupr_auth()} to authenticate"
    ))
    cli::cli_h3("CI/CD Setup:")
    cli::cli_ul(c(
      "Authenticate locally first with",
      "{.code meetupr_auth()}",
      "See the vignette on setting up authentication for CI/CD:",
      "{.url https://rladies.org/meetupr/articles/advanced-auth.html}"
    ))
    return(invisible(NULL))
  }

  cli::cli_h2("API Connectivity Test")
  tryCatch(
    {
      user_info <- get_self()
      if (!is.null(user_info)) {
        cli::cli_alert_success("API Connection: Working")
        cli::cli_alert_info(
          "Authenticated as: {.strong {user_info$name}}",
          "(ID: {user_info$id})"
        )
      } else {
        cli::cli_alert_warning(
          "API Connection: Unexpected response"
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
