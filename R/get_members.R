#' Get the current meetup members
#'
#' @template urlname
#' @template api_key
#'
#' @return A tibble with the following columns:
#'    * id
#'    * name
#'    * status
#'    * photo_url
#'    * members_resource
#' @examples
#' \dontrun{
#' urlname <- "rladies-nashville"
#' members <- get_members(urlname)
#'}
#' @export
get_members <- function(urlname, api_key = NULL){
  api_url <- paste0(meetup_api_prefix, urlname, "/members/")
  res <- .fetch_results(api_url, api_key)
  tibble::tibble(
    id = purrr::map_chr(res, "id"),
    name = purrr::map_chr(res, "name"),
    status = purrr::map_chr(res, "status"),
    photo_url = purrr::map_chr(res, c("photo", "photo_link"), .null = NA),
    members_resource = res
  )
}