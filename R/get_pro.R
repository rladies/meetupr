#' Get the groups under a meetup pro organisation
#'
#' @template urlname
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
get_pro_groups <- function(urlname){

  api_method <- paste0("/pro/", urlname, "/groups/")
  res <- .fetch_results(api_method)

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


#' Get the events from a meetup pro group
#'
#' @template urlname
#' @param event_status Character (e.g. "upcoming" or "past"). Event type - defaults to "upcoming".
#'  Valid inputs are:
#'  * past
#'  * upcoming
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
# past_events <- get_pro_events(urlname = urlname,
#                       event_status = "past")
#' upcoming_events <- get_pro_events(urlname = urlname,
#'                       event_status = "upcoming")
#'}
#' @export
get_pro_events <- function(urlname,
                           event_status = "upcoming"){

  if (!is.null(event_status) &&
      !event_status %in% c("past", "upcoming")) {
    stop(sprintf("Event status %s not allowed", event_status))
  }

  col <- paste0(event_status, "_events")

  all_groups <- suppressMessages(
    get_pro_groups(urlname = urlname)
  )

  # Get groups that have events matching the wanted status, skips those without entries
  groups_event <- unlist(all_groups[all_groups[,col] > 0, "urlname"])

  # slowly to avoid
  # HTTP 429 from too many requests
  events <- lapply(groups_event,
         slowly_get_events,
         event_status = event_status)

  # add chapter names to df
  events <- purrr::map2(events, groups_event,
              function(.x, .y){
                .x[,"chapter"] <- .y
                .x
              })

  events <- do.call(rbind, events)

  # Alter so that chapter column is first
  nms <- names(events)[-length(events)]
  events[, c("chapter", nms)]

}

#' to avoid making too many
#' requests too rapidly when
#' getting pro events
#' @param ... arguments to get_events
slowly_get_events <- purrr::slowly(
  get_events,
  rate = purrr::rate_delay(pause = .3,
                           max_times = Inf)
)
