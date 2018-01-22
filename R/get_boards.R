#' Get the discussion boards from a meetup group
#'
#' @template urlname
#' @template api_key
#' @return A tibble with the following columns:
#'    * id
#'    * name
#'    * description
#'    * created
#'    * updated
#'    * post_count
#'    * discussion_count
#'    * latest_reply_created
#'    * latest_reply_member_name
#'    * resource
#'
#' @references
#' \url{https://www.meetup.com/meetup_api/docs/:urlname/boards/}
#'@examples
#' \dontrun{
#' urlname <- "rladies-nashville"
#' meetup_boards <- get_boards(urlname = urlname,
#'                       api_key = api_key)
#'}
#' @export
get_boards <- function(urlname, api_key) {
  api_method <- paste0(urlname, "/boards")
  res <- .fetch_results(api_method, api_key)
  tibble::tibble(
    id = purrr::map_int(res, "id"),
    name = purrr::map_chr(res, "name"),
    description = purrr::map_chr(res, "description"),
    created = .date_helper(purrr::map_dbl(res, "created")),
    updated = .date_helper(purrr::map_dbl(res, "updated")),
    post_count = purrr::map_int(res, "post_count", .null = NA),
    discussion_count = purrr::map_int(res, "discussion_count", .null = NA),
    latest_reply_created = .date_helper(purrr::map_dbl(res, c("latest_reply", "created"), .null = NA)),
    latest_reply_member_name = purrr::map_chr(res, c("latest_reply", "member", "name"), .null = NA),
    resource = res
  )
}
