#' Get the events from a meetup group
#'
#' @param urlname The name of the group.
#' @param api_key Your api key.
#' @param event_status Status of the event.
#'
#'
#' @return The events.
#'
#'
#'
#' @export
get_events <- function(urlname, api_key, event_status = NULL) {
  meetup_api_prefix <- "https://api.meetup.com/"
  api_url <- paste0(meetup_api_prefix, urlname, "/events")
    .fetch_results(api_url, api_key, event_status)
}




