#' Get the comments for a specified event
#'
#' @template urlname
#' @param event_id Character. The id of the event. Event id's can be obtained
#'   using [get_events()].
#' @template api_key
#'
#' @return A tibble with the following columns:
#'    * id
#'    * comment
#'    * like_count
#'    * created
#'    * member_id
#'    * member_name
#'    * resource
#' @examples
#' \dontrun{
#' urlname <- "rladies-nashville"
#' past_events <- get_events(urlname = urlname,
#'                       event_status = "past")
#' event_id <- past_events$id[1]
#' comments <- get_comments(urlname, event_id)
#'}
#' @export
get_comments <- function(urlname, event_id, api_key = NULL){
  api_params <- paste0(urlname, "/events/", event_id, "/comments")
  res <- .fetch_results(api_params, api_key)
  tibble::tibble(
    id = purrr::map_chr(res, "id"),
    comment = purrr::map_chr(res, "comment"),
    like_count = purrr::map_int(res, "like_count"),
    created = .date_helper(purrr::map_dbl(res, "created")),
    member_id = purrr::map_chr(res, c("member", "id")),
    member_name = purrr::map_chr(res, c("member", "name")),
    resource = res
  )
}

