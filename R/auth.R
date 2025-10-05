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
#' @template client_name
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
  client_id = NULL,
  client_secret = NULL,
  client_name = Sys.getenv("MEETUP_CLIENT_NAME", "meetupr"),
  ...
) {
  if (is.null(client_id)) {
    client_id <- tryCatch(
      meetup_key_get("client_id"),
      error = function(e) meetup_builtin_key
    )
  }

  if (is.null(client_secret)) {
    client_secret <- tryCatch(
      meetup_key_get("client_secret"),
      error = function(e) meetup_builtin_secret
    )
  }

  httr2::oauth_client(
    id = client_id,
    secret = client_secret,
    name = client_name,
    ...,
    token_url = "https://secure.meetup.com/oauth2/access"
  )
}

#' Setup Meetup Authentication for CI Environments
#'
#' This function guides the user through setting up Meetup API authentication
#' for use in non-interactive Continuous Integration (CI) environments. It
#' encodes the existing authentication token as a base64 string and provides
#' instructions for storing it securely as environment variables in a CI
#' pipeline.
#'
#' @template client_name
#'
#' @return The encoded base64 authentication token as a character string.
#'   Returns invisibly.
#'
#' @details The function performs the following steps:
#'   - Checks if the user has authenticated with the Meetup API. If not,
#'     it prompts the user to authenticate interactively.
#'   - Reads the existing token file from the OAuth cache directory.
#'   - Encodes the token file contents into a base64 string.
#'   - Provides guidance to the user for storing the
#' base64 token (`MEETUP_TOKEN`)
#'     and token file name (`MEETUP_TOKEN_FILE`) as environment variables.
#'   - Copies the encoded token to the clipboard (if the `clipr` package is
#'     installed and the clipboard is available).
#'   - Displays example YAML configuration snippets for use in GitHub Actions.
#'
#' @examples
#' \dontrun{
#'   # Example usage to set up CI authentication:
#'   meetup_auth_setup_ci()
#'
#'   # Custom client name for token directory:
#'   meetup_auth_setup_ci(client_name = "my_custom_client")
#' }
#'
#' @importFrom base64enc base64encode
#' @importFrom rlang is_installed
#' @importFrom clipr clipr_available write_clip
#' @importFrom cli cli_h1 cli_h2 cli_alert_info cli_alert_success
#'   cli_bullets cli_code
#' @export
meetup_auth_setup_ci <- function(
  client_name = Sys.getenv("MEETUP_CLIENT_NAME", "meetupr")
) {
  cli::cli_h1("CI Authentication Setup")

  cli::cli_alert_info("Setting up authentication for non-interactive use...")

  meetup_auth_status()

  cache_path <- token_path(
    client_name = client_name,
    silent = TRUE
  )

  token_bytes <- readBin(
    cache_path,
    "raw",
    file.size(cache_path)
  )
  encoded_token <- base64enc::base64encode(token_bytes)

  cli::cli_alert_success("Credentials encoded for CI")

  cli::cli_h2("Storing credentials with keyring")
  meetup_key_set("token_file", basename(cache_path))
  meetup_key_set("token", encoded_token)

  cli::cli_h2("Set CI Environment Variables:")

  secrets <- c(
    "MEETUP_TOKEN={encoded_token}",
    "MEETUP_TOKEN_FILE={basename(cache_path)}"
  )

  cli::cli_bullets(secrets)

  if (rlang::is_installed("clipr") && clipr::clipr_available()) {
    clipr::write_clip(encoded_token)
    cli::cli_alert_info("Token copied to clipboard!")
  }

  cli::cli_h3("Example GitHub Actions:")

  c(
    "env:",
    "  MEETUP_TOKEN: ${{ secrets.MEETUP_TOKEN }}",
    "  MEETUP_TOKEN_FILE: ${{ secrets.MEETUP_TOKEN_FILE }}",
    "steps:",
    "  - name: Use API",
    "    run: Rscript -e 'meetupr::get_events(\"my-group\")'"
  ) |>
    cli::cli_code()

  invisible(encoded_token)
}


#' Load Meetup Authentication Token from CI Environment
#'
#' This function reads and decodes a Meetup API authentication token from
#' environment variables. The decoded token is then saved to a specified token
#' file within the OAuth cache directory for use by the application. This
#' function is designed to integrate with Continuous Integration (CI)
#' pipelines.
#'
#' @template client_name
#'
#' @return Invisible `TRUE` if the token was successfully loaded and decoded.
#'   If an error occurs, the function will throw an error and halt execution.
#'
#' @details The function requires the following environment variables to be
#'   set in the CI environment:
#'   - `MEETUP_TOKEN`: The base64-encoded token string.
#'   - `MEETUP_TOKEN_FILE`: The name of the file where the decoded token
#'     will be stored.
#'
#'   If any of these variables are not set, the function will terminate with an
#'   error.
#'
#'   The decoded token is saved in the OAuth cache directory at a path
#'   constructed as `{oauth_cache_path}/{client_name}/{MEETUP_TOKEN_FILE}`.
#'
#' @examples
#' \dontrun{
#'   # Example usage in a CI pipeline with the required environment variables:
#'   meetup_auth_load_ci()
#'
#'   # Overriding the default client name:
#'   meetup_auth_load_ci(client_name = "my_custom_client")
#' }
#'
#' @importFrom base64enc base64decode
#' @importFrom httr2 oauth_cache_path
#' @importFrom cli cli_abort cli_alert_info cli_alert_success
#' @export
meetup_auth_load_ci <- function(
  client_name = Sys.getenv("MEETUP_CLIENT_NAME", "meetupr")
) {
  # Get encoded token from environment
  encoded_token <- meetup_key_get("token")
  token_file <- meetup_key_get("token_file")

  cli::cli_alert_info("Loading token from environment...")

  token_bytes <- base64enc::base64decode(encoded_token)
  token_path <- file.path(
    httr2::oauth_cache_path(),
    client_name,
    token_file
  )
  dir.create(
    dirname(token_path),
    recursive = TRUE,
    showWarnings = FALSE
  )
  writeBin(token_bytes, token_path)

  cli::cli_alert_success("Token loaded successfully")
  invisible(TRUE)
}

