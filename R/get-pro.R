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
  ellipsis::check_dots_empty()
  execute(
    create_pro_query(
      "get_pro_groups",
      "groupsSearch",
      process_pro_group_data
    ),
    urlname = urlname,
    extra_graphql = extra_graphql
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
  ellipsis::check_dots_empty()
  execute(
    create_pro_query(
      "get_pro_events",
      "eventsSearch",
      process_pro_event_data
    ),
    urlname = urlname,
    status = validate_event_status(status),
    max_results = max_results,
    handle_multiples = handle_multiples,
    extra_graphql = extra_graphql
  )
}

#' Process pro group data dynamically
#' @param dlist List of pro group data from GraphQL
#' @return tibble with pro group information
#' @keywords internal
#' @noRd
process_pro_group_data <- function(dlist, handle_multiples) {
  result <- process_graphql_list(
    dlist,
    handle_multiples
  )

  # Post-process datetime fields
  if ("founded_date" %in% names(result)) {
    result <- process_datetime_fields(result, "founded_date")
  }

  result
}


#' Process pro event data dynamically
#' @param dlist List of pro event data from GraphQL
#' @return tibble with pro event information
#' @keywords internal
#' @noRd
process_pro_event_data <- function(dlist, handle_multiples) {
  if (length(dlist) == 0) {
    return(dplyr::tibble())
  }

  dlist <- add_country_name(
    dlist,
    function(x) x$group$country
  )

  process_graphql_list(
    dlist,
    handle_multiples
  ) |>
    process_datetime_fields(c(
      "created_time",
      "date_time"
    ))
}

create_pro_query <- function(
  template,
  network_type,
  process_data
) {
  create_meetup_query(
    template = template,
    page_info_path = glue::glue("data.proNetwork.{network_type}.pageInfo"),
    edges_path = glue::glue("data.proNetwork.{network_type}.edges"),
    process_data = process_data
  )
}
