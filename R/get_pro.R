#' Meetup pro functions
#'
#' The pro functions only work if the querying users
#' had a meetup pro account.
#'
#' @template urlname
#' @param ... Should be empty. Used for parameter expansion
#' @template extra_graphql
#' @template token
#' @param status Which status the events should have.
#'
#' @references
#' \url{https://www.meetup.com/api/schema/#ProNetwork}
#'
#' @examples
#' \dontrun{
#' urlname <- "rladies"
#' members <- get_pro_groups(urlname)
#'
#' past_events <- get_pro_events(urlname = urlname,
#'                       status = "PAST")
#' upcoming_events <- get_pro_events(urlname = urlname,
#'                       status = "UPCOMING")
#' all_events <- get_pro_events(urlname = urlname)
#' }
#' @name meetup_pro
#' @return A tibble with meetup pro information
NULL

#' Get pro groups information
#' @export
#' @describeIn meetup_pro retrieve groups in a pro network
get_pro_groups <- function(
  urlname,
  ...,
  extra_graphql = NULL,
  token = meetup_token()
) {
  ellipsis::check_dots_empty()

  dt <- gql_get_pro_groups(
    urlname = urlname,
    .extra_graphql = extra_graphql,
    .token = token
  )
  dt <- rename(dt,
               created = foundedDate,
               members = memberships.count,
               join_mode = joinMode,
               category_id = category.id,
               category_name = category.name,
               country = country_name,
               past_events_count = pastEvents.count,
               upcoming_events_count = upcomingEvents.count,
               membership_status = membershipMetadata.status,
               is_private = isPrivate

  )

  dt$created <- anytime::anytime(dt$created)
  dt
}

#' Get pro events information
#' @export
#' @describeIn meetup_pro retrieve events from a pro network
get_pro_events <- function(
  urlname,
  status = NULL,
  ...,
  extra_graphql = NULL,
  token = meetup_token()
) {
  ellipsis::check_dots_empty()

  dt <- gql_get_pro_events(
    urlname = urlname,
    status = status,
    .extra_graphql = extra_graphql,
    .token = token
  )
  if(nrow(dt) == 0) return(NULL)

  # replace dot with underscore
  names(dt) <- gsub("\\.", "_", names(dt))

  dt <- rename(dt,
               link = eventUrl,
               event_type = eventType,
               venue_zip = venue_postalCode
  )
  dt$time <- anytime::anytime(dt$dateTime)

  remove(dt,
         dateTime)
}
