#' Find groups using text-based search
#'
#' @param query Character string to search for groups
#' @param max_results Maximum number of results to return. Default: 200
#' @param ... Should be empty. Used for parameter expansion
#' @template extra_graphql
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
  ...,
  extra_graphql = NULL
) {
  ellipsis::check_dots_empty()

  execute(
    find_groups_query(max_results),
    query = query,
    first = max_results,
    .extra_graphql = extra_graphql
  )
}

process_groups_data <- function(dlist) {
  dplyr::tibble(
    id = purrr::map_chr(dlist, "id", .default = NA_character_),
    name = purrr::map_chr(dlist, "name", .default = NA_character_),
    urlname = purrr::map_chr(dlist, "urlname", .default = NA_character_),
    city = purrr::map_chr(dlist, "city", .default = NA_character_),
    state = purrr::map_chr(dlist, "state", .default = NA_character_),
    country = purrr::map_chr(dlist, "country", .default = NA_character_),
    latitude = purrr::map_dbl(dlist, "lat", .default = NA_real_),
    longitude = purrr::map_dbl(dlist, "lon", .default = NA_real_),
    membership_count = purrr::map_int(
      dlist,
      c("memberships", "totalCount"),
      .default = NA_integer_
    ),
    founded_date = purrr::map_chr(
      dlist,
      "foundedDate",
      .default = NA_character_
    ),
    timezone = purrr::map_chr(dlist, "timezone", .default = NA_character_),
    join_mode = purrr::map_chr(dlist, "joinMode", .default = NA_character_),
    who = purrr::map_chr(dlist, "who", .default = NA_character_),
    is_private = purrr::map_lgl(dlist, "isPrivate", .default = NA),
    category_id = purrr::map_chr(
      dlist,
      c("category", "id"),
      .default = NA_character_
    ),
    category_name = purrr::map_chr(
      dlist,
      c("category", "name"),
      .default = NA_character_
    ),
    membership_status = purrr::map_chr(
      dlist,
      c("membershipMetadata", "status"),
      .default = NA_character_
    )
  ) |>
    process_datetime_fields("founded_date")
}
