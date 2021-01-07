#' Get the RSVPs for a specified event
#'
#' @template urlname
#' @param event_id Character. The id of the event. Event ids can be obtained
#'   using [get_events()] or by looking at the event page URL.
#' @template api_key
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
get_event_rsvps <- function(urlname, event_id, api_key = NULL, verbose = TRUE) {
  api_method <-   api_method <- sprintf("%s/events/%s/rsvps",
                                        urlname, event_id)
  res <- .fetch_results(api_method, api_key, verbose = verbose)
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
