#' Get the events from a meetup group
#'
#' @template urlname
#' @param status Character vector of event statuses to retrieve.
#' @template max_results
#' @template handle_multiples
#' @template date_before
#' @template date_after
#' @param ... Should be empty. Used for parameter expansion
#' @template extra_graphql
#' @return A tibble with the events for the specified group
#' @examples
#' \dontshow{
#' vcr::insert_example_cassette("get_events", package = "meetupr")
#' meetupr:::mock_if_no_auth()
#' }
#' get_events("rladies-lagos", "past")
#' get_events(
#'    "rladies-lagos",
#'    status = "past",
#'    date_before = "2023-01-01T12:00:00Z"
#' )
#' \dontshow{
#' vcr::eject_cassette()
#' }
#' @export
get_events <- function(
  urlname,
  status = NULL,
  date_before = NULL,
  date_after = NULL,
  max_results = NULL,
  handle_multiples = "list",
  extra_graphql = NULL,
  ...
) {
  ellipsis::check_dots_empty()
  execute(
    create_meetup_query(
      template = "get_events",
      page_info_path = "data.groupByUrlname.events.pageInfo",
      edges_path = "data.groupByUrlname.events.edges",
      process_data = process_event_data,
      transform_fn = function(nodes) {
        add_country_name(nodes, get_country = function(event) {
          if (length(event$venues) > 0) {
            event$venues[[1]]$country
          } else {
            NULL
          }
        })
      }
    ),
    urlname = urlname,
    status = validate_event_status(status),
    date_before = date_before,
    date_after = date_after,
    max_results = max_results,
    handle_multiples = handle_multiples,
    extra_graphql = extra_graphql
  )
}

#' Process event data dynamically
#' @param dlist List of event data from GraphQL
#' @return tibble with event information
#' @keywords internal
#' @noRd
process_event_data <- function(dlist, handle_multiples = "list") {
  result <- process_graphql_list(
    dlist,
    handle_multiples = handle_multiples
  )

  if ("date_time" %in% names(result)) {
    result <- process_datetime_fields(result, "date_time")
  }
  if ("created_time" %in% names(result)) {
    result <- process_datetime_fields(result, "created_time")
  }

  result
}
