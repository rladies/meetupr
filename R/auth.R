#' Create a Meetup OAuth Client
#'
#' This function initializes and returns an OAuth client for authenticating
#' with the Meetup API. It requires the Meetup client ID and secret, which
#' can be passed as arguments or retrieved from environment variables.
#'
#' @param client_id A string representing the Meetup client ID. By default,
#'   it is retrieved from the `MEETUP_CLIENT_ID` environment variable.
#' @param client_secret A string representing the Meetup client secret. By
#'   default, it is retrieved from the `MEETUP_CLIENT_SECRET` environment
#'   variable.
#' @param client_name A string representing the name of the client. By
#'   default, it is set to `"meetupr"` and retrieved from the
#'   `MEETUP_CLIENT_NAME` environment variable.
#' @param ... Additional arguments passed to the `httr2::oauth_client` function.
#'
#' @return An OAuth client object created with the `httr2::oauth_client`
#'   function. This client can be used to handle authentication with the
#'   Meetup API.
#'
#' @examples
#' \dontrun{
#' # Example 1: Using environment variables to set credentials
#' client <- meetup_client()
#'
#' # Example 2: Passing client ID and secret as arguments
#' client <- meetup_client(
#'   client_id = "your_client_id",
#'   client_secret = "your_client_secret"
#' )
#' }
#'
#' @details
#' If the `client_id` or `client_secret` parameters are empty, the function
#' will throw an error prompting you to set the `MEETUP_CLIENT_ID` and
#' `MEETUP_CLIENT_SECRET` environment variables.
#'
#' @export
meetup_client <- function(
  client_id = Sys.getenv("MEETUP_CLIENT_ID"),
  client_secret = Sys.getenv("MEETUP_CLIENT_SECRET"),
  client_name = Sys.getenv("MEETUP_CLIENT_NAME", "meetupr"),
  ...
) {
  if (!nzchar(client_id) || !nzchar(client_secret)) {
    cli::cli_abort(c(
      "Meetup client ID and secret are required.",
      "i" = "Set {.envvar MEETUP_CLIENT_ID} and 
      {.envvar MEETUP_CLIENT_SECRET} environment variables."
    ))
  }

  httr2::oauth_client(
    id = client_id,
    secret = client_secret,
    name = client_name,
    ...,
    token_url = "https://secure.meetup.com/oauth2/access"
  )
}


#' Check for JWT Credentials
#'
#' This function checks if the necessary environment variables for using
#' JWT authentication with Meetup API are set.
#'
#' @details
#' The function validates the existence of the following environment variables:
#' - MEETUP_CLIENT_ID: Your Meetup client ID.
#' - MEETUP_MEMBER_ID: Your Meetup member ID.
#' - MEETUP_RSA_KEY or MEETUP_RSA_PATH: RSA key or its path used for signing.
#'
#' @return
#' A logical value:
#' - `TRUE` if all the required JWT credentials are set,
#' - `FALSE` otherwise.
#'
#' @examples
#' Sys.setenv(MEETUP_CLIENT_ID = "12345",
#'            MEETUP_MEMBER_ID = "67890",
#'            MEETUP_RSA_KEY = "example_rsa_key")
#' has_jwt_credentials() # Should return TRUE
#'
#' Sys.setenv(MEETUP_RSA_KEY = "")
#' has_jwt_credentials() # Should return FALSE
#' @export
has_jwt_credentials <- function() {
  rsa_path <- Sys.getenv("MEETUP_RSA_PATH")
  if (nzchar(rsa_path) && !file.exists(rsa_path)) {
    rsa_path <- ""
  }

  rsa <- nzchar(rsa_path) ||
    nzchar(Sys.getenv("MEETUP_RSA_PATH"))

  nzchar(Sys.getenv("MEETUP_CLIENT_ID")) &&
    nzchar(Sys.getenv("MEETUP_MEMBER_ID")) &&
    rsa
}

#' Check for OAuth Credentials
#'
#' This function checks if the necessary environment variables for using
#' OAuth authentication with Meetup API are set.
#'
#' @details
#' The function validates the existence of the following environment variables:
#' - MEETUP_CLIENT_ID: Your Meetup client ID.
#' - MEETUP_CLIENT_SECRET: Your Meetup client secret.
#'
#' @return
#' A logical value:
#' - `TRUE` if all the required OAuth credentials are set,
#' - `FALSE` otherwise.
#'
#' @examples
#' Sys.setenv(MEETUP_CLIENT_ID = "12345",
#'            MEETUP_CLIENT_SECRET = "example_secret")
#' has_oauth_credentials() # Should return TRUE
#'
#' Sys.setenv(MEETUP_CLIENT_SECRET = "")
#' has_oauth_credentials() # Should return FALSE
#' @export
has_oauth_credentials <- function() {
  nzchar(Sys.getenv("MEETUP_CLIENT_ID")) &&
    nzchar(Sys.getenv("MEETUP_CLIENT_SECRET"))
}

#' Retrieve RSA Private Key
#' @keywords internal
#' @noRd
get_rsa_key <- function(rsa_path = Sys.getenv("MEETUP_RSA_PATH")) {
  if (nzchar(rsa_path)) {
    if (!file.exists(rsa_path)) {
      cli::cli_abort("Private key file not found: {.path {rsa_path}}")
    }
    return(
      paste(
        readLines(rsa_path, warn = FALSE),
        collapse = "\n"
      )
    )
  }
  rsa_key <- Sys.getenv("MEETUP_RSA_KEY")
  if (nzchar(rsa_key)) {
    return(rsa_key)
  }
  cli::cli_abort(c(
    "RSA private key not found.",
    "Set {.envvar MEETUP_RSA} or {.envvar MEETUP_RSA_PATH}"
  ))
}
