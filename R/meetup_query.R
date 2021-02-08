
#' General Meetup query
#'
#' Create your own query to the Meetup API
#' (https://www.meetup.com/meetup_api/docs/).
#'
#'
#' @param api_path url path to send the meetup query after the 'https://api.meetup.com/'
#' @param ... additional parameters to the query
#'
#' @return raw list results from the query, untitied
#' @export
#'
#' @examples
#' \dontrun{
#'
#' meetup_query("rladies-oslo")
#'
#' meetup_query("rladies-oslo/events", event_status = "past")
#'
#' }
meetup_query <- function(api_path,
                         ...){
  .fetch_results(api_path,
               ...)
}
