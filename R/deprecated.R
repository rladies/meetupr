#' DEPRECATED: Get the comments (as a list)
#'
#' @param urlname The name of the group.
#' @param api_key Your api key.
#' @param event_id The id of the event.
#'
#' @examples
#' \dontrun{
#' urlname <- "rladies-san-francisco"
#' api_key <- Sys.getenv("MEETUP_KEY")
#' past_events <- get_events(urlname = urlname,
#'                       api_key = api_key,
#'                       event_status = "past")
#' event_id <- past_events[[1]]$id
#' comments <- get_meetup_comments(urlname, api_key, event_id)
#'}
#' @export
get_meetup_comments <- function(urlname, api_key, event_id) {
  .Deprecated("get_event_comments()")
  warning("NOTE: This function will be removed in the next release.")
  #get_event_comments(urlname = urlname, event_id = event_id, api_key = api_key)
  api_method <- paste0(urlname, "/events/", event_id, "/comments")
  .fetch_results(api_method, api_key)
}


#' DEPRECATED: Get the attendees (as a list)
#'
#' @param urlname The name of the group.
#' @param api_key Your api key.
#' @param event_id The id of the event.
#'
#' @examples
#' \dontrun{
#' urlname <- "rladies-san-francisco"
#' api_key <- Sys.getenv("MEETUP_KEY")
#' past_events <- get_events(urlname = urlname,
#'                       api_key = api_key,
#'                       event_status = "past")
#' event_id <- past_events[[1]]$id
#' attendees <- get_meetup_attendees(urlname, api_key, event_id)
#'}
#' @export
get_meetup_attendees <- function(urlname, api_key, event_id) {
  .Deprecated("get_event_attendees()")
  warning("NOTE: This function will be removed in the next release.")
  api_method <- paste0(urlname,
                       "/events/",
                       event_id,
                       "/attendance")
  .fetch_results(api_method, api_key)
}





