#' Get the current meetup members from a meetup group
#'
#' @template urlname
#' @param ... Should be empty. Used for parameter expansion
#' @template extra_graphql
#' @template token
#' @return A tibble with the following columns:
#'    * id
#'    * name
#'    * member_url
#'    * photo_link
#'    * status
#'    * role
#'    * created
#'    * most_recent_visit
#' @references
#' \url{https://www.meetup.com/api/schema/#GroupMembership}
#' \url{https://www.meetup.com/api/schema/#User}
#' @examples
#' \dontrun{
#' members <- get_members("rladies-remote")
#' }
#' @importFrom anytime anytime
#' @export
get_members <- function(
    urlname,
    ...,
    extra_graphql = NULL,
    token = meetup_token()
) {
  ellipsis::check_dots_empty()

  dt <- gql_get_members(
    urlname = urlname,
    .extra_graphql = extra_graphql,
    .token = token
  )

  dt <- rename(dt,
               id = node.id,
               name = node.name,
               member_url = node.memberUrl,
               photo_link = node.memberPhoto.baseUrl,
               status = metadata.status,
               role = metadata.role,
               created = metadata.joinedDate,
               most_recent_visit = metadata.mostRecentVisitDate
  )

  dt$created = anytime::anytime(dt$created)
  dt$most_recent_visit = anytime::anytime(dt$most_recent_visit)
  dt
}

