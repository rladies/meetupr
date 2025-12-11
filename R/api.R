#' Meetup API URLs
#'
#' @keywords internal
#' @noRd
meetupr_api_urls <- function() {
  list(
    api = Sys.getenv(
      "MEETUP_API_URL",
      "https://api.meetup.com/gql-ext"
    ),
    auth = "https://secure.meetup.com/oauth2/authorize",
    token = "https://secure.meetup.com/oauth2/access",
    redirect = Sys.getenv(
      "MEETUP_CLIENT_REDIRECT_URL",
      "http://localhost:1410"
    )
  )
}

#' Create and Configure a Meetup API Request
#'
#' This function prepares and configures an HTTP request for
#' interacting with the Meetup API. It handles both interactive and
#' non-interactive OAuth flows. In interactive mode, it uses OAuth
#' authorization code flow. In non-interactive mode (CI/CD), it loads
#' cached tokens.
#'
#' @param rate_limit A numeric value specifying the maximum number of
#'   requests per second. Defaults to `500 / 60` (500 requests per
#'   60 seconds).
#' @param cache A logical value indicating whether to cache the OAuth
#'   token on disk. Defaults to `TRUE`.
#' @param ... Additional arguments passed to [meetupr_client()] for
#'   setting up the OAuth client.
#'
#' @return A `httr2` request object pre-configured to interact with
#'   the Meetup API.
#'
#' @examples
#' \dontrun{
#' req <- meetupr_req(cache = TRUE)
#'
#' req <- meetupr_req(
#'   cache = FALSE,
#'   client_key = "your_client_key",
#'   client_secret = "your_client_secret"
#' )
#' }
#'
#' @details
#' This function constructs an HTTP POST request directed to the
#' Meetup API and applies appropriate OAuth authentication. The
#' function automatically detects whether it's running in an
#' interactive or non-interactive context:
#'
#' - **Interactive**: Uses OAuth authorization code flow with browser
#'   redirect
#' - **Non-interactive**: Loads pre-cached token from CI environment
#'   or disk
#'
#' @export
meetupr_req <- function(rate_limit = 500 / 60, cache = TRUE, ...) {
  meetupr_api_urls()$api |>
    httr2::request() |>
    httr2::req_headers(
      "Content-Type" = "application/json"
    ) |>
    httr2::req_throttle(rate = rate_limit) |>
    req_auth(cache = cache, ...)
}

#' Apply OAuth Authentication to Request
#'
#' Adds authentication to httr2 request. Handles JWT tokens,
#' OAuth encrypted tokens, and interactive OAuth flows.
#'
#' @param req httr2 request object
#' @param cache Cache OAuth token on disk (interactive only).
#'   Default TRUE.
#' @param ... Arguments to [meetupr_client()]
#'
#' @return Authenticated httr2 request object
#'
#' @details
#' Non-interactive mode tries: JWT token → encrypted token file.
#'  Interactive mode uses OAuth
#' browser flow.
#'
#' @keywords internal
#' @noRd
req_auth <- function(
  req,
  client_name = get_client_name(),
  cache = TRUE,
  ...
) {
  auth <- meetupr_auth_status(silent = TRUE)

  if (auth$jwt$available) {
    if (check_debug_mode()) {
      cli::cli_alert_info("Using jwt token authentication")
    }

    claim <- httr2::jwt_claim(
      iss = auth$jwt$client_key,
      sub = auth$jwt$issuer,
      aud = "api.meetup.com"
    )

    claim <- httr2::jwt_claim(
      iss = auth$jwt$client_key,
      sub = auth$jwt$issuer,
      aud = "api.meetup.com"
    )

    req <- req |>
      httr2::req_oauth_bearer_jwt(
        claim = claim,
        client = meetupr_client(
          key = auth$jwt$value,
          auth = "jwt_sig",
          auth_params = list(
            claim = claim
          )
        )
      )

    return(req)
  }

  token <- tryCatch(
    meetupr_encrypt_load(client_name = client_name),
    error = function(e) NULL
  )

  if (!is_empty(token)) {
    if (check_debug_mode()) {
      cli::cli_alert_info("Using encrypted token authentication")
    }
    return(
      httr2::req_auth_bearer_token(req, token)
    )
  }

  if (check_debug_mode()) {
    cli::cli_alert_info("Falling back to OAuth browser flow")
  }

  flow_params <- meetupr_oauth_flow_params()

  req |>
    httr2::req_oauth_auth_code(
      client = meetupr_client(...),
      auth_url = flow_params$auth_url,
      redirect_uri = flow_params$redirect_uri,
      cache_disk = cache
    )
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
#' meetupr_query(graphql = query, id = "12345")
#' }
#' @export
meetupr_query <- function(
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
    httr2::req_error(body = handle_api_error) |>
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

  # Construct body once
  body_list <- list(
    query = graphql,
    variables = variables
  )

  meetupr_req() |>
    httr2::req_body_json(body_list, auto_unbox = TRUE)
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

#' Get OAuth Flow Parameters
#'
#' @keywords internal
#' @noRd
meetupr_oauth_flow_params <- function() {
  urls <- meetupr_api_urls()
  list(
    auth_url = urls$auth,
    redirect_uri = urls$redirect
  )
}
