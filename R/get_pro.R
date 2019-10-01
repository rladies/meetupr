#' Get the groups under a meetup pro organisation
#'
#' @template urlname
#' @template api_key
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

  api_method <- paste0("/pro/", urlname, "/groups/")
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


#' Get the events from a meetup pro group
#'
#' @template urlname
#' @param event_status Character (e.g. "upcoming" or "past"). Event type - defaults to "upcoming".
#'  Valid inputs are:
#'  * past
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
#' urlname <- "rladies"
#' past_events <- get_events(urlname = urlname,
#'                       event_status = "past")
#' upcoming_events <- get_events(urlname = urlname,
#'                       event_status = "upcoming")
#'}
#' @export
#' @importFrom dplyr bind_rows
get_pro_events <- function(urlname,
                           event_status = "upcoming",
                           api_key = NULL){

  if (!is.null(event_status) &&
      !event_status %in% c("past", "upcoming")) {
    stop(sprintf("Event status %s not allowed", event_status))
  }

  col <- paste0(event_status, "_events")

  all_groups <- suppressMessages(
    get_pro_groups(urlname = urlname, api_key = api_key)
  )

  # Get groups that have events matching the wanted status, skips those without entries
  groups_event <- unlist(all_groups[all_groups[,col] > 0, "urlname"])

  pbtxt <- txtProgressBar(1, length(groups_event), style = 3)

  # Do this in a loop rather than map/apply,
  # in order to keep the sleep, or else will
  # HTTP 429 from too many requests
  events = list()
  for( i  in 1:length(groups_event)){
    suppressMessages(
      events[[i]] <- get_events(groups_event[i],
           event_status = event_status,
           api_key = api_key)
    )
    setTxtProgressBar(pbtxt, i)

    # Add a small sleep to not overcrowd too fast
    Sys.sleep(.1)
  }

  names(events) = groups_event

  dplyr::bind_rows(events,
                   .id="chapter")
}
