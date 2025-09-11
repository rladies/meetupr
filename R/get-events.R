#' Get the events from a meetup group
#'
#' @template urlname
#' @param status Character vector of event statuses to retrieve.
#' @param ... Should be empty. Used for parameter expansion
#' @template extra_graphql
#' @examples
#' \dontshow{
#' vcr::insert_example_cassette("get_events", package = "meetupr")
#' meetupr:::mock_if_no_auth()
#' }
#' get_events("rladies-lagos", "past")
#' \dontshow{
#' vcr::eject_cassette()
#' }
#' @export
get_events <- function(
  urlname,
  status = NULL,
  ...,
  extra_graphql = NULL
) {
  ellipsis::check_dots_empty()
  status <- validate_event_status(status)

  execute(
    events_query,
    urlname = urlname,
    status = status,
    .extra_graphql = extra_graphql
  )
}


process_event_data <- function(dlist) {
  dplyr::tibble(
    id = purrr::map_chr(dlist, "id", .default = NA_character_),
    title = purrr::map_chr(dlist, "title", .default = NA_character_),
    link = purrr::map_chr(dlist, "eventUrl", .default = NA_character_),
    created = purrr::map_chr(dlist, "createdTime", .default = NA_character_),
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
    venues_type = purrr::map_chr(
      dlist,
      ~ purrr::pluck(.x, "venues", 1, "venueType", .default = NA_character_)
    ),
    attendees = purrr::map_int(
      dlist,
      c("rsvps", "totalCount"),
      .default = NA_integer_
    ),
    photo_url = purrr::map_chr(
      dlist,
      c("featuredEventPhoto", "baseUrl"),
      .default = NA_character_
    )
  ) |>
    process_datetime_fields(c("created", "date_time"))
}
