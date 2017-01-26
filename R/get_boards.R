#' Get the boards from a meetup group
#'
#' @param urlname The name of the group.
#' @param api_key Your api key.
#' @return List containing requested events.
#'
#'@examples
#' \dontrun{
#' urlname <- "rladies-nashville"
#' api_key <- Sys.getenv("rladies_api_key")
#' meetup_boards <- get_boards(urlname = urlname,
#'                       api_key = api_key)
#'}
#' @export
get_boards <- function(urlname, api_key) {
  api_params <- paste0(urlname, "/boards")
  .fetch_results(api_params, api_key)
}
