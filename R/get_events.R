#' Get the events from a meetup group
#'
#' @param group_name The name of the group.
#' @param api_key Your api key.
#'
#' @return The events.
#' @examples
#' get_events




get_events <- function(urlname, api_key, event_status = NULL) {
  meetup_api_prefix <- "https://api.meetup.com/"
  api_url <- paste0(meetup_api_prefix, urlname, "/events")
  .fetch_results(api_url, api_key, event_status)
}




## Example
# past_events <- get_events(urlname = "rladies-san-francisco", api_key = api_key, event_status = "past")
# future_events <- get_events(urlname = "rladies-san-francisco",  api_key, event_status = "upcoming")
