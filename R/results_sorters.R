# For use when getting events,
# makes sure all events callers return the same
#' @importFrom purrr map_chr map_dbl map_int
#' @importFrom tibble tibble
event_sorter <- function(x){
  tibble(
    id = map_chr(x, "id"),  #this is returned as chr (not int)
    name = map_chr(x, "name"),
    created = .date_helper(map_dbl(x, "created", .default = NA)),
    status = map_chr(x, "status", .default = NA),
    time = .date_helper(map_dbl(x, "time", .default = NA)),
    local_date = as.Date(map_chr(x, "local_date", .default = NA)),
    duration = map_int(x, "duration", .default = NA),
    local_time = map_chr(x, "local_time", .default = NA),
    # TO DO: Add a local_datetime combining the two above?
    waitlist_count = map_int(x, "waitlist_count"),
    yes_rsvp_count = map_int(x, "yes_rsvp_count"),
    venue_id = map_int(x, c("venue", "id"), .default = NA),
    venue_name = map_chr(x, c("venue", "name"), .default = NA),
    venue_lat = map_dbl(x, c("venue", "lat"), .default = NA),
    venue_lon = map_dbl(x, c("venue", "lon"), .default = NA),
    venue_address_1 = map_chr(x, c("venue", "address_1"), .default = NA),
    venue_city = map_chr(x, c("venue", "city"), .default = NA),
    venue_state = map_chr(x, c("venue", "state"), .default = NA),
    venue_zip = map_chr(x, c("venue", "zip"), .default = NA),
    venue_country = map_chr(x, c("venue", "country"), .default = NA),
    description = map_chr(x, c("description"), .default = NA),
    link = map_chr(x, c("link")),
    resource = x
  )
}

# For use when getting group information,
# makes sure all events callers return the same
# different group requests give different outputs
# so only a helper for some of the information
#' @importFrom purrr map_chr map_dbl map_int
#' @importFrom tibble tibble
group_sorter <- function(x){
  tibble::tibble(
    id = purrr::map_int(x, "id"),
    name = purrr::map_chr(x, "name"),
    urlname = purrr::map_chr(x, "urlname"),
    status = purrr::map_chr(x, "status"),
    lat = purrr::map_dbl(x, "lat"),
    lon = purrr::map_dbl(x, "lon"),
    city = purrr::map_chr(x, "city"),
    state = purrr::map_chr(x, "state", .default = NA),
    country = purrr::map_chr(x, "country")
  )
}

