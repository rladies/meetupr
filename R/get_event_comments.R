#' Get the comments for a specified event
#'
#' @template urlname
#' @param event_id Character. The id of the event. Event ids can be obtained
#'   using [get_events()] or by looking at the event page URL.
#' @template verbose
#'
#' @return A tibble with the following columns:
#'    * id
#'    * comment
#'    * link
#'    * like_count
#'    * created
#'    * member_id
#'    * member_name
#'    * resource
#' @references
#' \url{https://www.meetup.com/meetup_api/docs/:urlname/events/:event_id/comments/#list}
#' @examples
#' \dontrun{
#' urlname <- "rladies-nashville"
#' past_events <- get_events(urlname = urlname,
#'                       event_status = "past")
#' event_id <- past_events$id[1]  #first event for this group
#' comments <- get_event_comments(urlname, event_id)
#'}
#' @export
get_event_comments <- function(urlname, event_id,
                               verbose = getOption("meetupr.verbose", rlang::is_interactive())) {
  api_path <- sprintf("%s/events/%s/comments",
                        urlname, event_id)
  res <- .fetch_results(api_path = api_path, verbose = verbose)
  tibble::tibble(
    id = purrr::map_int(res, "id"),
    comment = purrr::map_chr(res, "comment"),
    link = purrr::map_chr(res, "link"),
    like_count = purrr::map_int(res, "like_count"),
    created = .date_helper(purrr::map_dbl(res, "created")),
    member_id = purrr::map_int(res, c("member", "id")),
    member_name = purrr::map_chr(res, c("member", "name")),
    resource = res
  )
}

