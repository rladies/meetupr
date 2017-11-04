#' Get the boards from a meetup group
#'
#' @template urlname
#' @template api_key
#' @return A tibble with the following columns:
#'    * id
#'    * name
#'    * n_posts
#'    * boards_resource
#'
#'@examples
#' \dontrun{
#' urlname <- "rladies-nashville"
#' meetup_boards <- get_boards(urlname = urlname,
#'                       api_key = api_key)
#'}
#' @export
get_boards <- function(urlname, api_key) {
  api_params <- paste0(urlname, "/boards")
  res <- .fetch_results(api_params, api_key)
  tibble::tibble(
    id = purrr::map_chr(res, "id"),
    name = purrr::map_chr(res, "name"),
    n_posts = purrr::map_int(res, "post_count"),
    boards_resource = res
  )
}