#' Get the comments for a specified event
#'
#' @param id Required event ID
#' @param ... Should be empty. Used for parameter expansion
#' @template extra_graphql
#' @return A tibble with the following columns:
#'    * id
#'    * comment
#'    * created
#'    * like_count
#'    * member_id
#'    * member_name
#'    * link
#' @references
#' \url{https://www.meetup.com/api/schema/#Event}
#' \url{https://www.meetup.com/api/schema/#EventCommentConnection}
#' @examples
#' \dontrun{
#' comments <- get_event_comments(id = "103349942")
#' }
#' @export
get_event_comments <- function(
  id,
  ...,
  extra_graphql = NULL
) {
  ellipsis::check_dots_empty()

  cli::cli_warn(c(
    "!" = "Event comments functionality has been removed from the current Meetup GraphQL API.",
    "i" = "The 'comments' field is no longer available on the Event type.",
    "i" = "This function returns an empty tibble for backwards compatibility.",
    "i" = "Comment mutations may still work, but querying comments is not supported."
  ))

  create_empty_comments_tibble()
}

create_empty_comments_tibble <- function() {
  dplyr::tibble(
    id = character(0),
    comment = character(0),
    created = character(0),
    like_count = integer(0),
    member_id = character(0),
    member_name = character(0),
    link = character(0)
  )
}
