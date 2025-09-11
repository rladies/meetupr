#' Get the members from a meetup group
#'
#' @template urlname
#' @param max_results Maximum number of results to return. Default: 200
#' @param ... Should be empty. Used for parameter expansion
#' @template extra_graphql
#' @return A tibble with the following columns:
#'    * id
#'    * name
#'    * member_url
#'    * photo_link
#'    * status
#'    * role
#'    * joined
#'    * most_recent_visit
#' @export
get_members <- function(urlname, max_results = 200, ..., extra_graphql = NULL) {
  ellipsis::check_dots_empty()

  query_obj <- members_query(max_results)
  execute(
    query_obj,
    urlname = urlname,
    first = min(max_results, 200),
    .extra_graphql = extra_graphql
  )
}

#' Get the members from a meetup group
#'
#' @template urlname
#' @param max_results Maximum number of results to return. Default: 200
#' @param ... Should be empty. Used for parameter expansion
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
get_members <- function(urlname, max_results = 200, ..., extra_graphql = NULL) {
  ellipsis::check_dots_empty()

  query_obj <- members_query(max_results)
  execute(
    query_obj,
    urlname = urlname,
    first = max_results,
    .extra_graphql = extra_graphql
  )
}

process_members_data <- function(dlist) {
  dplyr::tibble(
    id = purrr::map_chr(
      dlist,
      c("node", "id"),
      .default = NA_character_
    ),
    name = purrr::map_chr(
      dlist,
      c("node", "name"),
      .default = NA_character_
    ),
    member_url = purrr::map_chr(
      dlist,
      c("node", "memberUrl"),
      .default = NA_character_
    ),
    photo_link = purrr::map_chr(
      dlist,
      c("node", "memberPhoto", "baseUrl"),
      .default = NA_character_
    ),
    status = purrr::map_chr(
      dlist,
      c("metadata", "status"),
      .default = NA_character_
    ),
    role = purrr::map_chr(
      dlist,
      c("metadata", "role"),
      .default = NA_character_
    ),
    joined = purrr::map_chr(
      dlist,
      c("metadata", "joinTime"),
      .default = NA_character_
    ),
    most_recent_visit = purrr::map_chr(
      dlist,
      c("metadata", "lastAccessTime"),
      .default = NA_character_
    )
  ) |>
    process_datetime_fields(c("joined", "most_recent_visit"))
}
