#' Get the RSVPs for a specified event
#'
#' @template urlname
#' @param event_id Character. The id of the event. Event ids can be obtained
#'   using [get_events()] or by looking at the event page URL.
#' @template verbose
#'
#' @return A tibble with the following columns:
#'    * member_id
#'    * member_name
#'    * member_is_host
#'    * response
#'    * guests
#'    * created
#'    * updated
#'    * resource
#' @references
#' \url{https://www.meetup.com/meetup_api/docs/:urlname/events/:event_id/rsvps/#list}
#' @examples
#' \dontrun{
#' urlname <- "rladies-nashville"
#' upcoming_events <- get_events(urlname = urlname,
#'                       event_status = "past")
#' event_id <- upcoming_events$id[1]  #first event for this group
#' rsvps <- get_event_rsvps(urlname, event_id)
#'}
#' @export
get_event_rsvps <- function(urlname, event_id,
                            verbose = meetupr_verbose()) {
  api_path <- sprintf("%s/events/%s/rsvps",
                      urlname, event_id)
  res <- .fetch_results(api_path = api_path, verbose = verbose)
  tibble::tibble(
    member_id = purrr::map_int(res, c("member", "id")),
    member_name = purrr::map_chr(res, c("member", "name")),
    member_is_host = purrr::map_lgl(res, c("member", "event_context", "host")),
    response = purrr::map_chr(res, "response"),
    guests = purrr::map_int(res, "guests"),
    created = .date_helper(purrr::map_dbl(res, "created")),
    updated = .date_helper(purrr::map_dbl(res, "updated")),
    resource = res
  )
}


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
#' rsvps <- get_event_rsvps2(id = "103349942!chp")
#' }
#' @importFrom dplyr %>%
get_event_rsvps2 <- function(
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

