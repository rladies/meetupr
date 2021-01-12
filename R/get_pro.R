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
#'    * members
#'    * upcoming_events
#'    * past events
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
#' @importFrom purrr map_int map_chr map_dbl
#' @importFrom tibble tibble
get_pro_groups <- function(urlname, api_key = NULL, verbose = TRUE){

  api_method <- sprintf("pro/%s/groups", urlname)
  res <- .fetch_results(api_method, api_key, verbose = verbose)

  tibble(
    group_sorter(res),
    created = .date_helper(map_dbl(res, "founded_date")),
    members = map_chr(res, "member_count"),
    upcoming_events = map_int(res, "upcoming_events"),
    past_events = map_int(res, "past_events"),
    res = res
  )
}


#' Get the events from a PRO meetup group
#'
#' This can only fetch events for the
#' next 30 days.
#'
#' @template urlname
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
                           api_key = NULL,
                           verbose = TRUE){

  api_method <- sprintf("pro/%s/events", urlname)
  res <- .fetch_results(api_method, api_key, verbose = verbose)

  group <- lapply(res, function(x) x[[3]])
  group <- tibble(group_sorter(group), res = group)
  names(group) <- paste0("group_", names(group))

  events <- lapply(res, function(x) x[[1]])

  tibble(
    event_sorter(events),
    group
  )
}

