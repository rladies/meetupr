#' Find meetup groups using text-based search
#'
#' @param text string used to filter groups
#' @param radius can be either "global" (default) or distance in miles in the
#' range 0-100.
#' @template api_key
#'
#' @return A tibble with the following columns:
#'    * id
#'    * name
#'    * urlname
#'    * description
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
#'    * organizer_id
#'    * organizer_name
#'    * category_id
#'    * category_name
#'    * resource
#'
#' @references
#' \url{https://www.meetup.com/meetup_api/docs/find/groups/}
#'@examples
#' \dontrun{
#' api_key <- Sys.getenv("MEETUP_KEY")
#' groups <- find_groups(text = "r-ladies", api_key = api_key)
#'}
#' @export
find_groups <- function(text = NULL, radius = "global", api_key = NULL) {
  api_method <- "find/groups"
  res <- .fetch_results(api_method = api_method,
                        api_key = api_key,
                        text = text,
                        radius = radius)
  tibble::tibble(
    id = purrr::map_int(res, "id"),
    name = purrr::map_chr(res, "name"),
    urlname = purrr::map_chr(res, "urlname"),
    description = purrr::map_chr(res, "description"),
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
    organizer_id = purrr::map_int(res, c("organizer", "id")),
    organizer_name = purrr::map_chr(res, c("organizer", "name")),
    category_id = purrr::map_int(res, c("category", "id"), .null = NA),
    category_name = purrr::map_chr(res, c("category", "name"), .null = NA),
    resource = res
  )
}
