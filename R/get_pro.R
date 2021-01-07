#' Get the current meetup members from a meetup group
#'
#' @template urlname
#' @template api_key
#' @template verbose
#'
#' @return A tibble with the following columns:
#'    * id
#'    * name
#'    * status
#'    * founded
#'    * member_count
#'    * member_count
#'    * upcoming_events
#'    * city
#'    * country
#'    * state
#'    * lat
#'    * lon
#'    * urlname
#' @references
#' \url{https://www.meetup.com/meetup_api/docs/pro/:urlname/groups/}
#' @examples
#' \dontrun{
#' urlname <- "rladies"
#' members <- get_pro_groups(urlname)
#'}
#' @export
get_pro_groups <- function(urlname, api_key = NULL){

  api_method <- sprintf("pro/%s/groups", urlname)
  res <- .fetch_results(api_method, api_key)

  tibble::tibble(
    id = purrr::map_int(res, "id"),
    name = purrr::map_chr(res, "name", .default = NA),
    status = purrr::map_chr(res, "status"),
    founded = .date_helper(purrr::map_dbl(res, "founded_date")),
    member_count = purrr::map_chr(res, "member_count"),
    upcoming_events = purrr::map_int(res, "upcoming_events"),
    past_events = purrr::map_int(res, "past_events"),
    city = purrr::map_chr(res, "city", .default = NA),
    country = purrr::map_chr(res, "country", .default = NA),
    state = purrr::map_chr(res, "state", .default = NA),
    lat = purrr::map_dbl(res, "lat", .default = NA),
    lon = purrr::map_dbl(res, "lon", .default = NA),
    urlname = purrr::map_chr(res, "urlname", .default = NA)
  )
}


#' Get the events from a meetup group
#'
#' @template urlname
#' @param event_status Character (e.g. "upcoming" or "past"). Event type - defaults to "upcoming".
#'  Valid inputs are:
#'  * past
#'  * upcoming
#'
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
#' urlname <- "rladies"
#' past_events <- get_events(urlname = urlname,
#'                       event_status = "past")
#' upcoming_events <- get_events(urlname = urlname,
#'                       event_status = "upcoming")
#'}
#' @export
get_pro_events <- function(urlname,
                           event_status = "upcoming",
                           api_key = NULL,
                           verbose = TRUE){

  event_status <- .check_event_status(event_status)

  event_cols <- paste0(event_status, "_events")

  all_groups <- suppressMessages(
    get_pro_groups(urlname = urlname, api_key = api_key, verbose = verbose)
  )

  # Get groups that have events matching the wanted status, skips those without entries
  groups_event <- unlist(all_groups[all_groups[,event_cols] > 0, "urlname"])

  events <- lapply(groups_event,
                   slowly_get_events,
                   event_status = event_status)

  events <- purrr::map2(events, groups_event,
                        function(.x, .y){
                        x[,"chapter"] <- .y
                        .x}
                        )

  nms <- names(events)[-length(events)]
  events[, c("chapter", nms)]
}
