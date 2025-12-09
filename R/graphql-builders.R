#' S7 class for representing GraphQL query configurations
#' @keywords internal
#' @noRd
meetupr_template <- S7::new_class(
  "meetupr_template",
  properties = list(
    template = S7::class_character,
    page_info_path = S7::class_character,
    edges_path = S7::class_character,
    process_data = S7::class_function
  )
)

#' Constructor for meetupr_template
#' @keywords internal
#' @noRd
meetupr_template_query <- function(
  template,
  page_info_path,
  edges_path,
  process_data = process_graphql_list
) {
  meetupr_template(
    template = template,
    page_info_path = page_info_path,
    edges_path = edges_path,
    process_data = process_data
  )
}

#' Extract data at a specified dot-separated path
#' @keywords internal
#' @noRd
extract_at_path <- function(response, edges_path) {
  if (is_empty(edges_path)) {
    return(list())
  }

  parts <- strsplit(edges_path, "\\.")[[1]]
  node <- response
  for (p in parts) {
    if (is.null(node)) {
      break
    }
    node <- node[[p]]
  }
  if (!is_empty(node)) {
    return(node)
  }
  list()
}

#' Get pagination cursor from response
#' @keywords internal
#' @noRd
get_cursor <- function(response, page_info_path) {
  if (is.null(page_info_path) || page_info_path == "") {
    return(NULL)
  }

  parts <- strsplit(page_info_path, "\\.")[[1]]
  info <- response
  for (p in parts) {
    if (is.null(info)) {
      break
    }
    info <- info[[p]]
  }

  if (!is.null(info) && isTRUE(info$hasNextPage)) {
    list(cursor = info$endCursor)
  } else {
    NULL
  }
}

#' Execute a meetupr_template
#' @keywords internal
#' @noRd
execute <- S7::new_generic("execute", "object")

S7::method(execute, meetupr_template) <- function(
  object,
  max_results = NULL,
  handle_multiples = "list",
  extra_graphql = NULL,
  asis = FALSE,
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
    current_data <- extract_at_path(
      response,
      object@edges_path
    )
    if (length(current_data) == 0) {
      break
    }

    all_data <- c(all_data, current_data)

    # Check if we've hit max_results
    if (!is.null(max_results) && length(all_data) >= max_results) {
      break
    }

    cursor_info <- get_cursor(response, object@page_info_path)
    if (is.null(cursor_info)) {
      break
    }

    # Prevent infinite loops
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
  if (asis) {
    return(all_data)
  }
  object@process_data(all_data, handle_multiples)
}

#' Parse dot-separated path to pluck arguments
#' @keywords internal
#' @noRd
parse_path_to_pluck <- function(path) {
  strsplit(path, "\\.")[[1]]
}

#' Create a standard meetupr_template query
#' @keywords internal
#' @noRd
standard_query <- function(template, base_path) {
  meetupr_template_query(
    template = template_path(template),
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
