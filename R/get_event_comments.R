#' Get the comments for a specified event
#'
#' @template id
#' @param ... Should be empty. Used for parameter expansion
#' @template extra_graphql
#' @template token
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
#' comments <- get_event_comments(id = "103349942!chp")
#' }
#' @export
get_event_comments <- function(
  id,
  ...,
  extra_graphql = NULL,
  token = meetup_token()
) {
  ellipsis::check_dots_empty()

  dt <- gql_get_event_comments(
    id = id,
    .extra_graphql = extra_graphql,
    .token = token
  )

  rename(dt,
      comment = text,
      like_count = likeCount,
      member_id = member.id,
      member_name = member.name
    )

}
