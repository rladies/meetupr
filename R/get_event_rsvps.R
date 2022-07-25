#' Get the RSVPs for a specified event
#'
#' @param id Required event ID
#' @param ... Should be empty. Used for parameter expansion
#' @param extra_graphql A graphql object. Extra objects to return
#' @param token Meetup token
#' @return A tibble with the following columns:
#'    * member_id
#'    * member_name
#'    * member_url
#'    * member_is_host
#'    * guests
#'    * response
#'    * event_id
#'    * event_title
#'    * event_url
#'    * created
#'    * updated
#' @references
#' \url{https://www.meetup.com/api/schema/#Event}
#' \url{https://www.meetup.com/api/schema/#Ticket}
#' \url{https://www.meetup.com/api/schema/#User}
#' @examples
#' \dontrun{
#' rsvps <- get_event_rsvps(id = "103349942!chp")
#' }
#' @importFrom dplyr rename mutate
#' @export
get_event_rsvps <- function(
  id,
  ...,
  extra_graphql = NULL,
  token = meetup_token()
) {
  ellipsis::check_dots_empty()

  dt <- gql_get_event_rsvps(
    id = id,
    .extra_graphql = extra_graphql,
    .token = token
  )

  dt  |>
    dplyr::rename(
      member_id = user.id,
      member_name = user.name,
      member_url = user.memberUrl,
      event_id = event.id,
      event_title = event.title,
      event_url = event.eventUrl,
      member_is_host = isHost,
      guests = guestsCount,
      response = status,
      created = createdAt,
      updated = updatedAt
    )  |>
    dplyr::mutate(
      created = anytime::anytime(created),
      updated = anytime::anytime(updated)
    )

}

