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
#' @param fields Character, character vector or characters separated by comma (e.g "event_hosts" or c("event_hosts","attendance_count") or "event_hosts, group_past_event_count").
#' @template api_key
#' @template verbose
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
#' past_meetings <- get_events(urlname = urlname,
#'                  event_status = "past",
#'                  fields = "event_hosts", api_key = api_key)
#' # get events hosts (co-organizers) of single past meeting
#' single_event <- past_meetings$resource[[1]]$event_hosts
#'
#' # get all event hosts names (2) and host_counts (6) for that single event
#' # host_counts represents how events the person has co-organized or hosted.
#' do.call("rbind", lapply(single_event, '[', c(2,6)))

#'}
#' @export
get_events <- function(urlname, event_status = "upcoming", fields = NULL,
                       api_key = NULL, verbose = TRUE) {

  event_status <- .check_event_status(event_status)

  res <- .fetch_results(
    sprintf("%s/events", urlname),
    api_key,
    .collapse(event_status),
    fields = .collapse(fields),
    verbose = verbose
  )

  tibble::tibble(
    id = purrr::map_chr(res, "id"),  #this is returned as chr (not int)
    name = purrr::map_chr(res, "name"),
    created = .date_helper(purrr::map_dbl(res, "created", .default = NA)),
    status = purrr::map_chr(res, "status", .default = NA),
    time = .date_helper(purrr::map_dbl(res, "time", .default = NA)),
    local_date = as.Date(purrr::map_chr(res, "local_date", .default = NA)),
    local_time = purrr::map_chr(res, "local_time", .default = NA),
    # TO DO: Add a local_datetime combining the two above?
    waitlist_count = purrr::map_int(res, "waitlist_count"),
    yes_rsvp_count = purrr::map_int(res, "yes_rsvp_count"),
    venue_id = purrr::map_int(res, c("venue", "id"), .default = NA),
    venue_name = purrr::map_chr(res, c("venue", "name"), .default = NA),
    venue_lat = purrr::map_dbl(res, c("venue", "lat"), .default = NA),
    venue_lon = purrr::map_dbl(res, c("venue", "lon"), .default = NA),
    venue_address_1 = purrr::map_chr(res, c("venue", "address_1"), .default = NA),
    venue_city = purrr::map_chr(res, c("venue", "city"), .default = NA),
    venue_state = purrr::map_chr(res, c("venue", "state"), .default = NA),
    venue_zip = purrr::map_chr(res, c("venue", "zip"), .default = NA),
    venue_country = purrr::map_chr(res, c("venue", "country"), .default = NA),
    description = purrr::map_chr(res, c("description"), .default = NA),
    link = purrr::map_chr(res, c("link")),
    resource = res
  )
}
