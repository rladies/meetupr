#' Post the attendance for a specified event
#'
#' @template urlname
#' @param event_id Character. The id of the event. Event ids can be obtained
#'   using [get_events()] or by looking at the event page URL.
#' @param member_id Integer. The id of the member(s). Can be obtained using
#'   [get_event_rsvps()]. Can accept multiple members using \code{c()}.
#' @param status Character. Must be one of 'noshow', 'absent', 'attended'.
#' @template api_key
#'
#' @return NULL
#'
#' @references
#' \url{https://www.meetup.com/meetup_api/docs/:urlname/events/:id/attendance/#edit}
#'
#' @export
post_event_attendance <- function(urlname, event_id, member_id, status,
                                  api_key = NULL) {

  if(length(member_id > 1)) {
    tmp <- member_id
    member_id <- paste(tmp, collapse = ",")
  }

  api_method <- paste0(urlname, "/events/", event_id, "/attendance")
  meetup_api_prefix <- "https://api.meetup.com/"
  api_url <- paste0(meetup_api_prefix, api_method)

  # Get the API key from MEETUP_KEY environment variable if NULL
  if (is.null(api_key)) api_key <- .get_api_key()
  if (!is.character(api_key)) stop("api_key must be a character string")

  # list of parameters
  parameters <- list(key = api_key,         # your api_key
                     member = member_id,    # member(s) to update
                     status = status  # attendance status
  )

  req <- httr::POST(url = api_url,          # the endpoint
                    query = parameters)

  httr::stop_for_status(req)
  reslist <- httr::content(req, "parsed")

  if (length(reslist) == 0) {
    stop("It looks like your update did not work :(\n",
         call. = FALSE)
  }

  message(reslist)
}
