#' Get the events from a meetup group
#'
#' @param urlname Required urlname of the Meetup group
#' @param ... Should be empty. Used for parameter expansion
#' @param extra_graphql A graphql object. Extra objects to return
#' @param token Meetup token
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

  # replace dot with underscore
  names(dt) <- gsub("\\.", "_", names(dt))

  dt <- rename(dt,
      # created =  createdAt,
      link = eventUrl,
      venue_zip = venue_postalCode
    )

  dt$time <- anytime::anytime(dt$dateTime)
  dt$venue_country <- dt$country_name

  remove(dt,
         country_name,
         dateTime)

}
