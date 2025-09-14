#' Get the attendees for a specified event
#'
#' @param id Required event ID
#' @param ... Should be empty. Used for parameter expansion
#' @template max_results
#' @template handle_multiples
#' @template extra_graphql
#' @return A tibble with the attendees for the specified event
#' @references
#' \url{https://www.meetup.com/api/schema/#Event}
#' \url{https://www.meetup.com/api/schema/#RSVP}
#' \url{https://www.meetup.com/api/schema/#Member}
#' @examples
#' \dontshow{
#' vcr::insert_example_cassette("get_event_attendees", package = "meetupr")
#' meetupr:::mock_if_no_auth()
#' }
#' attendees <- get_event_attendees(id = "103349942")
#' \dontshow{
#' vcr::eject_cassette()
#' }
#' @export
get_event_attendees <- function(
  id,
  max_results = NULL,
  handle_multiples = "list",
  extra_graphql = NULL,
  ...
) {
  ellipsis::check_dots_empty()
  execute(
    create_meetup_query(
      template = "get_event_attendees",
      page_info_path = "data.event.rsvps.pageInfo",
      edges_path = "data.event.rsvps.edges",
      total_path = "data.event.rsvps.count",
      process_data = process_attendees_data
    ),
    id = id,
    max_results = max_results,
    handle_multiples = handle_multiples,
    extra_graphql = extra_graphql
  )
}

#' Process attendees data dynamically
#' @param dlist List of attendee data from GraphQL
#' @return tibble with attendee information
#' @keywords internal
#' @noRd
process_attendees_data <- function(dlist, handle_multiples = "list") {
  result <- process_graphql_list(
    dlist,
    handle_multiples = handle_multiples
  )

  # Ensure consistent column names for attendees
  if ("status" %in% names(result)) {
    names(result)[names(result) == "status"] <- "response"
  }

  result
}
