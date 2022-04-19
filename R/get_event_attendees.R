#' Get the attendees for a specified event
#'
#' @param id Required event ID
#' @param ... Should be empty. Used for parameter expansion
#' @return A tibble with the following columns:
#'    * id
#'    * name
#'    * url
#'    * photo
#'    * organized_group_count
#' @references
#' \url{https://www.meetup.com/api/schema/#Event}
#' \url{https://www.meetup.com/api/schema/#Ticket}
#' \url{https://www.meetup.com/api/schema/#User}
#' @examples
#' \dontrun{
#' attendees <- get_event_attendees(id = "103349942!chp")
#' }
#' @importFrom dplyr %>%
#' @export
get_event_attendees <- function(
  id,
  ...,
  extra_graphql = NULL,
  token = meetup_token()
) {
  ellipsis::check_dots_empty()

  dt <- gql_get_event_attendees(
    id = id,
    .extra_graphql = extra_graphql,
    .token = token
  )

  dt %>%
  dplyr::rename(
    url = .data$memberUrl,
    photo = .data$memberPhoto.baseUrl,
    organized_group_count = .data$organizedGroupCount
  )
}

