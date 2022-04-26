#' Find meetup groups matching a search query
#'
#' @param query Required search text
#' @param ... Should be empty. Used for parameter expansion
#' @param topic_category_id Topic ID e.g 543 for technology topic
#' @param lat Latitude. An integer
#' @param lon Longitutde. An integer
#' @param radius Radius. An integer
#' @param extra_graphql A graphql object. Extra objects to return
#' @param token Meetup token
#' @importFrom dplyr %>%
#' @export
find_groups <- function(
  query,
  ...,
  topic_category_id = NULL,
  lat = 0,
  lon = 0,
  radius = 100000000,
  extra_graphql = NULL,
  token = meetup_token()
) {
  ellipsis::check_dots_empty()

  dt <- gql_find_groups(
    query = query,
    topicCategoryId = topic_category_id,
    lat = lat,
    lon = lon,
    radius = radius,
    .extra_graphql = extra_graphql,
    .token = token
  )

  dt %>%
    dplyr::select(-.data$country) %>%
    dplyr::rename(
      created = .data$foundedDate,
      members = .data$memberships.count,
      join_mode = .data$joinMode,
      category_id = .data$category.id,
      category_name = .data$category.name,
      country = .data$country_name,
    ) %>%
    dplyr::mutate(
      created = anytime::anytime(.data$created)
    )
}
