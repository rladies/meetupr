#' Get the attendees
#'
#' @param urlname The name of the group.
#' @param api_key Your api key.
#' @param event_id The id of the event.
#' @export
get_meetup_attendees <- function(urlname, api_key, event_id){
  api_url <- paste0(meetup_api_prefix(), urlname, "/events/", event_id, "/attendance")
  .fetch_results(api_url, api_key)
}



# Example:
# urlname <- "rladies-san-francisco"
# event_id <- past_events[[1]]$id
# get_meetup_attendees(urlname, api_key, event_id)
