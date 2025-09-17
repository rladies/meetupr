#' Find groups using text-based search
#'
#' Search for groups on Meetup using a text query. This function allows
#' you to find groups that match your search criteria.
#'
#' @param query Character string to search for groups
#' @template max_results
#' @template handle_multiples
#' @template extra_graphql
#' @param ... Should be empty. Used for parameter expansion
#' @return A tibble with group information
#' @examples
#' \dontshow{
#' vcr::insert_example_cassette("find_groups", package = "meetupr")
#' meetupr:::mock_if_no_auth()
#' }
#' groups <- find_groups("R-Ladies")
#' \dontshow{
#' vcr::eject_cassette()
#' }
#' @export
find_groups <- function(
  query,
  max_results = 200,
  handle_multiples = "list",
  extra_graphql = NULL,
  ...
) {
  ellipsis::check_dots_empty()

  std_query <- standard_query(
    "find_groups",
    "data.groupSearch"
  )

  execute(
    std_query,
    query = query,
    first = max_results,
    max_results = max_results,
    handle_multiples = handle_multiples,
    extra_graphql = extra_graphql
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
  ...
) {
  ellipsis::check_dots_empty()

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
    extra_graphql = extra_graphql
  )
}
