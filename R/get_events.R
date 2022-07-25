#' Get the events from a meetup group
#'
#' @param urlname Required urlname of the Meetup group
#' @param ... Should be empty. Used for parameter expansion
#' @param extra_graphql A graphql object. Extra objects to return
#' @param token Meetup token
#' @importFrom dplyr %>%
#' @export
get_events <- function(
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
  if(nrow(dt) == 0) return(NULL)

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
