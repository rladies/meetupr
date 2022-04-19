#' Get the RSVPs for a specified event
#'
#' @param id Required event ID
#' @param ... Should be empty. Used for parameter expansion
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
#' @importFrom dplyr %>%
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

  dt %>%
    dplyr::rename(
      member_id = .data$user.id,
      member_name = .data$user.name,
      member_url = .data$user.memberUrl,
      event_id = .data$event.id,
      event_title = .data$event.title,
      event_url = .data$event.eventUrl,
      member_is_host = .data$isHost,
      guests = .data$guestsCount,
      response = .data$status,
      created = .data$createdAt,
      updated = .data$updatedAt
    ) %>%
    dplyr::mutate(
      created = anytime::anytime(.data$created),
      updated = anytime::anytime(.data$updated)
    )

}

