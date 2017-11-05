#' Get list of meetup groups using text-based search
#'
#' @param text string used to filter groups
#' @param radius can be either "global" (default) or distance in miles in the
#' range 0-100.
#' @template api_key
#'
#' @return Tibble containing the list of selected groups. The table contains 12
#' columns: name, urlname, who, members, status, created, organizer, lat, lon,
#' city, country, timezone.
#'
#'@examples
#' \dontrun{
#' api_key <- Sys.getenv("rladies_api_key")
#' groups <- get_groups(text = "r-ladies", api_key = api_key)
#'}
#' @export
get_groups <- function(text = NULL, radius = "global", api_key = NULL) {
  api_params <- "find/groups"
  res <- .fetch_results(api_params = api_params,
                        api_key = api_key,
                        text = text,
                        radius = radius)
  tibble::tibble(
    name = purrr::map_chr(res, "name"),
    urlname = purrr::map_chr(res, "urlname"),
    who = purrr::map_chr(res, "who"),
    members = purrr::map_int(res, "members"),
    status = purrr::map_chr(res, "status"),
    created = purrr::map_chr(res, "created"),
    organizer = purrr::map_chr(res, c("organizer", "name")),
    lat = purrr::map_dbl(res, "lat"),
    lon = purrr::map_dbl(res, "lon"),
    city = purrr::map_chr(res, "city"),
    country = purrr::map_chr(res, "country"),
    timezone = purrr::map_chr(res, "timezone")
  )
}
