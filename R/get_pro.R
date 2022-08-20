#' #' Meetup pro functions
#' #'
#' #' The pro functions only work if the querying users
#' #' had a meetup pro account.
#' #'
#' #' \describe{
#' #'   \item{get_pro_groups}{Get the current meetup members from a pro meetup group}
#' #'   \item{get_pro_events}{Get pro group events}
#' #' }
#' #'
#' #' @template urlname
#' #'
#' #' @references
#' #' \url{https://www.meetup.com/api/schema/#ProNetwork}
#' #'
#' #' @examples
#' #' \dontrun{
#' #' urlname <- "rladies"
#' #' members <- get_pro_groups(urlname)
#' #'
#' #' past_events <- get_events(urlname = urlname,
#' #'                       status = "PAST")
#' #' upcoming_events <- get_events(urlname = urlname,
#' #'                       status = "UPCOMING")
#' #' all_events <- get_events(urlname = urlname)
#' #'}
#' #'
#' #' @return A tibble with meetup information
#'
#'



#' @rdname meetup_pro
#' @export
#' @return A tibble with the meetup pro group information
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
  )

  dt$created <- anytime::anytime(dt$created)
  dt
}


#' @rdname meetup_pro
#' @export
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
