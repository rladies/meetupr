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
    id = purrr::map_int(res, "id"),
    name = purrr::map_chr(res, "name", .default = NA),  
    bio = purrr::map_chr(res, "bio", .default = NA),
    status = purrr::map_chr(res, "status"),
    created = .date_helper(purrr::map_dbl(res, c("group_profile", "created"))),
    city = purrr::map_chr(res, "city", .default = NA),
    country = purrr::map_chr(res, "country", .default = NA),
    state = purrr::map_chr(res, "state", .default = NA),
    lat = purrr::map_dbl(res, "lat", .default = NA),
    lon = purrr::map_dbl(res, "lon", .default = NA),
    photo_link = purrr::map_chr(res, c("photo", "photo_link"), .default = NA),
    resource = res
  )
}
