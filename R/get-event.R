#' Get information for a specified event
#'
#' @param id Required event ID
#' @param ... Should be empty. Used for parameter expansion
#' @template extra_graphql
#' @return A meetup_event object with information about the specified event
#'
#' @examples
#' \dontshow{
#' vcr::insert_example_cassette("get_event", package = "meetupr")
#' meetupr:::mock_if_no_auth()
#' }
#' event <- get_event(id = "103349942")
#' \dontshow{
#' vcr::eject_cassette()
#' }
#' @export
get_event <- function(
  id,
  extra_graphql = NULL,
  ...
) {
  rlang::check_dots_empty()

  result <- execute(
    meetup_template_query(
      template = template_path("get_event"),
      page_info_path = "data.event.pageInfo",
      edges_path = "data.event",
      process_data = process_event_data
    ),
    id = id,
    extra_graphql = extra_graphql
  )

  result
}

#' Process event data into meetup_event object
#' @keywords internal
#' @noRd
process_event_data <- function(data, ...) {
  if (length(data) == 0 || is.null(data[[1]])) {
    cli::cli_abort("No event data returned")
  }

  # Just add the class to the existing list
  structure(
    data,
    class = c("meetup_event", "list")
  )
}

#' @export
print.meetup_event <- function(x, ...) {
  cli::cli_h2("Meetup Event")

  cli::cli_li("ID: {.val {x$id}}")
  cli::cli_li("Title: {.strong {x$title}}")
  cli::cli_li("Status: {.val {x$status}}")

  if (!is.null(x$dateTime)) {
    cli::cli_li("Date/Time: {x$dateTime}")
  }

  if (!is.null(x$duration)) {
    cli::cli_li("Duration: {x$duration}")
  }

  if (!is.null(x$rsvps$totalCount)) {
    cli::cli_li("RSVPs: {x$rsvps$totalCount}")
  }

  if (!is.null(x$group)) {
    cli::cli_h3("Group:")
    cli::cli_li("{x$group$name} ({.val {x$group$urlname}})")
  }

  if (!is.null(x$venues) && length(x$venues) > 0) {
    venue <- x$venues[[1]]
    cli::cli_h3("Venue:")
    if (!is.null(venue$name)) {
      cli::cli_li("Name: {venue$name}")
    }
    location_parts <- c(venue$city, venue$state, venue$country)
    location <- paste(
      location_parts[!sapply(location_parts, is.null)],
      collapse = ", "
    )
    if (nzchar(location)) {
      cli::cli_li("Location: {location}")
    }
  }

  if (!is.null(x$feeSettings) && isTRUE(x$feeSettings$required)) {
    cli::cli_h3("Fee:")
    cli::cli_li("{x$feeSettings$amount} {x$feeSettings$currency}")
  }

  if (!is.null(x$eventUrl)) {
    cli::cli_text("")
    cli::cli_text("{.url {x$eventUrl}}")
  }

  invisible(x)
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
