#' Manage API keys in system keyring
#'
#' Store and retrieve keys securely using the system keyring.
#' Typically used for storing OAuth tokens and credentials
#'  for the meetupr package.
#'
#' @param key Character string indicating the key name to store/retrieve.
#'   Default is `"token"`. Valid options are `"client_id"`, `"client_secret"`,
#'   `"token"`, and `"token_file"`.
#' @param value Character string with the value to store. If
#'   `NULL` (default),
#'   prompts for interactive input.
#' @template client_name
#' @param error Logical. If `TRUE` (default), raises an
#'    error when key not found.
#'   If `FALSE`, returns `NULL`.
#'
#' @return
#' - `meetup_key_set()`: Returns `TRUE` invisibly on success
#' - `meetup_key_get()`: Returns the key value, or `NULL`
#'  if not found and `error = FALSE`
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

#' Get appropriate keyring backend
#' @keywords internal
#' @noRd
get_keyring_backend <- function() {
  tryCatch(
    {
      if (keyring::has_keyring_support()) {
        return(keyring::default_backend())
      }
      keyring::backend_env$new()
    },
    error = function(e) {
      keyring::backend_env$new()
    }
  )
}

#' @describeIn meetup_keys Store a key in the system keyring
#' @export
meetup_key_set <- function(
  key,
  value,
  client_name = Sys.getenv("MEETUP_CLIENT_NAME", "meetupr")
) {
  key <- key_name(key)

  backend <- get_keyring_backend()
  backend$set_with_value(
    service = client_name,
    username = key,
    password = value
  )
}

#' @describeIn meetup_keys Retrieve a key from the system keyring
#' @export
meetup_key_get <- function(
  key,
  client_name = Sys.getenv("MEETUP_CLIENT_NAME", "meetupr"),
  error = TRUE
) {
  backend <- get_keyring_backend()
  key <- key_name(key)

  tryCatch(
    backend$get(
      service = client_name,
      username = key
    ),
    error = function(e) {
      if (error) {
        cli::cli_abort("Key {.val {key}} not found")
      }
    }
  )
}

#' @describeIn meetup_keys Delete a key in the system keyring
#' @export
xmeetup_key_delete <- function(
  key,
  client_name = Sys.getenv("MEETUP_CLIENT_NAME", "meetupr")
) {
  backend <- get_keyring_backend()
  key <- key_name(key)

  tryCatch(
    backend$delete(
      service = client_name,
      username = key
    ),
    error = function(e) invisible(NULL)
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
  match.arg(
    key,
    c("client_id", "client_secret", "token", "token_file"),
    several.ok = FALSE
  )
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
#' @template client_name
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
key_available <- function(
  key,
  client_name = Sys.getenv("MEETUP_CLIENT_NAME", "meetupr")
) {
  key_name_val <- key_name(key)
  tryCatch(
    {
      available <- keyring::key_list(client_name)
      any(available$username == key_name_val)
    },
    error = function(e) {
      FALSE
    }
  )
}
