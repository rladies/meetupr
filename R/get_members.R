#' Get the current meetup members from a meetup group
#'
#' @param urlname Required urlname of the Meetup group
#' @param ... Should be empty. Used for parameter expansion
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
#' @importFrom dplyr %>%
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

  dt %>%
    dplyr::rename(
      id = .data$node.id,
      name = .data$node.name,
      member_url = .data$node.memberUrl,
      photo_link = .data$node.memberPhoto.baseUrl,
      status = .data$metadata.status,
      role = .data$metadata.role,
      created = .data$metadata.joinedDate,
      most_recent_visit = .data$metadata.mostRecentVisitDate
    ) %>%
    dplyr::mutate(
      created = anytime::anytime(.data$created),
      most_recent_visit = anytime::anytime(.data$most_recent_visit)
    )
}

