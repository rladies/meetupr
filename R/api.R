#' Meetup API Prefix
#'
#' @keywords internal
#' @noRd
meetup_api_prefix <- function() {
  Sys.getenv(
    "MEETUP_API_URL",
    "https://api.meetup.com/gql-ext"
  )
}

#' Create and Configure a Meetup API Request
#'
#' This function prepares and configures an HTTP request for interacting with
#' the Meetup API. It allows the user to authenticate via OAuth, specify the
#' use of caching, and set custom client configuration.
#'
#' @param cache A logical value indicating whether to cache the OAuth token
#'   on disk. Defaults to `TRUE`.
#' @param ... Additional arguments passed to `meetup_client()` for setting up
#'   the OAuth client.
#'
#' @return A `httr2` request object pre-configured to interact with the
#'   Meetup API. Note that the current implementation is commented out and
#'   serves as a placeholder for the full logic.
#'
#' @examples
#' \dontrun{
#' # Example 1: Basic request with caching enabled
#' req <- meetup_req(cache = TRUE)
#'
#' # Example 2: Request with custom client ID and secret
#' req <- meetup_req(
#'   cache = FALSE,
#'   client_id = "your_client_id",
#'   client_secret = "your_client_secret"
#' )
#' }
#'
#' @details
#' This function constructs an HTTP POST request directed to the Meetup API
#' and applies appropriate OAuth headers for authentication. The function
#' is prepared to support caching and provides flexibility for client
#' customization with the `...` parameter. The implementation is currently
#' commented out and would require activation for functionality.
#'
#' @export
meetup_req <- function(cache = TRUE, ...) {
  req <- httr2::request(meetup_api_prefix()) |>
    httr2::req_headers("Content-Type" = "application/json") |>
    httr2::req_error(body = function(resp) {
      error_data <- httr2::resp_body_json(resp)
      if (!is.null(error_data$errors)) {
        messages <- sapply(error_data$errors, function(err) err$message)
        paste("Meetup API errors:", paste(messages, collapse = "; "))
      } else {
        "Unknown Meetup API error"
      }
    })

  use_jwt <- switch(
    Sys.getenv("MEETUP_AUTH_METHOD"),
    "jwt" = TRUE,
    "oauth" = FALSE,
    has_jwt_credentials()
  )

  if (use_jwt && has_jwt_credentials()) {
    claim <- httr2::jwt_claim(
      sub = Sys.getenv("MEETUP_MEMBER_ID"),
      iss = Sys.getenv("MEETUP_CLIENT_ID"),
      aud = "api.meetup.com"
    )
    req <- req |>
      httr2::req_oauth_bearer_jwt(
        claim = claim,
        client = meetup_client(
          key = get_rsa_key(),
          auth = "jwt_sig",
          auth_params = list(claim = claim)
        )
      )
    return(req)
  } else if (has_oauth_credentials()) {
    req <- req |>
      httr2::req_oauth_auth_code(
        client = meetup_client(...),
        auth_url = "https://secure.meetup.com/oauth2/authorize",
        redirect_uri = "http://localhost:1410",
        cache_disk = cache
      )
    return(req)
  }
  cli::cli_abort(c(
    "x" = "Authentication required. Set either:",
    "i" = "JWT: {.val MEETUP_CLIENT_ID}, 
    {.val MEETUP_MEMBER_ID}, {.val MEETUP_RSA_PATH}",
    "i" = "OAuth: {.val MEETUP_CLIENT_ID}, 
    {.val MEETUP_CLIENT_SECRET}",
    "i" = "Control method with 
    {.envvar MEETUP_AUTH_METHOD=jwt} or 
    {.envvar MEETUP_AUTH_METHOD=oauth}"
  ))
}
