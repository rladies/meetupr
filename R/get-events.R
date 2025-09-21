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
  rlang::check_dots_empty()

  execute(
    standard_query(
      "get_events",
      "data.groupByUrlname.events"
    ),
    urlname = urlname,
    status = validate_event_status(status),
    date_before = date_before,
    date_after = date_after,
    first = max_results,
    max_results = max_results,
    handle_multiples = handle_multiples,
    extra_graphql = extra_graphql
  ) |>
    dplyr::mutate(
      venues_country = get_country_code(venues_country)
    ) |>
    process_datetime_fields(c(
      "created_time",
      "date_time"
    ))
}

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
  rlang::check_dots_empty()

  execute(
    standard_query(
      "get_event_rsvps",
      "data.event.rsvps"
    ),
    id = id,
    first = max_results,
    max_results = max_results,
    handle_multiples = handle_multiples,
    extra_graphql = extra_graphql
  )
}

#' Get the comments for a specified event
#'
#' @param id Required event ID
#' @param ... Should be empty. Used for parameter expansion
#' @template extra_graphql
#' @return A tibble with the following columns:
#'    * id
#'    * comment
#'    * created
#'    * like_count
#'    * member_id
#'    * member_name
#'    * link
#' @references
#' \url{https://www.meetup.com/api/schema/#Event}
#' \url{https://www.meetup.com/api/schema/#EventCommentConnection}
#' @examples
#' \dontrun{
#' comments <- get_event_comments(id = "103349942")
#' }
#' @export
get_event_comments <- function(
  id,
  ...,
  extra_graphql = NULL
) {
  rlang::check_dots_empty()

  cli::cli_warn(c(
    "!" = "Event comments functionality has been 
    removed from the current Meetup GraphQL API.",
    "i" = "The 'comments' field is no longer available 
    on the Event type.",
    "i" = "This function returns an empty tibble for
     backwards compatibility.",
    "i" = "Comment mutations may still work, but 
    querying comments is not supported."
  ))

  create_empty_comments_tibble()
}

create_empty_comments_tibble <- function() {
  dplyr::tibble(
    id = character(0),
    comment = character(0),
    created = character(0),
    like_count = integer(0),
    member_id = character(0),
    member_name = character(0),
    link = character(0)
  )
}
