#' General Meetup query
#'
#' Create your own query to the Meetup API
#' (https://www.meetup.com/meetup_api/docs/).
#' This function is convenient if you want to create
#' a query to other Meetup API endpoints that we
#' have not created functions for. If you do create
#' a function that queries a currently unsupported
#' endpoint and a results tidier for this, we are happy
#' to receive PR's with your suggestion.
#'
#' @param api_path url path to send the meetup query after the 'https://api.meetup.com/'
#' @param ... additional parameters to the query
#'
#' @return raw list results from the query, not tidied
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

#' @param query Required query text. Test queries at: https://www.meetup.com/api/playground
#' @param ... Should be empty. Used for parameter expansion
#' @examples
#' \dontrun{
#'  res <- meetup_query2('
#'    query($eventId: ID = "103349942!chp") {
#'     event(id: $eventId) {
#'      title
#'      description
#'      dateTime
#'     }
#'    }
#' ')
#' }
#'
meetup_query2 <- function(
  query,
  ...,
  token = meetup_token()
) {
  res <- graphql_query(
    .query = query,
    .token = token
    )
  res$data
}
