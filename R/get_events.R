#' Get the events from a meetup group
#'
#' @param urlname Required urlname of the Meetup group
#' @param ... Should be empty. Used for parameter expansion
#' @param extra_graphql A graphql object. Extra objects to return
#' @param token Meetup token
#' @importFrom dplyr rename select mutate
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

  if("venue_postalCode" %in% names(dt)){
    dt <- dt |>
      dplyr::rename(
        venue_zip = venue_postalCode
      )
  }
  dt |>
    dplyr::rename(
      # created =  createdAt,
      link = eventUrl,
    ) |>
    dplyr::mutate(
      time = anytime::anytime(dateTime),
      venue_country = country_name,
    ) |>
    dplyr::select(-country_name, -dateTime)

}
