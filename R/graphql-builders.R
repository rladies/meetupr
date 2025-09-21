#' S7 class for representing GraphQL query configurations
#' @keywords internal
#' @noRd
meetup_template <- S7::new_class(
  "meetup_template",
  properties = list(
    template = S7::class_character,
    page_info_path = S7::class_character,
    edges_path = S7::class_character,
    process_data = S7::class_function
  )
)

#' Constructor for meetup_template
#' @keywords internal
#' @noRd
meetup_template_query <- function(
  template,
  page_info_path,
  edges_path,
  process_data = process_graphql_list
) {
  meetup_template(
    template = template,
    page_info_path = page_info_path,
    edges_path = edges_path,
    process_data = process_data
  )
}

#' Execute a meetup_template
#' @keywords internal
#' @noRd
execute <- S7::new_generic("execute", "object")

S7::method(execute, meetup_template) <- function(
  object,
  max_results = NULL,
  handle_multiples = "list",
  extra_graphql = NULL,
  ...,
  .progress = TRUE
) {
  all_data <- list()
  cursor <- NULL
  previous_cursor <- NULL
  page_count <- 0

  repeat {
    page_count <- page_count + 1

    response <- execute_from_template(
      object@template,
      ...,
      cursor = cursor,
      extra_graphql = extra_graphql
    )

    current_data <- extract_at_path(object, response)
    if (length(current_data) == 0) {
      break
    }

    all_data <- c(all_data, current_data)

    # Check if we've hit max_results
    if (!is.null(max_results) && length(all_data) >= max_results) {
      break
    }

    cursor_info <- get_cursor(object, response)
    if (is.null(cursor_info)) {
      break
    }

    # Prevent infinite loops - if cursor hasn't changed, stop
    new_cursor <- cursor_info$cursor
    if (!is.null(previous_cursor) && new_cursor == previous_cursor) {
      break
    }

    previous_cursor <- cursor
    cursor <- new_cursor
  }

  # Trim to max_results if specified
  if (!is.null(max_results) && length(all_data) > max_results) {
    all_data <- all_data[1:max_results]
  }

  object@process_data(all_data, handle_multiples)
}

#' Parse dot-separated path to pluck arguments
#' @keywords internal
#' @noRd
parse_path_to_pluck <- function(path) {
  strsplit(path, "\\.")[[1]]
}

# Generic path extraction
extract_at_path <- S7::new_generic("extract_at_path", c("object", "response"))

S7::method(extract_at_path, list(meetup_template, S7::class_any)) <- function(
  object,
  response
) {
  edges_parts <- strsplit(object@edges_path, "\\.")[[1]]
  edges <- purrr::pluck(response, !!!edges_parts)
  if (!is.null(edges) && length(edges) > 0) {
    if (!any(sapply(edges, function(x) "node" %in% names(x)))) {
      return(edges)
    }
    return(
      lapply(edges, `[[`, "node")
    )
  }
  list()
}

# Pagination using stored path
get_cursor <- S7::new_generic("get_cursor", c("object", "response"))

S7::method(get_cursor, list(meetup_template, S7::class_any)) <- function(
  object,
  response
) {
  page_info_parts <- strsplit(object@page_info_path, "\\.")[[1]]
  if (length(page_info_parts) == 0) {
    return(NULL)
  }
  page_info <- purrr::pluck(response, !!!page_info_parts)

  if (!is.null(page_info) && page_info$hasNextPage) {
    return(
      list(cursor = page_info$endCursor)
    )
  }
  NULL
}

# For common patterns
standard_query <- function(template, base_path) {
  meetup_template_query(
    template = template,
    page_info_path = paste0(
      base_path,
      ".pageInfo"
    ),
    edges_path = paste0(
      base_path,
      ".edges"
    )
  )
}
