#' Find groups using text-based search
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

  group_query <- create_meetup_query(
    template = "find_groups",
    page_info_path = "data.groupSearch.pageInfo",
    edges_path = "data.groupSearch.edges",
    total_path = "data.groupSearch.count",
    process_data = process_groups_data,
    transform_fn = function(nodes) {
      add_country_name(nodes, get_country = function(group) group$country)
    }
  )

  execute(
    group_query,
    query = query,
    first = max_results,
    max_results = max_results,
    handle_multiples = handle_multiples,
    extra_graphql = extra_graphql
  )
}

#' Process group data dynamically
#' @param dlist List of group data from GraphQL
#' @return tibble with group information
#' @keywords internal
#' @noRd
process_groups_data <- function(dlist, handle_multiples = "list") {
  result <- process_graphql_list(
    dlist,
    handle_multiples = handle_multiples
  )

  # Post-process datetime fields
  if ("founded_date" %in% names(result)) {
    result <- process_datetime_fields(result, "founded_date")
  }

  result
}
