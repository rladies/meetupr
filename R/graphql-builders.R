#' S7 class for representing GraphQL query configurations
#' @keywords internal
#' @noRd
# nolint start: object_name_linter
MeetupQuery <- S7::new_class(
  # nolint end: object_name_linter
  "MeetupQuery",
  properties = list(
    template = S7::class_character,
    pagination = S7::class_function,
    extract = S7::class_function,
    process_data = S7::class_function
  )
)

#' Execute a MeetupQuery
#' @keywords internal
#' @noRd
execute <- S7::new_generic("execute", "object")

# nolint start: object_name_linter
S7::method(execute, MeetupQuery) <- function(
  # nolint end: object_name_linter
  object,
  ...,
  max_results = NULL,
  handle_multiples = "list",
  extra_graphql = NULL,
  .progress = TRUE
) {
  all_data <- list()
  cursor <- NULL
  page_count <- 0

  debug_enabled <- nzchar(Sys.getenv("MEETUPR_DEBUG"))
  show_progress <- .progress && !debug_enabled

  response <- execute_from_template(
    object@template,
    ...,
    cursor = cursor,
    extra_graphql = extra_graphql
  )

  if (show_progress) {
    cli::cli_progress_bar(
      format = "Fetching data {cli::pb_spin} 
      Page {page_count}, {length(all_data)} items",
      format_done = "Fetched {length(all_data)}
       items in {page_count} page{?s}",
      total = NA
    )
  }

  repeat {
    page_count <- page_count + 1
    current_data <- object@extract(response)

    if (length(current_data) == 0) {
      break
    }

    all_data <- c(all_data, current_data)

    if (show_progress) {
      cli::cli_progress_update()
    }

    cursor_info <- object@pagination(response, max_results)
    if (is.null(cursor_info)) {
      break
    }

    response <- execute_from_template(
      object@template,
      ...,
      cursor = cursor_info$cursor,
      max_results = max_results,
      extra_graphql = extra_graphql
    )
  }

  if (show_progress) {
    cli::cli_progress_done()
  }

  object@process_data(
    all_data,
    handle_multiples
  )
}

#' Parse dot-separated path to pluck arguments
#' @keywords internal
#' @noRd
parse_path_to_pluck <- function(path) {
  strsplit(path, "\\.")[[1]]
}

#' Abstract GraphQL Pagination Handler
#' @keywords internal
#' @noRd
build_standard_pagination <- function(
  path_to_page_info,
  path_to_edges
) {
  results_fetched <- 0

  page_info_parts <- parse_path_to_pluck(path_to_page_info)
  edges_parts <- parse_path_to_pluck(path_to_edges)

  list(
    pagination = function(x, max_results = NULL) {
      page_info <- purrr::pluck(x, !!!page_info_parts)
      current_page_size <- length(purrr::pluck(x, !!!edges_parts))

      results_fetched <<- results_fetched + current_page_size

      should_continue <- !is.null(page_info) &&
        !is.null(page_info$hasNextPage) &&
        page_info$hasNextPage &&
        (is.null(max_results) || results_fetched < max_results)

      if (should_continue) {
        list(cursor = page_info$endCursor)
      } else {
        NULL
      }
    },
    get_results_fetched = function() results_fetched
  )
}

#' Standard Edge Extractor
#' @keywords internal
#' @noRd
build_edge_extractor <- function(
  path_to_edges,
  node_only = TRUE,
  transform_fn = NULL
) {
  edges_parts <- parse_path_to_pluck(path_to_edges)
  function(x) {
    edges <- purrr::pluck(x, !!!edges_parts)
    if (!is.null(edges) && length(edges) > 0) {
      result <- if (node_only) {
        lapply(edges, `[[`, "node")
      } else {
        edges
      }
      if (!is.null(transform_fn)) {
        transform_fn(result)
      } else {
        result
      }
    } else {
      list()
    }
  }
}

#' Query Factory - creates MeetupQuery objects with standard patterns
#' @keywords internal
#' @noRd
create_meetup_query <- function(
  template,
  page_info_path,
  edges_path,
  total_path,
  process_data,
  transform_fn = NULL
) {
  pagination <- build_standard_pagination(
    page_info_path,
    edges_path
  )

  MeetupQuery(
    template = template,
    pagination = pagination$pagination,
    extract = build_edge_extractor(
      edges_path,
      transform_fn = transform_fn
    ),
    process_data = process_data
  )
}
