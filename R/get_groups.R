#' Get list of meetup groups using text-based search
#'
#' @param api_key Your api key.
#' @param ... any parameter listed in meetup API (\url{https://www.meetup.com/meetup_api/docs/find/groups/})
#' @return List containing relevant groups.
#'
#'@examples
#' \dontrun{
#' api_key <- Sys.getenv("rladies_api_key")
#' groups <- get_groups(api_key = api_key,
#'                      sign   = "true",
#'                      text = "r-ladies",
#'                      radius = "global",
#'                      only = "urlname")
#' rladies_groups <- as.character(unlist(groups))
#'}
#' @export
get_groups <- function(api_key, ...) {
  api_params <- "find/groups"
  .fetch_results(api_params, api_key, ...)
}
