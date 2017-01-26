#' Get the current meetup members
#'
#' @param urlname The name of the group.
#' @param api_key Your api key.
#'
#' @examples
#' \dontrun{
#' urlname <- "rladies-nashville"
#' api_key <- Sys.getenv("rladies_api_key")
#' members <- get_members(urlname, api_key)
#'}
#' @export
get_members <- function(urlname, api_key){
  api_url <- paste0(urlname, "/members/")
  .fetch_results(api_url, api_key)
}
