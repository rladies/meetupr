#' Get the attendees for a specified event
#'
#' @template urlname
#' @param event_id Character. The id of the event. Event ids can be obtained
#'   using [get_events()].
#' @template api_key
#'
#' @return A tibble with the following columns:
#'    * id
#'    * name
#'    * status
#'    * resource
#' @references
#' \url{https://www.meetup.com/meetup_api/docs/:urlname/events/:id/attendance/#list}
#' @examples
#' \dontrun{
#' urlname <- "rladies-nashville"
#' past_events <- get_events(urlname = urlname,
#'                       event_status = "past")
#' event_id <- past_events$id[1]  #first event for this group
#' attendees <- get_event_attendees(urlname, event_id)
#'}
#' @export
get_event_attendees <- function(urlname, event_id, api_key = NULL) {
  api_params <- paste0(urlname,
                       "/events/",
                       event_id,
                       "/attendance")
  res <- .fetch_results(api_params, api_key)
  tibble::tibble(
    id = purrr::map_chr(res, c("member", "id")),
    name = purrr::map_chr(res, c("member", "name")),
    status = purrr::map_chr(res, "status"),  #currently always "attended" so this is not very useful
    resource = res
  )
}





