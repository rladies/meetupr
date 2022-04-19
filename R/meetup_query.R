#' General Meetup query
#'
#' Create your own query to the Meetup API
#' @param query Required query text. Test queries at: https://www.meetup.com/api/playground
#' @param ... Should be empty. Used for parameter expansion
#'
#' @return raw list results from the query, not tidied
#' @export
#'
#' @examples
#' \dontrun{
#'  res <- meetup_query('
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
meetup_query <- function(
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
