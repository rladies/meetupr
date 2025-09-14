#' Get information about the authenticated user
#'
#' Retrieves detailed information about the currently authenticated Meetup user,
#' including basic profile data, account type,
#' subscription status, and API access permissions.
#'
#' @param extended Logical. Whether to include extended profile fields like bio,
#'   location, and subscription info. Defaults to TRUE.
#' @param check_pro Logical. Whether to test for Pro API access by attempting
#'   a Pro-only query. Defaults to TRUE.
#'
#' @return A list containing user information
#' @export
#' @examples
#' \dontshow{
#' vcr::insert_example_cassette("get_self", package = "meetupr")
#' meetupr:::mock_if_no_auth()
#' }
#' user <- get_self()
#' cat("Hello", user$name, "!")
#'
#' # Extended profile info
#' user <- get_self(extended = TRUE)
#'
#' # Skip pro access check for faster response
#' user <- get_self(check_pro = FALSE)
#' \dontshow{
#' vcr::eject_cassette()
#' }
get_self <- function(extended = TRUE, check_pro = TRUE) {
  execute(
    self_query(
      extended = extended,
      check_pro = check_pro
    ),
    extended = extended,
    extra_graphql = NULL
  )
}

extract_location_info <- function(user_data, extended) {
  if (!extended) {
    return(NULL)
  }

  list(
    city = user_data$city,
    state = user_data$state,
    country = user_data$country,
    lat = user_data$lat,
    lon = user_data$lon
  )
}

extract_profile_info <- function(user_data, extended) {
  if (!extended) {
    return(NULL)
  }

  list(
    bio = user_data$bio,
    member_url = user_data$memberUrl,
    join_time = user_data$startDate,
    preferred_locale = user_data$preferredLocale
  )
}

determine_pro_status <- function(user_data, check_pro) {
  if (!check_pro) {
    return(NA)
  }

  has_pro_organizer <- user_data$isProOrganizer %||% FALSE
  has_admin_networks <- !is.null(user_data$adminProNetworks) &&
    length(user_data$adminProNetworks) > 0

  has_pro_organizer || has_admin_networks
}

#' @export
print.meetup_user <- function(x, ...) {
  cli::cli_h2("Meetup User:")
  cli::cli_li("ID: {x$id}")
  cli::cli_li("Name: {x$name}")
  if (!is.null(x$email)) {
    cli::cli_li("Email: {x$email}")
  }

  cli::cli_h3("Roles:")
  cli::cli_li("Organizer: {ifelse(x$is_organizer, 'Yes', 'No')}")
  cli::cli_li("Leader: {ifelse(x$is_leader, 'Yes', 'No')}")
  cli::cli_li("Pro Organizer: {ifelse(x$is_pro_organizer, 'Yes', 'No')}")
  cli::cli_li("Member Plus: {ifelse(x$is_member_plus_subscriber, 'Yes', 'No')}")

  if (!is.na(x$has_pro_access)) {
    cli::cli_li("Pro API Access: {ifelse(x$has_pro_access, 'Yes', 'No')}")
  }

  if (!is.null(x$location)) {
    cli::cli_h3("Location:")
    if (!is.null(x$location$city)) {
      cli::cli_li("City: {x$location$city}")
    }
    if (!is.null(x$location$country)) {
      cli::cli_li("Country: {x$location$country}")
    }
  }

  invisible(x)
}

# Self query (special case - no pagination)
self_query <- function(extended = TRUE, check_pro = TRUE) {
  MeetupQuery(
    template = "get_self",
    pagination = function(x, ...) NULL,
    extract = function(x) list(x$data$self),
    process_data = function(data, ...) {
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
