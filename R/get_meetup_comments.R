#' Get the comments
#'
#' @param urlname The name of the group.
#' @param api_key Your api key.
#' @param event_id The id of the event.
#'
#' @examples
#' \dontrun{
#' urlname <- "rladies-san-francisco"
#' api_key <- Sys.getenv("rladies_api_key")
#' past_events <- get_events(urlname = urlname,
#'                       api_key = api_key,
#'                       event_status = "past")
#' event_id <- past_events[[1]]$id
#' comments <- get_meetup_comments(urlname, api_key, event_id)
#'}
#' @export
get_meetup_comments <- function(urlname, api_key, event_id){
  api_url <- paste0(meetup_api_prefix, urlname, "/events/", event_id, "/comments")
  .fetch_results(api_url, api_key)
}

