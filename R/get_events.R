#' Get the events from a meetup group
#'
#' @template urlname
#' @param event_status Character or character vector (e.g. "upcoming" or c("past", "upcoming")). Event type - defaults to "upcoming".
#'  Valid inputs are:
#'  * cancelled
#'  * draft
#'  * past
#'  * proposed
#'  * suggested
#'  * upcoming
#'
#' @template api_key
#'
#' @return A tibble with the following columns:
#'    * id
#'    * name
#'    * created
#'    * status
#'    * time
#'    * local_date
#'    * local_time
#'    * waitlist_count
#'    * yes_rsvp_count
#'    * venue_id
#'    * venue_name
#'    * venue_lat
#'    * venue_lon
#'    * venue_address_1
#'    * venue_city
#'    * venue_state
#'    * venue_zip
#'    * venue_country
#'    * description
#'    * link
#'    * resource
#'
#' @references
#' \url{https://www.meetup.com/meetup_api/docs/:urlname/events/#list}
#'@examples
#' \dontrun{
#' urlname <- "rladies-nashville"
#' past_events <- get_events(urlname = urlname,
#'                       event_status = "past")
#' upcoming_events <- get_events(urlname = urlname,
#'                       event_status = "upcoming")
#'}
#' @export
get_events <- function(urlname, event_status = "upcoming", api_key = NULL) {
  if (!is.null(event_status) &&
     !event_status %in% c("cancelled", "draft", "past", "proposed", "suggested", "upcoming")) {
    stop(sprintf("Event status %s not allowed", event_status))
  }
  # If event_status contains multiple statuses, we can pass along a comma sep list
  if (length(event_status) > 1) {
    event_status <- paste(event_status, collapse = ",")
  }
  api_method <- paste0(urlname, "/events")
  res <- .fetch_results(api_method, api_key, event_status)
  tibble::tibble(
    id = purrr::map_chr(res, "id"),  #this is returned as chr (not int)
    name = purrr::map_chr(res, "name"),
    created = .date_helper(purrr::map_dbl(res, "created", .default = NA)),
    status = purrr::map_chr(res, "status", .default = NA),
    time = .date_helper(purrr::map_dbl(res, "time", .default = NA)),
    local_date = as.Date(purrr::map_chr(res, "local_date", .default = NA)),
    local_time = purrr::map_chr(res, "local_time", .null = NA),
    # TO DO: Add a local_datetime combining the two above?
    waitlist_count = purrr::map_int(res, "waitlist_count"),
    yes_rsvp_count = purrr::map_int(res, "yes_rsvp_count"),
    venue_id = purrr::map_int(res, c("venue", "id"), .null = NA),
    venue_name = purrr::map_chr(res, c("venue", "name"), .null = NA),
    venue_lat = purrr::map_dbl(res, c("venue", "lat"), .null = NA),
    venue_lon = purrr::map_dbl(res, c("venue", "lon"), .null = NA),
    venue_address_1 = purrr::map_chr(res, c("venue", "address_1"), .null = NA),
    venue_city = purrr::map_chr(res, c("venue", "city"), .null = NA),
    venue_state = purrr::map_chr(res, c("venue", "state"), .null = NA),
    venue_zip = purrr::map_chr(res, c("venue", "zip"), .null = NA),
    venue_country = purrr::map_chr(res, c("venue", "country"), .null = NA),
    description = purrr::map_chr(res, c("description"), .null = NA),
    link = purrr::map_chr(res, c("link")),
    resource = res
  )
}
