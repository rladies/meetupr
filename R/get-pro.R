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
#' @param ... Should be empty. Used for parameter expansion
#' @template extra_graphql
#' @param status Which status the events should have.
#'
#' @references
#' \url{https://www.meetup.com/api/schema/#ProNetwork}
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
  ...,
  extra_graphql = NULL
) {
  ellipsis::check_dots_empty()
  execute(
    pro_groups_query(max_results),
    urlname = urlname,
    .extra_graphql = extra_graphql
  )
}

#' @export
#' @describeIn get_pro retrieve events from a pro network
get_pro_events <- function(
  urlname,
  status = NULL,
  max_results = NULL,
  ...,
  extra_graphql = NULL
) {
  ellipsis::check_dots_empty()
  execute(
    pro_events_query(max_results),
    urlname = urlname,
    status = validate_event_status(status),
    .extra_graphql = extra_graphql
  )
}

process_pro_group_data <- function(dlist) {
  dplyr::tibble(
    id = purrr::map_chr(dlist, "id", .default = NA_character_),
    name = purrr::map_chr(dlist, "name", .default = NA_character_),
    urlname = purrr::map_chr(dlist, "urlname", .default = NA_character_),
    city = purrr::map_chr(dlist, "city", .default = NA_character_),
    state = purrr::map_chr(dlist, "state", .default = NA_character_),
    country = purrr::map_chr(dlist, "country", .default = NA_character_),
    latitude = purrr::map_dbl(dlist, "lat", .default = NA_real_),
    longitude = purrr::map_dbl(dlist, "lon", .default = NA_real_),
    membership_count = purrr::map_int(
      dlist,
      c("memberships", "totalCount"),
      .default = NA_integer_
    ),
    founded_date = purrr::map_chr(
      dlist,
      "foundedDate",
      .default = NA_character_
    ),
    timezone = purrr::map_chr(dlist, "timezone", .default = NA_character_),
    join_mode = purrr::map_chr(dlist, "joinMode", .default = NA_character_),
    who = purrr::map_chr(dlist, "who", .default = NA_character_),
    is_private = purrr::map_lgl(dlist, "isPrivate", .default = NA)
  )
}

process_pro_event_data <- function(dlist) {
  dplyr::tibble(
    id = purrr::map_chr(dlist, "id", .default = NA_character_),
    title = purrr::map_chr(dlist, "title", .default = NA_character_),
    link = purrr::map_chr(dlist, "eventUrl", .default = NA_character_),
    status = purrr::map_chr(dlist, "status", .default = NA_character_),
    date_time = purrr::map_chr(dlist, "dateTime", .default = NA_character_),
    duration = purrr::map_chr(dlist, "duration", .default = NA_character_),
    description = purrr::map_chr(
      dlist,
      "description",
      .default = NA_character_
    ),
    group_id = purrr::map_chr(
      dlist,
      c("group", "id"),
      .default = NA_character_
    ),
    group_name = purrr::map_chr(
      dlist,
      c("group", "name"),
      .default = NA_character_
    ),
    group_urlname = purrr::map_chr(
      dlist,
      c("group", "urlname"),
      .default = NA_character_
    ),
    venues_id = purrr::map_chr(
      dlist,
      ~ purrr::pluck(.x, "venues", 1, "id", .default = NA_character_)
    ),
    venues_name = purrr::map_chr(
      dlist,
      ~ purrr::pluck(.x, "venues", 1, "name", .default = NA_character_)
    ),
    venues_address = purrr::map_chr(
      dlist,
      ~ purrr::pluck(.x, "venues", 1, "address", .default = NA_character_)
    ),
    venues_city = purrr::map_chr(
      dlist,
      ~ purrr::pluck(.x, "venues", 1, "city", .default = NA_character_)
    ),
    venues_state = purrr::map_chr(
      dlist,
      ~ purrr::pluck(.x, "venues", 1, "state", .default = NA_character_)
    ),
    venues_zip = purrr::map_chr(
      dlist,
      ~ purrr::pluck(.x, "venues", 1, "postalCode", .default = NA_character_)
    ),
    venues_country = purrr::map_chr(
      dlist,
      ~ purrr::pluck(.x, "venues", 1, "country", .default = NA_character_)
    ),
    venues_lat = purrr::map_dbl(
      dlist,
      ~ purrr::pluck(.x, "venues", 1, "lat", .default = NA_real_)
    ),
    venues_lon = purrr::map_dbl(
      dlist,
      ~ purrr::pluck(.x, "venues", 1, "lon", .default = NA_real_)
    ),
    attendees = purrr::map_int(
      dlist,
      c("rsvps", "totalCount"),
      .default = NA_integer_
    )
  ) |>
    process_datetime_fields("date_time")
}
