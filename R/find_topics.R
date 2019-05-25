#' Find meetup groups matching a search query
#'
#' @param text Character. Raw full text search query.
#' @param topic_id  Integer. Meetup.com topic ID.
#' @param radius can be either "global" (default) or distance in miles in the
#' range 0-100.
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
#' groups <- find_groups(text = "r-ladies", api_key = api_key)
#'}
#' @export

# install.packages("devtools")
# devtools::install_github("rladies/meetupr")

urlname <- "rladies-san-francisco"
m<-get_members(urlname, api_key = MEETUP_KEY)

events <- get_events(urlname, "past", api_key = MEETUP_KEY)
dplyr::arrange(events, desc(created))


find_topics <- function(searchText = NULL, radius = "global", api_key = NULL) {
  api_method <- "find/topics"
  res <- .fetch_results(api_method = api_method,
                        api_key = api_key,
                        query = searchText)
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
