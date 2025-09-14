#' Get the members from a meetup group
#'
#' @template urlname
#' @param max_results Maximum number of results to return. Default: 200
#' @param ... Should be empty. Used for parameter expansion
#' @template max_results
#' @template handle_multiples
#' @template extra_graphql
#' @return A tibble with group members
#' @export
#' @examples
#' \dontshow{
#' vcr::insert_example_cassette("get_members", package = "meetupr")
#' meetupr:::mock_if_no_auth()
#' }
#' get_members("rladies-lagos")
#' \dontshow{
#' vcr::eject_cassette()
#' }
get_members <- function(
  urlname,
  max_results = NULL,
  handle_multiples = "list",
  extra_graphql = NULL,
  ...
) {
  ellipsis::check_dots_empty()

  execute(
    create_meetup_query(
      template = "get_members",
      page_info_path = "data.groupByUrlname.memberships.pageInfo",
      edges_path = "data.groupByUrlname.memberships.edges",
      process_data = process_members_data
    ),
    urlname = urlname,
    first = max_results,
    extra_graphql = extra_graphql
  )
}

#' Process members data dynamically
#' @param dlist List of member data from GraphQL
#' @return tibble with member information
#' @keywords internal
#' @noRd
process_members_data <- function(dlist, handle_multiples = "list") {
  process_graphql_list(
    dlist,
    handle_multiples = handle_multiples
  )
}
