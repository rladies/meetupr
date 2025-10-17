#' Create a Meetup OAuth Client
#'
#' This function initializes and returns an OAuth client for authenticating
#' with the Meetup API. It requires the Meetup client ID and secret, which
#' can be passed as arguments or retrieved from environment variables.
#'
#' @param client_id A string representing the Meetup client ID. By default,
#'   it is retrieved from the `meetup:client_id` environment variable.
#' @param client_secret A string representing the Meetup client secret. By
#'   default, it is retrieved from the `meetup:client_secret` environment
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
#' will throw an error prompting you to set the `meetup:client_id` and
#' `meetup:client_secret` environment variables.
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
      error = function(e) meetupr_client$id
    )
  }

  if (is.null(client_secret)) {
    client_secret <- tryCatch(
      meetup_key_get("client_secret"),
      error = function(e) meetupr_client$secret
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

#' Meetup API CI Authentication
#'
#' Functions to manage Meetup API authentication in Continuous Integration (CI)
#' environments. `meetup_setup_ci()` prepares authentication credentials for CI
#' use by encoding tokens, while `meetup_load_ci()` loads and decodes those
#' credentials in the CI environment.
#'
#' @template client_name
#'
#' @return
#' - `meetup_setup_ci()`: Returns the encoded base64 authentication token
#'   invisibly.
#' - `meetup_load_ci()`: Returns `TRUE` invisibly if the token was successfully
#'   loaded.
#'
#' @details
#' ## Setting up CI Authentication
#'
#' `meetup_setup_ci()` performs the following steps:
#' - Checks if the user has authenticated with the Meetup API
#' - Reads the existing token file from the OAuth cache directory
#' - Encodes the token file contents into a base64 string
#' - Stores credentials in the keyring with service name "meetupr"
#' - Provides guidance for setting environment variables in CI
#' - Copies the encoded token to the clipboard (if available)
#'
#' ## Loading CI Authentication
#'
#' `meetup_load_ci()` requires the following to be stored in the keyring
#' (typically populated from environment variables in CI):
#' - `token`: The base64-encoded token string
#'   (service: "meetupr", username: "token")
#' - `token_file`: The name of the token file
#'   (service: "meetupr", username: "token_file")
#'
#' The decoded token is saved in the OAuth cache directory at:
#' `{oauth_cache_path}/{client_name}/{token_file}`
#'
#' ## Environment Variables for CI
#'
#' When using the environment backend (automatically selected when keyring
#' support is unavailable, such as on CRAN or headless CI systems), credentials
#' are stored as:
#' - `meetupr:token` - The base64-encoded token
#' - `meetupr:token_file` - The token filename
#'
#' @examples
#' \dontrun{
#' # Setup CI authentication (run locally):
#' meetup_setup_ci()
#'
#' # In your CI pipeline, load the credentials:
#' meetup_load_ci()
#'
#' # Custom client name:
#' meetup_setup_ci(client_name = "my_custom_client")
#' meetup_load_ci(client_name = "my_custom_client")
#' }
#'
#' @name meetup_ci
#' @importFrom base64enc base64encode base64decode
#' @importFrom rlang is_installed
#' @importFrom clipr clipr_available write_clip
#' @importFrom cli cli_h1 cli_h2 cli_h3 cli_alert_info cli_alert_success
#'   cli_bullets cli_code cli_abort
#' @importFrom httr2 oauth_cache_path
NULL

#' @describeIn meetup_ci Setup authentication for CI environments
#' @export
meetup_ci_setup <- function(
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
  meetup_key_set(
    "token_file",
    basename(cache_path),
    client_name
  )
  meetup_key_set(
    "token",
    encoded_token,
    client_name
  )

  cli::cli_h2("Set CI Environment Variables:")

  secrets <- c(
    "{client_name}:token={encoded_token}",
    "{client_name}:token_file={basename(cache_path)}"
  )

  cli::cli_bullets(secrets)

  if (rlang::is_installed("clipr") && clipr::clipr_available()) {
    clipr::write_clip(encoded_token)
    cli::cli_alert_info("Token copied to clipboard!")
  }

  cli::cli_h3("Example GitHub Actions:")

  c(
    "env:",
    "  'meetupr:token': ${{ secrets.meetupr:token }}",
    "  'meetupr:token_file': ${{ secrets.meetupr:token_file}}",
    "steps:",
    "  - name: Use API",
    "    run: Rscript -e 'meetupr::get_events(\"my-group\")'"
  ) |>
    cli::cli_code()

  invisible(encoded_token)
}

#' @describeIn meetup_ci Load authentication from CI environment
#' @export
meetup_ci_load <- function(
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
#' @template client_name
#' @param ... Additional arguments to `meetup_client()`.
#' @return Nothing. Outputs messages indicating the result of the
#' process.
#'
#' @examples
#' \dontrun{
#' meetup_auth()
#'
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

  if (clear_keyring && keyring::has_keyring_support()) {
    if (clear_keyring) {
      sapply(c("token", "token_file"), function(key) {
        if (key_available(key, client_name = client_name)) {
          meetup_key_delete(key, client_name = client_name)
          cli::cli_alert_success(
            "Key {.val {key}} removed from keyring {.val {client_name}}"
          )
        }
      })
    }
  }
}
