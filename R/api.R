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
#' @param rate_limit A numeric value specifying the maximum number of requests
#' @param cache A logical value indicating whether to cache the OAuth token
#'   on disk. Defaults to `TRUE`.
#' @param ... Additional arguments passed to [meetup_client()] for setting up
#'   the OAuth client.
#'
#' @return A `httr2` request object pre-configured to
#' interact with the Meetup API.
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
meetup_req <- function(rate_limit = 500 / 60, cache = TRUE, ...) {
  meetup_api_prefix() |>
    httr2::request() |>
    httr2::req_headers(
      "Content-Type" = "application/json"
    ) |>
    httr2::req_error(body = handle_api_error) |>
    httr2::req_oauth_auth_code(
      client = meetup_client(...),
      auth_url = "https://secure.meetup.com/oauth2/authorize",
      redirect_uri = "http://localhost:1410",
      cache_disk = cache
    ) |>
    httr2::req_throttle(rate = rate_limit)
}

#' Execute GraphQL query
#'
#' This function executes a GraphQL query with the provided variables.
#' It validates the variables, constructs the request,
#' and handles any errors returned by the GraphQL API.
#' @param graphql GraphQL query string
#' @param ... Variables to pass to query
#' @param .envir Environment for error handling
#' @return The response from the GraphQL API as a list.
#' @examples
#' \dontrun{
#' query <- "
#' query GetUser($id: ID!) {
#'  user(id: $id) {
#'   id
#'  name
#' }
#' }"
#' meetup_query(graphql = query, id = "12345")
#' }
#' @export
meetup_query <- function(
  graphql,
  ...,
  .envir = parent.frame()
) {
  variables <- rlang::list2(...) |>
    purrr::compact()
  validate_graphql_variables(variables)

  req <- build_request(
    graphql,
    variables
  )

  resp <- req |>
    httr2::req_perform() |>
    httr2::resp_body_json()

  if (!is.null(resp$errors)) {
    cli::cli_abort(
      c(
        "Failed to execute GraphQL query.",
        sapply(resp$errors, function(e) {
          gsub("\\{", "{{", gsub("\\}", "}}", e$message))
        })
      ),
      .envir = .envir
    )
  }

  resp
}

#' Build a GraphQL Request
#' This function constructs an HTTP request for a GraphQL query,
#' including the query and variables in the request body.
#' @param query A character string containing the GraphQL query.
#' @param variables A named list of variables to include with the query.
#' @return A `httr2` request object ready to be sent.
#' @noRd
#' @keywords internal
build_request <- function(
  graphql,
  variables = list()
) {
  # Ensure variables is always a proper object, not an array
  if (length(variables) == 0 || is.null(variables)) {
    variables <- structure(
      list(),
      names = character(0)
    )
  }

  # Debug the request body if enabled
  if (check_debug_mode()) {
    body <- list(
      query = graphql,
      variables = variables
    ) |>
      jsonlite::toJSON(
        auto_unbox = TRUE,
        pretty = TRUE
      ) |>
      strsplit("\n|\\\\n") |>
      unlist()
    cli::cli_alert_info("DEBUG: JSON to be sent:")
    cli::cli_code(
      body
    )
  }

  meetup_req() |>
    httr2::req_body_json(
      list(
        query = graphql,
        variables = variables
      ),
      auto_unbox = TRUE
    )
}

#' Handle API Error
#'
#' This function processes the error response from the API
#' and extracts meaningful error messages.
#'
#' @param resp The response object from the API request.
#' @return A character string containing the error message.
#' @keywords internal
#' @noRd
handle_api_error <- function(resp) {
  error_data <- httr2::resp_body_json(resp)
  if (!is.null(error_data$errors)) {
    messages <- sapply(error_data$errors, function(err) err$message)
    paste("Meetup API errors:", paste(messages, collapse = "; "))
  } else {
    "Unknown Meetup API error"
  }
}
