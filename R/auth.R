#' Get Meetup OAuth Client Name
#'
#' Retrieves the Meetup OAuth client name from the
#' `MEETUPR_CLIENT_NAME` environment variable or defaults to "meetupr".
#' @return A string representing the client name.
#' @export
get_client_name <- function() {
  Sys.getenv("MEETUPR_CLIENT_NAME", "meetupr")
}

#' Create a Meetup OAuth client
#'
#' This function creates an httr2 OAuth client for the Meetup API.
#' It uses environment variables or built-in credentials as fallback.
#'
#' @template client_name
#' @param client_key Optional. The OAuth client ID.
#' @param client_secret Optional. The OAuth client secret.
#' @param ... Additional arguments passed to `httr2::oauth_client()`.
#' @return An httr2 OAuth client object.
#' @export
meetupr_client <- function(
  client_key = NULL,
  client_secret = NULL,
  client_name = get_client_name(),
  ...
) {
  if (is.null(client_key)) {
    client_key <- meetupr_key_get(
      "client_key",
      client_name = client_name,
      error = FALSE
    )
    if (is_empty(client_key)) {
      client_key <- builtin_client$id
    }
  }

  if (is.null(client_secret)) {
    client_secret <- meetupr_key_get(
      "client_secret",
      client_name = client_name,
      error = FALSE
    )
    if (is_empty(client_secret)) {
      client_secret <- builtin_client$secret
    }
  }

  httr2::oauth_client(
    id = client_key,
    token_url = meetupr_api_urls()$token,
    secret = client_secret,
    name = client_name,
    ...
  )
}


#' Authenticate and return the current user
#'
#' Attempts to retrieve information about the currently authenticated
#' user. On success a message is emitted and the user object is
#' returned. On failure a message is shown and `NULL` is returned.
#'
#' @param client_name OAuth client name
#' @return A user list (invisibly) or `NULL` on failure
#' @export
meetupr_auth <- function(client_name = get_client_name()) {
  res <- tryCatch(
    {
      user <- get_self()
      cli::cli_alert_success("Authenticated as {.strong {user$name}}")
      user
    },
    error = function(e) {
      cli::cli_alert_danger("Authentication failed")
      NULL
    }
  )
  res
}

#' Deauthorize and remove cached authentication
#'
#' Remove cached OAuth tokens and optionally clear stored credentials.
#'
#' @param client_name OAuth client name
#' @export
meetupr_deauth <- function(
  client_name = get_client_name()
) {
  cache_root <- httr2::oauth_cache_path()
  cache_dir <- get_cache_path(client_name)

  if (!dir.exists(cache_dir)) {
    cli::cli_alert_info("No authentication cache to remove")

    return(invisible(NULL))
  }

  keys <- c(
    "client_key",
    "client_secret",
    "encrypt_pwd",
    "jwt_token"
  )

  keys_removed <- sapply(keys, function(x) {
    if (key_available(x, client_name = client_name)) {
      meetupr_key_delete(
        x,
        client_name = client_name
      )
      x
    }
  })

  unlink(cache_dir, recursive = TRUE, force = FALSE)

  # Emit message depending on whether credential removals happened
  if (length(keys_removed) > 0) {
    cli::cli_alert_success(
      "Authentication cache removed for client:
      {.val {client_name}} and stored
      credentials were deleted"
    )
  } else {
    cli::cli_alert_success("Authentication cache removed")
  }

  invisible(NULL)
}
