#' Get the events from a meetup group
#'
#' @template urlname
#' @param event_status Character. Event type - defaults to "upcomming".
#'  Valid inputs are:
#'  * cancelled
#'  * draft
#'  * past
#'  * proposed
#'  * suggested
#'  * upcoming
#' @template api_key
#'
#' @return A tibble with the following columns:
#'    * id
#'    * name
#'    * yes_rsvp_count
#'    * time
#'    * resource
#'
#' @references
#' \url{https://www.meetup.com/meetup_api/docs/:urlname/events/#list}
#'@examples
#' \dontrun{
#' urlname <- "rladies-nashville"
#' past_events <- get_events(urlname = urlname,
#'                       event_status = "past")
#' upcoming_events <- get_events(urlname = urlname,
#'                       event_status = "upcoming")
#'}
#' @export
get_events <- function(urlname, event_status = "upcoming", api_key = NULL) {
  if (!is.null(event_status) &&
     !event_status %in% c("cancelled", "draft", "past", "proposed", "suggested", "upcoming")) {
    stop(sprintf("Event status %s not allowed", event_status))
  }
  api_method <- paste0(urlname, "/events")
  res <- .fetch_results(api_method, api_key, event_status)
  tibble::tibble(
    id = purrr::map_chr(res, "id"),
    name = purrr::map_chr(res, "name"),
    yes_rsvp_count = purrr::map_int(res, "yes_rsvp_count"),
    time = .date_helper(purrr::map_dbl(res, "time")),
    resource = res
  )
}
