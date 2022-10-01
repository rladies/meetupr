#' Find meetup groups matching a search query
#'
#' @param query Required search text
#' @param ... Should be empty. Used for parameter expansion
#' @param topic_category_id Topic ID e.g 543 for technology topic
#' @param lat Latitude. An integer
#' @param lon Longitutde. An integer
#' @param radius Radius. An integer
#' @param ... Should be empty. Used for parameter expansion
#' @template extra_graphql
#' @template token
#' @importFrom anytime anytime
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

  dt <- rename(dt,
    created = foundedDate,
    members = memberships.count,
    join_mode = joinMode,
    category_id = category.id,
    category_name = category.name,
    country = country_name,
  )

  dt$country <- NULL
  dt$created <- anytime::anytime(dt$created)
  dt
}

