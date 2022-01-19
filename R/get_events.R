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
#'                  fields = "event_hosts")
#' # get events hosts (co-organizers) of single past meeting
#' single_event <- past_meetings$resource[[1]]$event_hosts
#'
#' # get all event hosts names (2) and host_counts (6) for that single event
#' # host_counts represents how events the person has co-organized or hosted.
#' do.call("rbind", lapply(single_event, '[', c(2,6)))

#'}
#' @export
get_events <- function(urlname,
                       event_status = c("upcoming", "cancelled", "draft", "past", "proposed", "suggested"),
                       fields = NULL,
                       verbose = meetupr_verbose()) {

  match.arg(event_status)
  res <- .fetch_results(
    sprintf("%s/events", urlname),
    .collapse(event_status),
    fields = .collapse(fields),
    verbose = verbose
  )

  event_sorter(res)
}


# Contains all events. Look at `status` field to see type
get_events2 <- function(
  urlname,
  ...,
  extra_graphql = NULL,
  token = meetup_token()
) {
  ellipsis::check_dots_empty()

  dt <- gql_events(
    urlname = urlname,
    .extra_graphql = extra_graphql,
    .token = token
  )

  dt %>%
    dplyr::rename(
      venue_id = .data$venue.id,
      venue_name = .data$venue.name,
      venue_lat = .data$venue.lat,
      venue_lon = .data$venue.lon,
      venue_address = .data$venue.address,
      venue_city = .data$venue.city,
      venue_state = .data$venue.state,
      venue_zip = .data$venue.postalCode,
      venue_country = .data$country_name,
      # created =  .data$createdAt,
      time = .data$dateTime,
      link = .data$eventUrl,
    ) %>%
    dplyr::mutate(
      venue.country = NULL, # drop
      time = anytime::anytime(.data$time)
    )

}
