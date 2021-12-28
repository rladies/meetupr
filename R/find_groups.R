#' Find meetup groups matching a search query
#'
#' @param text Character. Raw full text search query.
#' @param topic_id  Integer. Meetup.com topic ID.
#' @param radius can be either "global" (default) or distance in miles in the
#' range 0-100.
#' @param fields Character. Optional fields that are not returned by default.
#' @template verbose
#'
#' @return A tibble with the following columns:
#'    * id
#'    * name
#'    * urlname
#'    * created
#'    * members
#'    * status
#'    * organizer
#'    * lat
#'    * lon
#'    * city
#'    * state
#'    * country
#'    * timezone
#'    * join_mode
#'    * visibility
#'    * who
#'    * organizer_id
#'    * organizer_name
#'    * category_id
#'    * category_name
#'    * resource
#'
#' @references
#' \url{https://www.meetup.com/meetup_api/docs/find/groups/}
#' \url{https://www.meetup.com/meetup_api/docs/find/topics/}
#'@examples
#' \dontrun{
#' groups <- find_groups(text = "r-ladies")
#' groups <- find_groups(topic_id = 1513883)
#' groups <- find_groups(text = "r-ladies", fields = "past_event_count,
#'  upcoming_event_count")
#' past_event_counts <- purrr::map_dbl(groups$resource, "past_event_count",
#'  .default = 0)
#' upcoming_event_counts <- purrr::map_dbl(groups$resource, "upcoming_event_count",
#'  .default = 0)
#'}
#' @export
#' @importFrom purrr map_dbl map_int map_chr
#' @importFrom tibble tibble
find_groups <- function(text = NULL, topic_id = NULL, radius = "global",
                        fields = NULL,
                        verbose = meetupr_verbose()) {

  res <- .fetch_results(api_path = "find/groups",
                        text = text,
                        topic_id = .collapse(topic_id),
                        fields = .collapse(fields),
                        radius = radius,
                        verbose = verbose)

  base <- group_sorter(res)
  base$country = NULL

  tibble(
    base,
    country = map_chr(res, "localized_country_name"),
    created = .date_helper(map_dbl(res, "created")),
    members = map_int(res, "members"),
    timezone = map_chr(res, "timezone", .default = NA),
    join_mode = map_chr(res, "join_mode", .default = NA),
    visibility = map_chr(res, "visibility", .default = NA),
    who = map_chr(res, "who", .default = NA),
    location = map_chr(res, "localized_location"),
    organizer_id = map_int(res, c("organizer", "id")),
    organizer_name = map_chr(res, c("organizer", "name")),
    category_id = map_int(res, c("category", "id"), .default = NA),
    category_name = map_chr(res, c("category", "name"), .default = NA),
    resource = res
  )
}
