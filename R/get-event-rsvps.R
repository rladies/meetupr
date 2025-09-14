#' Get the RSVPs for a specified event
#'
#' @param id Required event ID
#' @param ... Should be empty. Used for parameter expansion
#' @template max_results
#' @template handle_multiples
#' @template extra_graphql
#' @return A tibble with the RSVPs for the specified event
#'
#' @examples
#' \dontshow{
#' vcr::insert_example_cassette("get_event_rsvps", package = "meetupr")
#' meetupr:::mock_if_no_auth()
#' }
#' rsvps <- get_event_rsvps(id = "103349942")
#' \dontshow{
#' vcr::eject_cassette()
#' }
#' @export
get_event_rsvps <- function(
  id,
  max_results = NULL,
  handle_multiples = "list",
  extra_graphql = NULL,
  ...
) {
  ellipsis::check_dots_empty()
  execute(
    create_meetup_query(
      template = "get_event_rsvps",
      page_info_path = "data.event.rsvps.pageInfo",
      edges_path = "data.event.rsvps.edges",
      process_data = process_rsvps_data
    ),
    id = id,
    max_results = max_results,
    handle_multiples = handle_multiples,
    extra_graphql = extra_graphql
  )
}

#' Process RSVP data dynamically
#' @param dlist List of RSVP data from GraphQL
#' @return tibble with RSVP information
#' @keywords internal
#' @noRd
process_rsvps_data <- function(dlist, handle_multiples = "list") {
  result <- process_graphql_list(
    dlist,
    handle_multiples = handle_multiples
  )

  # Ensure consistent column names for RSVPs
  if ("status" %in% names(result)) {
    names(result)[names(result) == "status"] <- "response"
  }

  result
}
