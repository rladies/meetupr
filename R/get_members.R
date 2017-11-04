#' Get the current meetup members
#'
#' @template urlname
#' @template api_key
#'
#' @return A tibble with the following columns:
#'    * id
#'    * name
#'    * status
#'    * photo_link
#'    * resource
#' @examples
#' \dontrun{
#' urlname <- "rladies-nashville"
#' members <- get_members(urlname)
#'}
#' @export
get_members <- function(urlname, api_key = NULL){
  api_params <- paste0(urlname, "/members/")
  res <- .fetch_results(api_params, api_key)
  tibble::tibble(
    id = purrr::map_chr(res, "id"),
    name = purrr::map_chr(res, "name"),
    status = purrr::map_chr(res, "status"),
    photo_link = purrr::map_chr(res, c("photo", "photo_link"), .null = NA),
    resource = res
  )
}
