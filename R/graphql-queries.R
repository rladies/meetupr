#' Execute GraphQL query from file
#'
#' This function reads a GraphQL query from a specified file,
#' optionally inserts additional GraphQL fragments or queries,
#' and executes the query with provided variables.
#'
#' @param .file Name of the file containing the GraphQL
#' query (without extension)
#' @param ... Variables to pass to query
#' @param extra_graphql Additional GraphQL fragments or queries to include
#' @param .envir Environment for error handling
#' @noRd
#' @keywords internal
execute_from_template <- function(
  .file,
  ...,
  extra_graphql = NULL,
  .envir = parent.frame()
) {
  file_path <- get_execute_from_template_path(.file)
  query <- read_execute_from_template(file_path)

  extra_graphql <- validate_extra_graphql(
    extra_graphql
  )

  glued_query <- insert_extra_graphql(
    query,
    extra_graphql
  )
  meetup_query(
    .query = glued_query,
    ...,
    .envir = .envir
  )
}

#' Execute GraphQL query
#' This function executes a GraphQL query with the provided variables.
#' It validates the variables, constructs the request,
#' and handles any errors returned by the GraphQL API.
#' @param .query GraphQL query string
#' @param ... Variables to pass to query
#' @param .envir Environment for error handling
#' @export
meetup_query <- function(
  .query,
  ...,
  .envir = parent.frame()
) {
  variables <- purrr::compact(rlang::list2(...))

  validate_graphql_variables(variables)

  req <- build_template_request(
    .query,
    variables
  )
  result <- httr2::req_perform(req)
  resp <- httr2::resp_body_json(result)

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
build_template_request <- function(
  query,
  variables = list()
) {
  # Ensure variables is always a proper object, not an array
  if (length(variables) == 0 || is.null(variables)) {
    variables <- structure(list(), names = character(0))
  }

  # Debug the request body if enabled
  if (nzchar(Sys.getenv("MEETUPR_DEBUG"))) {
    body <- list(
      query = query,
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
        query = query,
        variables = variables
      ),
      auto_unbox = TRUE
    )
}
