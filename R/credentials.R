#' Manage API keys in system keyring
#'
#' Store and retrieve keys securely using the system keyring.
#' Typically used for storing OAuth tokens and credentials for the meetupr package.
#'
#' @param key Character string indicating the key name to store/retrieve.
#'   Default is `"token"`. Valid options are `"client_id"`, `"client_secret"`,
#'   `"token"`, and `"token_file"`.
#' @param value Character string with the value to store. If `NULL` (default),
#'   prompts for interactive input via `readline()`.
#' @param error Logical. If `TRUE` (default), raises an error when key not found.
#'   If `FALSE`, returns `NULL`.
#'
#' @return
#' - `meetup_key_set()`: Returns `TRUE` invisibly on success
#' - `meetup_key_get()`: Returns the key value, or `NULL` if not found and `error = FALSE`
#'
#' @examples
#' \dontrun{
#' meetup_key_set("token", "my-access-token")
#' meetup_key_set("client_id")
#'
#' meetup_key_get("token")
#' meetup_key_get("missing_key", error = FALSE)
#' }
#' @name meetup_keys
NULL

#' @describeIn meetup_keys Store a key in the system keyring
#' @export
meetup_key_set <- function(key = "token", value = NULL) {
  key <- key_name(key)

  if (is.null(value)) {
    value <- get_input(key)
  }

  keyring::key_set_with_value(service = key, password = value)

  cli::cli_alert_success("Credentials for {.val {key}} stored securely")
  invisible(TRUE)
}

#' @describeIn meetup_keys Retrieve a key from the system keyring
#' @export
meetup_key_get <- function(key = "token", error = TRUE) {
  key <- key_name(key)
  tryCatch(
    keyring::key_get(key),
    error = function(e) {
      if (error) {
        cli::cli_abort("Key {.val {key}} not found in keyring")
      } else {
        NULL
      }
    }
  )
}

#' Create standardized key names
#'
#' This function generates standardized key names for storing in the keyring,
#' prefixing them with "MEETUP_" and converting to uppercase.
#' @param key A character string indicating the name of the key.
#' Valid options are "client_id", "client_secret", "token", and "token_file".
#' Default is "token".
#' @return A character string representing the standardized key name.
#' @keywords internal
#' @noRd
key_name <- function(key = "token") {
  key <- match.arg(
    key,
    c("client_id", "client_secret", "token", "token_file"),
    several.ok = FALSE
  )
  paste0("meetup_", key) |>
    toupper()
}

#' Prompt user for input
#' @param key The key for which to prompt input.
#' @return The user input as a character string.
#' @keywords internal
#' @noRd
get_input <- function(key) {
  glue::glue("Enter value for {.val {key}}: ") |>
    readline()
}

#' Find token
#'
#' Locate the OAuth token file in the httr2 cache directory.
#' This function searches for a single token file matching the
#' specified pattern within the httr2 OAuth cache directory.
#' If multiple or no tokens are found, it raises an error.
#' The function returns the path to the found token file.
#' @param pattern A regex pattern to match the token file name.
#' Defaults to ".rds.enc$".
#' @param client_name The name of the OAuth client.
#' Defaults to the value of the "MEETUP_CLIENT_NAME"
#' environment variable or "meetupr" if not set.
#' @keywords internal
#' @noRd
token_path <- function(
  pattern = ".rds.enc$",
  client_name = Sys.getenv("MEETUP_CLIENT_NAME", "meetupr"),
  silent = FALSE
) {
  cache_path <- file.path(
    httr2::oauth_cache_path(),
    client_name
  )

  cache_file <- list.files(
    cache_path,
    pattern,
    full.names = TRUE,
    recursive = TRUE
  )

  if (length(cache_file) != 1) {
    if (length(cache_file) > 1) {
      cli::cli_abort(
        "Multiple tokens found. Please clean up: {.path {cache_path}}"
      )
    }
    cli::cli_abort("No token found. Please authenticate first.")
  }

  if (!silent) {
    cli::cli_alert_success("Token found: {.path {cache_file}}")
  }

  cache_file
}

#' Check if a Key is Available in the Keyring
#' @keywords internal
#' @noRd
key_available <- function(key) {
  available <- keyring::key_list(key)
  nrow(available) > 0
}
