#' Get the current meetup members from a meetup group
#'
#' @template urlname
#' @template api_key
#'
#' @return A tibble with the following columns:
#'    * id
#'    * name
#'    * bio
#'    * status
#'    * joined
#'    * city
#'    * country
#'    * state
#'    * lat
#'    * lon
#'    * photo_link
#'    * resource
#' @references
#' \url{https://www.meetup.com/meetup_api/docs/:urlname/members/#list}
#' @examples
#' \dontrun{
#' urlname <- "rladies-nashville"
#' members <- get_members(urlname)
#'}
#' @export
get_members <- function(urlname, api_key = NULL){
  api_method <- paste0(urlname, "/members/")
  res <- .fetch_results(api_method, api_key)
  tibble::tibble(
    id = purrr::map_chr(res, "id"),
    name = purrr::map_chr(res, "name", .null = NA),
    bio = purrr::map_chr(res, "bio", .null = NA),
    status = purrr::map_chr(res, "status"),
    joined = .date_helper(purrr::map_dbl(res, "joined")),
    city = purrr::map_chr(res, "city", .null = NA),
    country = purrr::map_chr(res, "country", .null = NA),
    state = purrr::map_chr(res, "state", .null = NA),
    lat = purrr::map_chr(res, "lat", .null = NA),
    lon = purrr::map_chr(res, "lon", .null = NA),
    photo_link = purrr::map_chr(res, c("photo", "photo_link"), .null = NA),
    resource = res
  )
}
