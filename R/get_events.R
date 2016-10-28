#' Get the events from a meetup group
#'
#' @param group_name The name of the group.
#' @param api_key Your api key.
#' @return The events.
#' @examples
#' get_events


get_events <- function(group_name, api_key){
  api <- 'https://api.meetup.com/'
  url <- paste0(api, group_name, "/events")
  url %>%
    httr::GET(query = list(status = 'past', key = api_key)) %>%
    httr::content()
}












