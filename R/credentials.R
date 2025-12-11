valid_keys <- c(
  "client_key",
  "client_secret",
  "encrypt_path",
  "encrypt_pwd",
  "jwt_token",
  "jwt_issuer"
)

#' Manage API Keys via Environment Variables
#'
#' Store and retrieve credentials using environment variables.
#'
#' @details
#' This is an alias of `meetupr_credentials` with hyphenated envvar names.
#' Credentials are stored as environment variables with the pattern
#' `{client_name}-{key}` (e.g., `meetupr-client_key`).
#'
#' \itemize{
#' \item `client_key`: OAuth client ID
#' \item `client_secret`: OAuth client secret
#' \item `encrypt_path`: Path to encrypted token file
#' \item `encrypt_pwd`: Password for encrypted token
#' \item `jwt_token`: JWT token for service account authentication
#' \item `jwt_issuer`: JWT issuer, Meetup account number
#' }
#'
#' @param key Key name: `"client_key"`, `"client_secret"`, `"encrypt_path"`,
#'   `"encrypt_pwd"`, `"jwt_token"` or `"jwt_issuer"`.
#' @param value Value to be stored.
#' @template client_name
#' @param error Throw error if key not found. Default TRUE.
#'
#' @return
#' - [meetupr_key_set()]: NULL (invisibly)
#' - [meetupr_key_get()]: Character string or NA
#' - [meetupr_key_delete()]: NULL (invisibly)
## Credentials helpers (underscore-only envvar names)

#' Manage API Keys via Environment Variables
#'
#' Store and retrieve credentials using environment variables.
#'
#' @param key Key name, see details for options.
#' @param value Value to be stored.
#' @template client_name
#' @param error Throw error if key not found. Default TRUE.
#'
#' @return
#' - [meetupr_key_set()]: NULL (invisibly)
#' - [meetupr_key_get()]: Character string or NA
#' - [meetupr_key_delete()]: NULL (invisibly)
#' - [key_available()]: Logical
#'
#' @examples
#' \dontrun{
#' meetupr_key_set("client_key", "your_id")
#' client_key <- meetupr_key_get("client_key")
#' meetupr_key_delete("client_key")
#' }
#'
#' @name meetupr_credentials
NULL


#' @describeIn meetupr_credentials Store a key in environment variables
#' @export
meetupr_key_set <- function(
  key,
  value,
  client_name = get_client_name()
) {
  key <- key_name(key)
  env_var_name <- paste0(client_name, "_", key)
  do.call(
    Sys.setenv,
    stats::setNames(list(value), env_var_name)
  )
  invisible(NULL)
}


#' @describeIn meetupr_credentials Retrieve a key from environment variables
#' @export
meetupr_key_get <- function(
  key,
  client_name = get_client_name(),
  error = TRUE
) {
  key <- key_name(key)
  env_var_name <- paste0(client_name, "_", key)
  env_value <- Sys.getenv(env_var_name, unset = NA)
  if (!is_empty(env_value)) {
    return(env_value)
  }
  if (error) {
    cli::cli_abort(
      c(
        "Key {.val {key}} not found.",
        "i" = "Set via {.envvar {env_var_name}} environment variable."
      )
    )
  }
  NA
}


#' @describeIn meetupr_credentials Delete a key from environment variables
#' @export
meetupr_key_delete <- function(
  key,
  client_name = get_client_name()
) {
  key <- key_name(key)
  env_var_name <- paste0(client_name, "_", key)
  Sys.unsetenv(env_var_name)
  invisible(NULL)
}

#' Remove all credentials and cached tokens for a client
#' @param client_name OAuth client name
#' @export
clear_meetupr_token <- function(client_name = get_client_name()) {
  for (k in valid_keys) {
    meetupr_key_delete(k, client_name)
  }
  cache_path <- get_cache_path(client_name)
  if (dir.exists(cache_path)) {
    unlink(cache_path, recursive = TRUE)
  }
  invisible(NULL)
}

#' Create standardized key names
#'
#' Generates standardized key names for storing in env vars.
#' @param key A character string indicating the name of the key.
#' Valid options are `r paste(valid_keys, collapse = ", ")`.
#' @return A character string representing the standardized key name.
#' @keywords internal
#' @noRd
key_name <- function(key) {
  match.arg(key, valid_keys, several.ok = FALSE)
}

#' Prompt user for input
#' @param key The key for which to prompt input.
#' @return The user input as a character string.
#' @keywords internal
#' @noRd
get_input <- function(key) {
  glue::glue("Enter value for {.val {key}}: ") |>
    read_input()
}

#' Read input from the console
#' @param text The prompt text to display to the user.
#' @return The user input as a character string.
#' @keywords internal
#' @noRd
read_input <- function(text) {
  readline(prompt = text) # nocov
}

#' Check if a Key is Available in Environment Variables
#' @keywords internal
#' @noRd
key_available <- function(
  key,
  client_name = get_client_name()
) {
  key_name_val <- key_name(key)
  env_var_name <- paste0(client_name, "_", key_name_val)
  val <- Sys.getenv(env_var_name, unset = "")
  nzchar(val)
}

#' Retrieve a cached OAuth token for an httr2 client
#'
#' Uses httr2::oauth_token_cached() to load a cached token and returns a
#' list with an `access_token` element, or NULL if none found.
#' @param client An httr2 oauth client object (expects element `name`)
#' @return A list with `access_token` or NULL
#' @keywords internal
#' @noRd
get_cached_token <- function(...) {
  client <- meetupr_client(...)

  tryCatch(
    httr2::oauth_token_cached(
      client = client,
      flow = httr2::oauth_flow_auth_code,
      flow_params = meetupr_oauth_flow_params()
    ),
    error = function(e) NULL
  )
}
