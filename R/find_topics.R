#' Find meetup topic IDs matching a text search query
#'
#' @param text Character. Raw full text search query.
#' @template api_key
#'
#' @return A tibble with the following columns:
#'    * id
#'    * name
#'    * urlkey
#'    * description
#'    * member_count
#'    * group_count
#'    * resource
#'
#' @references
#' \url{https://www.meetup.com/meetup_api/docs/find/groups/}
#' \url{https://www.meetup.com/meetup_api/docs/find/topics/}
#'@examples
#' \dontrun{
#' api_key <- Sys.getenv("MEETUP_KEY")
#' topics <- find_topics(text = "R-Ladies", api_key = api_key)
#' # Note that R-Ladies has topic id 1513883
#' groups <- find_groups(topic_id = 1513883, api_key = api_key)
#'}
#' @export
find_topics <- function(text = NULL, api_key = NULL) {
  api_method <- "find/topics"
  res <- .fetch_results(api_method = api_method, api_key = api_key, query = text)
  tibble::tibble(
    id = purrr::map_int(res, "id"),
    name = purrr::map_chr(res, "name"),
    urlkey = purrr::map_chr(res, "urlkey"),
    member_count = purrr::map_int(res, "member_count"),
    description = purrr::map_chr(res, "description"),
    group_count = purrr::map_int(res, "group_count"),
    resource = res
  )
}
