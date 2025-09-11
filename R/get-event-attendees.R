#' Get the attendees for a specified event
#'
#' @param id Required event ID
#' @param ... Should be empty. Used for parameter expansion
#' @template extra_graphql
#' @return A tibble with the following columns:
#'    * id
#'    * name
#'    * url
#'    * photo
#'    * organized_group_count
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
get_event_attendees <- function(id, ..., extra_graphql = NULL) {
  ellipsis::check_dots_empty()
  execute(
    event_attendees_query,
    id = id,
    .extra_graphql = extra_graphql
  )
}

process_attendees_data <- function(dlist) {
  dplyr::tibble(
    rsvp_id = purrr::map_chr(dlist, "id", .default = NA_character_),
    response = purrr::map_chr(dlist, "status", .default = NA_character_),
    guests_count = purrr::map_int(dlist, "guestsCount", .default = NA_integer_),
    id = purrr::map_chr(dlist, c("member", "id"), .default = NA_character_),
    name = purrr::map_chr(dlist, c("member", "name"), .default = NA_character_),
    bio = purrr::map_chr(dlist, c("member", "bio"), .default = NA_character_),
    url = purrr::map_chr(
      dlist,
      c("member", "memberUrl"),
      .default = NA_character_
    ),
    photo = purrr::map_chr(
      dlist,
      c("member", "memberPhoto", "baseUrl"),
      .default = NA_character_
    ),
    organized_group_count = purrr::map_int(
      dlist,
      c("member", "organizedGroups", "totalCount"),
      .default = NA_integer_
    )
  )
}
