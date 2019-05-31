#' Find meetup groups matching a search query
#'
#' @param text Character. Raw full text search query.
#' @param topic_id  Integer. Meetup.com topic ID.
#' @param radius can be either "global" (default) or distance in miles in the
#' range 0-100.
#' @param fields Character. Optional fields that are not returned by default.
#' @template api_key
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
#' api_key <- Sys.getenv("MEETUP_KEY")
#' groups <- find_groups(text = "r-ladies", api_key = api_key)
#' groups <- find_groups(topic_id = 1513883, api_key = api_key)
#' groups <- find_groups(text = "r-ladies", fields = "past_event_count,
#'  upcoming_event_count", api_key = api_key)
#' past_event_counts <- purrr::map_dbl(groups$resource, "past_event_count",
#'  .default = 0)
#' upcoming_event_counts <- purrr::map_dbl(groups$resource, "upcoming_event_count",
#'  .default = 0)
#'}
#' @export
find_groups <- function(text = NULL, topic_id = NULL, radius = "global", fields = NULL, api_key = NULL) {
  api_method <- "find/groups"
  res <- .fetch_results(api_method = api_method,
                        api_key = api_key,
                        text = text,
                        topic_id = topic_id,
                        fields = fields,
                        radius = radius)
  tibble::tibble(
    id = purrr::map_int(res, "id"),
    name = purrr::map_chr(res, "name"),
    urlname = purrr::map_chr(res, "urlname"),
    created = .date_helper(purrr::map_dbl(res, "created")),
    members = purrr::map_int(res, "members"),
    status = purrr::map_chr(res, "status"),
    organizer = purrr::map_chr(res, c("organizer", "name")),
    lat = purrr::map_dbl(res, "lat"),
    lon = purrr::map_dbl(res, "lon"),
    city = purrr::map_chr(res, "city"),
    state = purrr::map_chr(res, "state", .null = NA),
    country = purrr::map_chr(res, "country"),
    timezone = purrr::map_chr(res, "timezone", .null = NA),
    join_mode = purrr::map_chr(res, "join_mode", .null = NA),
    visibility = purrr::map_chr(res, "visibility", .null = NA),
    who = purrr::map_chr(res, "who", .null = NA),
    organizer_id = purrr::map_int(res, c("organizer", "id")),
    organizer_name = purrr::map_chr(res, c("organizer", "name")),
    category_id = purrr::map_int(res, c("category", "id"), .null = NA),
    category_name = purrr::map_chr(res, c("category", "name"), .null = NA),
    resource = res
  )
}
