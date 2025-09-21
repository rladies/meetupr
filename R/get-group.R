#' Get the members from a meetup group
#'
#' @template urlname
#' @param max_results Maximum number of results to return. Default: 200
#' @param ... Should be empty. Used for parameter expansion
#' @template max_results
#' @template handle_multiples
#' @template extra_graphql
#' @return A tibble with group members
#' @export
#' @examples
#' \dontshow{
#' vcr::insert_example_cassette("get_group_members", package = "meetupr")
#' meetupr:::mock_if_no_auth()
#' }
#' get_group_members("rladies-lagos")
#' \dontshow{
#' vcr::eject_cassette()
#' }
get_group_members <- function(
  urlname,
  max_results = NULL,
  handle_multiples = "list",
  extra_graphql = NULL,
  ...
) {
  rlang::check_dots_empty()

  execute(
    standard_query(
      "get_group_members",
      "data.groupByUrlname.memberships"
    ),
    urlname = urlname,
    first = max_results,
    max_results = max_results,
    handle_multiples = handle_multiples,
    extra_graphql = extra_graphql
  )
}

#' Get detailed information about a Meetup group
#'
#' @param urlname The URL name of the Meetup group (e.g., "rladies-lagos")
#' @return A list containing detailed information about the Meetup group
#' @export
#' @examples
#' \dontshow{
#' vcr::insert_example_cassette("get_group", package = "meetupr")
#' meetupr:::mock_if_no_auth()
#' }
#' get_group("rladies-lagos")
#' \dontshow{
#' vcr::eject_cassette()
#' }
get_group <- function(urlname) {
  execute(
    meetup_template_query(
      template = "get_group",
      page_info_path = ".pageInfo",
      edges_path = "data.groupByUrlname",
      process_data = process_group_data
    ),
    urlname = urlname,
    first = NULL,
    max_results = NULL,
    handle_multiples = "list"
  )
}

#' Process Group Data
#' @param data The raw data returned from the API
#' @param ... Additional arguments (not used)
#' @return A structured list representing the Meetup group
#' @keywords internal
#' @noRd
process_group_data <- function(data, ...) {
  if (length(data) == 0 || is.null(data)) {
    cli::cli_abort("No group data returned")
  }

  structure(
    list(
      id = data$id,
      name = data$name,
      description = data$description,
      urlname = data$urlname,
      link = data$link,
      location = extract_group_location(data),
      timezone = data$timezone,
      created = fix_datetime(data$foundedDate),
      members = data$stats$memberCounts$all,
      total_events = data$events$totalCount,
      organizer = extract_organizer_info(data$organizer),
      category = extract_category_info(data$topicCategory),
      photo_url = data$keyGroupPhoto$baseUrl
    ),
    class = c("meetup_group", "list")
  )
}

#' Extract Group Location
#' @param data The raw group data
#' @return A list with city and country
#' @keywords internal
#' @noRd
extract_group_location <- function(data) {
  list(
    city = data$city,
    country = data$country
  )
}

#' Extract Organizer Information
#' @param organizer_data The raw organizer data
#' @return A list with organizer id and name
#' @keywords internal
#' @noRd
extract_organizer_info <- function(organizer_data) {
  if (is.null(organizer_data)) {
    return(NULL)
  }

  list(
    id = organizer_data$id,
    name = organizer_data$name
  )
}

#' Extract Category Information
#' @param category_data The raw category data
#' @return A list with category id and name
#' @keywords internal
#' @noRd
extract_category_info <- function(category_data) {
  if (is.null(category_data)) {
    return(NULL)
  }

  list(
    id = category_data$id,
    name = category_data$name
  )
}

#' @export
print.meetup_group <- function(x, ...) {
  cli::cli_h2("Meetup Group:")
  cli::cli_li("Name: {x$name}")
  cli::cli_li("URL: {x$urlname}")
  cli::cli_li("Link: {x$link}")

  if (!is.null(x$location)) {
    location_parts <- c(x$location$city, x$location$country)
    location_str <- paste(stats::na.omit(location_parts), collapse = ", ")
    if (nzchar(location_str)) {
      cli::cli_li("Location: {location_str}")
    }
  }

  cli::cli_li("Timezone: {x$timezone}")
  cli::cli_li("Founded: {format(x$created, '%B %d, %Y')}")

  cli::cli_h3("Statistics:")
  cli::cli_li("Members: {scales::comma(x$members)}")
  cli::cli_li("Total Events: {scales::comma(x$total_events)}")

  if (!is.null(x$organizer)) {
    cli::cli_h3("Organizer:")
    cli::cli_li("Name: {x$organizer$name}")
  }

  if (!is.null(x$category)) {
    cli::cli_li("Category: {x$category$name}")
  }

  if (!is.null(x$description) && nzchar(x$description)) {
    cli::cli_h3("Description:")
    desc_clean <- gsub("<[^>]*>", "", x$description)
    desc_truncated <- if (is.na(desc_clean) || nchar(desc_clean) == 0) {
      "No description available."
    } else if (nchar(desc_clean) > 200) {
      paste0(substr(desc_clean, 1, 197), "...")
    } else {
      desc_clean
    }
    cli::cli_text(desc_truncated)
  }

  invisible(x)
}
