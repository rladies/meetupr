#' Get information about the authenticated user
#'
#' Retrieves detailed information about the currently authenticated Meetup user,
#' including basic profile data, account type,
#' subscription status, and API access permissions.
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
#' \dontshow{
#' vcr::eject_cassette()
#' }
get_self <- function() {
  execute(
    meetup_template_query(
      "get_self",
      "",
      "data.self",
      process_data = process_self_data
    ),
    extra_graphql = NULL
  )
}

#' Extract Location Information
#' @keywords internal
#' @noRd
extract_location_info <- function(user_data) {
  list(
    city = user_data$city,
    state = user_data$state,
    country = user_data$country,
    lat = user_data$lat,
    lon = user_data$lon
  )
}

#' Extract Profile Information
#' @keywords internal
#' @noRd
extract_profile_info <- function(user_data) {
  list(
    bio = user_data$bio,
    member_url = user_data$memberUrl,
    join_time = user_data$startDate,
    preferred_locale = user_data$preferredLocale
  )
}

#' Determine Pro Status
#' @keywords internal
#' @noRd
determine_pro_status <- function(user_data) {
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


#' Self query template
#' @keywords internal
#' @noRd
process_self_data <- function(data, ...) {
  if (length(data) == 0 || is.null(data[[1]])) {
    cli::cli_abort("No user data returned from self query")
  }
  pro_status <- determine_pro_status(data)

  structure(
    list(
      id = data$id,
      name = data$name,
      email = data$email,
      is_organizer = data$isOrganizer %||% FALSE,
      is_leader = data$isLeader %||% FALSE,
      is_member_plus_subscriber = data$isMemberPlusSubscriber %||%
        FALSE,
      is_pro_organizer = data$isProOrganizer %||% FALSE,
      has_pro_access = pro_status,
      location = extract_location_info(data),
      profile = extract_profile_info(data),
      raw = data
    ),
    class = c("meetup_user", "list")
  )
}
