#' Get the events from a meetup group
#'
#' @param urlname The name of the group.
#' @param api_key Your api key.
#' @param event_status A character string defining an event type. If empty upcoming meetups will be provided.
#'
#' @return List containing requested events.
#'
#'
#'
#' @export
get_events <- function(urlname, api_key, event_status = NULL) {
  if(!is.null(event_status) && !event_status %in% c("cancelled", "draft", "past", "proposed", "suggested", "upcoming")) {
    stop(sprintf("Event status %s not allowed", event_status))
  }
  meetup_api_prefix <- "https://api.meetup.com/"
  api_url <- paste0(meetup_api_prefix, urlname, "/events")
  .fetch_results(api_url, api_key, event_status)
}


## Example
#past_events <- get_events(urlname = 'Spotkania-Entuzjastow-R-Warsaw-R-Users-Group-Meetup', api_key = api_key, event_status = "past")
# future_events <- get_events(urlname = "rladies-san-francisco",  api_key, event_status = "upcoming")
# get_events(urlname = 'Spotkania-Entuzjastow-R-Warsaw-R-Users-Group-Meetup', api_key = api_key, event_status = "future") ##error
