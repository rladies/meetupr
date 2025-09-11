#' Clean Query Definitions Using Shared Infrastructure
#' This file completely replaces the existing R/meetup-query.R
#' @keywords internal

# Event queries
events_query <- create_event_query("get_events")

# RSVP queries
event_rsvps_query <- create_rsvp_query("get_events_rsvps")

event_attendees_query <- create_rsvp_query("get_event_attendees")
event_attendees_query@finalizer_fn <- process_attendees_data

# Member queries with max_results parameter
members_query <- function(max_results) {
  create_members_query(max_results)
}

# Group search with max_results parameter
find_groups_query <- function(max_results) {
  create_groups_search_query(max_results)
}

# Pro network queries with optional max_results
pro_groups_query <- function(max_results = NULL) {
  create_pro_query(
    "get_pro_groups",
    "groupsSearch",
    process_pro_group_data,
    max_results
  )
}

pro_events_query <- function(max_results = NULL) {
  create_pro_query(
    "get_pro_events",
    "eventsSearch",
    process_pro_event_data,
    max_results
  )
}

# Self query (special case - no pagination)
self_query <- function(extended = TRUE, check_pro = TRUE) {
  MeetupQuery(
    template = "get_self",
    cursor_fn = function(x) NULL,
    total_fn = function(x) 1L,
    extract_fn = function(x) list(x$data$self),
    finalizer_fn = function(data) {
      if (length(data) == 0 || is.null(data[[1]])) {
        cli::cli_abort("No user data returned from self query")
      }

      user_data <- data[[1]]
      pro_status <- determine_pro_status(user_data, check_pro)

      structure(
        list(
          id = user_data$id,
          name = user_data$name,
          email = user_data$email,
          is_organizer = user_data$isOrganizer %||% FALSE,
          is_leader = user_data$isLeader %||% FALSE,
          is_member_plus_subscriber = user_data$isMemberPlusSubscriber %||%
            FALSE,
          is_pro_organizer = user_data$isProOrganizer %||% FALSE,
          has_pro_access = pro_status,
          location = extract_location_info(user_data, extended),
          profile = extract_profile_info(user_data, extended),
          raw = user_data
        ),
        class = "meetup_user"
      )
    }
  )
}
