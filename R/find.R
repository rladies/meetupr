#' Find groups using text-based search
#'
#' Search for groups on Meetup using a text query. This function allows
#' you to find groups that match your search criteria.
#'
#'
#' @param query Character string to search for groups
#' @param topic_id Numeric ID of a topic to filter groups by
#' @param category_id Numeric ID of a category to filter groups by
#' @template max_results
#' @template handle_multiples
#' @template extra_graphql
#' @template asis
#' @param ... other named variables for graphql query. options are:
#'   - lat: Float
#'   - lon: Float
#'   - radius: Float
#'   - categoryId: ID
#'   - topicCategoryId: ID
#' @return A tibble with group information
#' @examples
#' \dontshow{
#' vcr::insert_example_cassette("find_groups", package = "meetupr")
#' meetupr:::mock_if_no_auth()
#' }
#' groups <- find_groups("R-Ladies")
#' groups
#' \dontshow{
#' vcr::eject_cassette()
#' }
#' @export
find_groups <- function(
  query,
  topic_id = NULL,
  category_id = NULL,
  max_results = 200,
  handle_multiples = "list",
  extra_graphql = NULL,
  asis = FALSE,
  ...
) {
  std_query <- standard_query(
    "find_groups",
    "data.groupSearch"
  )

  execute(
    std_query,
    query = query,
    categoryId = category_id,
    topicCategoryId = topic_id,
    first = max_results,
    max_results = max_results,
    handle_multiples = handle_multiples,
    extra_graphql = extra_graphql,
    asis = asis,
    ...
  ) |>
    process_datetime_fields("founded_date")
}


#' Find topics on Meetup
#'
#' Search for topics on Meetup using a query string.
#' This function allows you to find topics that match your search criteria.
#'
#' @param query A string query to search for topics.
#' @template max_results
#' @template handle_multiples
#' @template extra_graphql
#' @template asis
#' @param ... Used for parameter expansion, must be empty.
#' @return A data frame of topics matching the search query.
#' @examples
#' \dontshow{
#' vcr::insert_example_cassette("find_topics", package = "meetupr")
#' meetupr:::mock_if_no_auth()
#' }
#' find_topics("R", max_results = 10)
#' find_topics("Data Science", max_results = 5)
#' \dontshow{
#' vcr::eject_cassette()
#' }
#' @export
find_topics <- function(
  query,
  max_results = 200,
  handle_multiples = "list",
  extra_graphql = NULL,
  asis = FALSE,
  ...
) {
  rlang::check_dots_empty()

  std_query <- standard_query(
    "find_topics",
    "data.suggestTopics"
  )

  execute(
    std_query,
    query = query,
    first = max_results,
    max_results = max_results,
    handle_multiples = handle_multiples,
    extra_graphql = extra_graphql,
    asis = asis
  )
}
