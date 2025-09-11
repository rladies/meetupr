#' Get the RSVPs for a specified event
#'
#' @param id Required event ID
#' @param ... Should be empty. Used for parameter expansion
#' @template extra_graphql
#' @return A tibble with the following columns:
#'    * rsvp_id
#'    * member_id
#'    * member_name
#'    * member_url
#'    * member_photo
#'    * guests_count
#'    * response
#' @references
#' \url{https://www.meetup.com/api/schema/#Event}
#' \url{https://www.meetup.com/api/schema/#RSVP}
#' \url{https://www.meetup.com/api/schema/#Member}
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
get_event_rsvps <- function(id, ..., extra_graphql = NULL) {
  ellipsis::check_dots_empty()
  execute(
    event_rsvps_query,
    id = id,
    .extra_graphql = extra_graphql
  )
}

process_rsvps_data <- function(dlist) {
  dplyr::tibble(
    rsvp_id = purrr::map_chr(dlist, "id", .default = NA_character_),
    response = purrr::map_chr(dlist, "status", .default = NA_character_),
    guests_count = purrr::map_int(dlist, "guestsCount", .default = NA_integer_),
    member_id = purrr::map_chr(
      dlist,
      c("member", "id"),
      .default = NA_character_
    ),
    member_name = purrr::map_chr(
      dlist,
      c("member", "name"),
      .default = NA_character_
    ),
    member_url = purrr::map_chr(
      dlist,
      c("member", "memberUrl"),
      .default = NA_character_
    ),
    member_photo = purrr::map_chr(
      dlist,
      c("member", "memberPhoto", "baseUrl"),
      .default = NA_character_
    )
  )
}
