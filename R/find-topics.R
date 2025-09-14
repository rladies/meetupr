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

  topic_query <- create_meetup_query(
    template = "find_topics",
    page_info_path = "data.suggestTopics.pageInfo",
    edges_path = "data.suggestTopics.edges",
    process_data = process_groups_data
  )

  execute(
    topic_query,
    query = query,
    first = max_results,
    max_results = max_results,
    handle_multiples = handle_multiples,
    extra_graphql = extra_graphql
  )
}
