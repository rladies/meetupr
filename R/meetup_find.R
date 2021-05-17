#' Find meetup information by searching
#'
#' These functions search for relevant meetup information
#' based. These are usually good to use to find all groups
#' that fall within a certain topic or that have a specific string
#' in their name.
#'
#' \describe{
#'   \item{find_topics}{Find meetup topic IDs matching a text search query}
#'   \item{find_groups}{Find meetup groups by searching group names}
#' }
#'
#' @param text Character. Raw full text search query.
#' @param topic_id  Integer. Meetup.com topic ID.
#' @param radius can be either "global" (default) or distance in miles in the
#' range 0-100.
#' @param fields Character. Optional fields that are not returned by default.
#' @template verbose
#' @param ... Other parameters to send to the API query
#'
#' @return A tibble with relevant meetup information
#'
#' @references
#' \url{https://www.meetup.com/meetup_api/docs/find/groups/}
#' \url{https://www.meetup.com/meetup_api/docs/find/topics/}
#'
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
#'
#' topics <- find_topics(text = "R-Ladies")
#' # Note that R-Ladies has topic id 1513883
#' groups <- find_groups(topic_id = 1513883)
#'}

#' @rdname meetup_find
#' @export
#' @importFrom purrr map_dbl map_int map_chr
#' @importFrom tibble tibble
find_groups <- function(text = NULL, topic_id = NULL, radius = "global",
                        fields = NULL,
                        verbose = getOption("meetupr.verbose", rlang::is_interactive())) {

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


#' @rdname meetup_find
#' @importFrom purrr map_int map_chr
#' @importFrom tibble tibble
#' @export
find_topics <- function(text = NULL,
                        verbose = getOption("meetupr.verbose", rlang::is_interactive()),
                        ...) {
  res <- .fetch_results("find/topics", query = text, ...)
  tibble(
    id = map_int(res, "id"),
    name = map_chr(res, "name"),
    urlkey = map_chr(res, "urlkey"),
    member_count = map_int(res, "member_count"),
    description = map_chr(res, "description"),
    group_count = map_int(res, "group_count"),
    resource = res
  )
}
