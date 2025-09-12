#' S7 class for representing GraphQL query configurations
#' @keywords internal
#' @noRd
# nolint start: object_name_linter
MeetupQuery <- S7::new_class(
  # nolint end: object_name_linter
  "MeetupQuery",
  properties = list(
    template = S7::class_character,
    cursor_fn = S7::class_function,
    total_fn = S7::class_function,
    extract_fn = S7::class_function,
    finalizer_fn = S7::class_function
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
  .extra_graphql = NULL,
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
    .extra_graphql = .extra_graphql
  )

  total <- object@total_fn(response)

  if (show_progress) {
    cli::cli_progress_bar(
      format = "Fetching data {cli::pb_spin} 
      Page {page_count}, {length(all_data)} items",
      format_done = "Fetched {length(all_data)}
       items in {page_count} page{?s}",
      total = total
    )
  }

  repeat {
    page_count <- page_count + 1
    current_data <- object@extract_fn(response)

    if (length(current_data) == 0) {
      break
    }

    all_data <- c(all_data, current_data)

    if (show_progress) {
      cli::cli_progress_update()
    }

    cursor_info <- object@cursor_fn(response)
    if (is.null(cursor_info)) {
      break
    }

    response <- execute_from_template(
      object@template,
      ...,
      cursor = cursor_info$cursor,
      .extra_graphql = .extra_graphql
    )
  }

  if (show_progress) {
    cli::cli_progress_done()
  }

  object@finalizer_fn(all_data)
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
  path_to_edges,
  max_results = NULL
) {
  results_fetched <- 0

  page_info_parts <- parse_path_to_pluck(path_to_page_info)
  edges_parts <- parse_path_to_pluck(path_to_edges)

  list(
    cursor_fn = function(x) {
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

#' Standard Total Count Function
#' @keywords internal
#' @noRd
build_total_counter <- function(path_to_total, max_results = NULL) {
  total_parts <- parse_path_to_pluck(path_to_total)

  function(x) {
    total <- purrr::pluck(x, !!!total_parts) %||% 0
    if (is.null(max_results)) total else min(total, max_results)
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
  data_processor_fn,
  max_results = NULL,
  transform_fn = NULL
) {
  pagination <- build_standard_pagination(
    page_info_path,
    edges_path,
    max_results
  )

  MeetupQuery(
    template = template,
    cursor_fn = pagination$cursor_fn,
    total_fn = build_total_counter(total_path, max_results),
    extract_fn = build_edge_extractor(edges_path, transform_fn = transform_fn),
    finalizer_fn = data_processor_fn
  )
}

#' Specialized query builders for common patterns
#' @keywords internal
#' @noRd
create_event_query <- function(template, max_results = NULL) {
  create_meetup_query(
    template = template,
    page_info_path = "data.groupByUrlname.events.pageInfo",
    edges_path = "data.groupByUrlname.events.edges",
    total_path = "data.groupByUrlname.events.totalCount",
    data_processor_fn = process_event_data,
    max_results = max_results,
    transform_fn = function(nodes) {
      add_country_name(nodes, get_country = function(event) {
        if (length(event$venues) > 0) {
          event$venues[[1]]$country
        } else {
          NULL
        }
      })
    }
  )
}

create_rsvp_query <- function(template) {
  create_meetup_query(
    template = template,
    page_info_path = "data.event.rsvps.pageInfo",
    edges_path = "data.event.rsvps.edges",
    total_path = "data.event.rsvps.count",
    data_processor_fn = process_rsvps_data
  )
}

create_members_query <- function(max_results = NULL) {
  pagination <- build_standard_pagination(
    "data.groupByUrlname.memberships.pageInfo",
    "data.groupByUrlname.memberships.edges",
    max_results
  )

  MeetupQuery(
    template = "get_members",
    cursor_fn = function(x) {
      cursor_info <- pagination$cursor_fn(x)
      if (!is.null(cursor_info)) {
        list(after = cursor_info$cursor)
      } else {
        NULL
      }
    },
    total_fn = build_total_counter(
      "data.groupByUrlname.memberships.totalCount",
      max_results
    ),
    extract_fn = build_edge_extractor(
      "data.groupByUrlname.memberships.edges",
      node_only = FALSE
    ),
    finalizer_fn = process_members_data
  )
}

create_groups_search_query <- function(max_results) {
  create_meetup_query(
    template = "find_groups",
    page_info_path = "data.groupSearch.pageInfo",
    edges_path = "data.groupSearch.edges",
    total_path = "data.groupSearch.count",
    data_processor_fn = process_groups_data,
    max_results = max_results,
    transform_fn = function(nodes) {
      add_country_name(nodes, get_country = function(group) group$country)
    }
  )
}

create_pro_query <- function(
  template,
  network_type,
  data_processor_fn,
  max_results = NULL
) {
  create_meetup_query(
    template = template,
    page_info_path = glue::glue("data.proNetwork.{network_type}.pageInfo"),
    edges_path = glue::glue("data.proNetwork.{network_type}.edges"),
    total_path = glue::glue(
      "data.proNetwork.{network_type}.{
      if (network_type == 'eventsSearch') 
      'totalCount' else 'count'}"
    ),
    data_processor_fn = data_processor_fn,
    max_results = max_results
  )
}
