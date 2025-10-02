#' Retrieve information about Meetup Pro networks,
#' including groups and events.
#'
#' Meetup Pro is a premium service for organizations
#' managing multiple Meetup groups.
#' This functionality allows you to access details about
#' the groups within a Pro network
#' and the events they host.
#'
#' @template urlname
#' @template max_results
#' @template handle_multiples
#' @template date_before
#' @template date_after
#' @param ... Should be empty. Used for parameter expansion
#' @template extra_graphql
#' @param status Which status the events should have.
#' @return tibble with pro network information
#'
#' @examples
#' \dontshow{
#' vcr::insert_example_cassette("get_pro", package = "meetupr")
#' meetupr:::mock_if_no_auth()
#' }
#' urlname <- "rladies"
#' members <- get_pro_groups(urlname)
#'
#' upcoming_events <- get_pro_events(urlname, "upcoming", max_results = 5)
#' \dontshow{
#' vcr::eject_cassette()
#' }
#' @name get_pro
#' @return A tibble with meetup pro information
NULL

#' @export
#' @describeIn get_pro retrieve groups in a pro network
get_pro_groups <- function(
  urlname,
  max_results = NULL,
  handle_multiples = "list",
  extra_graphql = NULL,
  ...
) {
  rlang::check_dots_empty()
  execute(
    standard_query(
      "get_pro_groups",
      "data.proNetwork.groupsSearch"
    ),
    urlname = urlname,
    first = max_results,
    max_results = max_results,
    handle_multiples = handle_multiples,
    extra_graphql = extra_graphql
  ) |>
    process_datetime_fields(c("founded_date", "pro_join_date")) |>
    dplyr::mutate(
      country = get_country_code(country)
    )
}

#' @export
#' @describeIn get_pro retrieve events from a pro network
get_pro_events <- function(
  urlname,
  status = NULL,
  date_before = date_before,
  date_after = date_after,
  max_results = NULL,
  handle_multiples = "list",
  extra_graphql = NULL,
  ...
) {
  rlang::check_dots_empty()

  if (!is_self_pro()) {
    cli::cli_warn(
      "The authenticated user must have Pro 
      access to retrieve Network event data."
    )
  }

  execute(
    standard_query(
      "get_pro_events",
      "data.proNetwork.eventsSearch"
    ),
    urlname = urlname,
    first = max_results,
    max_results = max_results,
    status = validate_event_status(status, pro = TRUE),
    handle_multiples = handle_multiples,
    extra_graphql = extra_graphql
  ) |>
    process_datetime_fields(c("date_time", "pro_join_date"))
}

#' Check if the authenticated user has Pro access
#' @keywords internal
#' @noRd
is_self_pro <- function() {
  if (!meetup_auth_status(silent = TRUE)) {
    return(FALSE)
  }
  resp <- meetup_query(
    "
  query { self { 
    isProOrganizer 
    } }
  "
  )
  resp$data$self$isProOrganizer
}