#' Check Authentication Status for Meetup API
#'
#' This function verifies if a user is
#' authenticated to interact with the Meetup
#' API by checking the existence of token
#' cache files in the specified directory.
#'
#' @details
#' The function checks the \code{httr2} OAuth cache directory for encrypted
#' token files (\code{.rds.enc}) associated with the specified client. Based on
#' the results, it provides feedback about the authentication status. Multiple
#' tokens in the cache directory trigger a warning, while a missing token or
#' cache directory result in an error message.
#'
#' @template client_name
#' @param silent A \code{logical} indicating whether to suppress output
#' messages. Defaults to \code{FALSE}.
#'
#' @return logical. \code{TRUE} if a valid token
#' is found, \code{FALSE} otherwise.
#' If \code{silent} is \code{FALSE}, the function outputs status messages.
#' @export
#' @examples
#' \dontrun{
#' # Check authentication status with default client name
#' status <- meetup_auth_status()
#'
#' # Check authentication status with a specific client name
#' status <- meetup_auth_status(client_name = "custom_client")
#'
#' # Suppress output messages
#' status <- meetup_auth_status(silent = TRUE)
#' }
#'
#' @seealso
#' \code{\link[httr2]{oauth_cache_path}}, \code{\link[cli]{cli_alert}}
meetup_auth_status <- function(
  client_name = Sys.getenv("MEETUP_CLIENT_NAME", "meetupr"),
  silent = FALSE
) {
  cache_path <- file.path(
    httr2::oauth_cache_path(),
    client_name
  )

  if (!dir.exists(cache_path)) {
    if (!silent) {
      cli::cli_alert_danger("Not authenticated: No token cache found")
    }
    return(FALSE)
  }

  cache_files <- list.files(
    cache_path,
    pattern = ".rds.enc$",
    full.names = TRUE,
    recursive = TRUE
  )

  if (length(cache_files) == 0) {
    if (!silent) {
      cli::cli_alert_danger("Not authenticated: No token found")
    }
    return(FALSE)
  }

  if (length(cache_files) > 1) {
    cli::cli_warn(
      "Multiple tokens found in {.path {cache_path}}.
      Please clean up before proceeding."
    )
  }

  if (!silent) {
    cli::cli_alert_success("Token found: {.path {cache_files}}")
  }
  TRUE
}

#' @describeIn meetup_auth_status Check if authenticated
#' to Meetup API. Uses silent mode.
has_auth <- function(
  client_name = Sys.getenv("MEETUP_CLIENT_NAME", "meetupr")
) {
  meetup_auth_status(
    client_name,
    silent = TRUE
  )
}

#' Meetup API Authentication
#'
#' Functions to manage authentication with the Meetup API.
#' Includes functions to authenticate,
#' and deauthorize by removing cached credentials.
#'
#' @template client_name
#' @param clear_keyring A logical value indicating whether to clear
#' the associated keyring entries. Defaults to `TRUE`.
#' @param ... Additional arguments to `meetup_client()`.
#' @return Nothing. Outputs messages indicating the result of the
#' process.
#'
#' @examples
#' \dontrun{
#' # Default deauthorization
#' meetup_deauth()
#'
#' # Deauthorization with a custom client name
#' meetup_deauth(client_name = "custom_client")
#' }
#' @name meetup_auth
#' @export
NULL

#' @describeIn meetup_auth Authenticate and display the
#' authenticated user's name.
meetup_auth <- function(...) {
  resp <- meetup_req(...) |>
    httr2::req_body_json(
      list(
        query = "query { self { name } }"
      ),
      auto_unbox = TRUE
    ) |>
    httr2::req_perform() |>
    httr2::resp_body_json(simplifyVector = TRUE)

  # nolint start
  auth_name <- resp$data$self$name
  cli::cli_alert_success(
    "Authenticated as {.val {auth_name}}"
  )
  # nolint end
}

#' @describeIn meetup_auth Remove cached authentication
#' for the Meetup API client.
meetup_deauth <- function(
  client_name = Sys.getenv(
    "MEETUP_CLIENT_NAME",
    "meetupr"
  ),
  clear_keyring = TRUE
) {
  cache_path <- file.path(
    httr2::oauth_cache_path(),
    client_name
  )

  if (dir.exists(cache_path)) {
    unlink(cache_path, recursive = TRUE)
    cli::cli_alert_success("Authentication cache removed")
  } else {
    cli::cli_alert_info("No authentication cache to remove")
  }

  if (clear_keyring) {
    keys_to_clear <- c("client_id", "client_secret", "token", "token_file") |>
      sapply(key_name)

    sapply(keys_to_clear, function(key) {
      if (!key_available(key)) {
        return(FALSE)
      }
      keyring::key_delete(key)
      cli::cli_alert_success("Keyring {.val {key}} cleared")
      TRUE
    })
  }
}
