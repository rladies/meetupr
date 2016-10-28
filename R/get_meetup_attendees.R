#' Get the attendees
#'
#' @param group_name The name of the group.
#' @param id The id of the event.
#' @param api_key Your api key.



get_meetup_attendees <- function(group_name, id, api_key){
  api <- 'https://api.meetup.com/'
  url_attendes <- paste0(api, group_name, "/events/", id, "/attendance")
  url_attendes %>%
    httr::GET(query = list(key = api_key)) %>%
    httr::content()
}
