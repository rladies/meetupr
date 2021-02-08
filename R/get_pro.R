#' Meetup pro functions
#'
#' The pro functions only work if the querying users
#' had a meetup pro account.
#'
#' \describe{
#'   \item{get_pro_groups}{Get the current meetup members from a pro meetup group}
#'   \item{get_pro_events}{Get pro group events for the enxt 30 days}
#' }
#'
#' @template urlname
#' @template verbose
#'
#' @references
#' \url{https://www.meetup.com/meetup_api/docs/pro/:urlname/groups/}
#' \url{https://www.meetup.com/meetup_api/docs/:urlname/events/#list}
#'
#' @examples
#' \dontrun{
#' urlname <- "rladies"
#' members <- get_pro_groups(urlname)
#'
#' past_events <- get_events(urlname = urlname,
#'                       event_status = "past")
#' upcoming_events <- get_events(urlname = urlname,
#'                       event_status = "upcoming")
#'}
#'
#' @return A tibble with meetup information


#' @rdname meetup_pro
#' @export
#' @importFrom purrr map_int map_chr map_dbl
#' @importFrom tibble tibble
get_pro_groups <- function(urlname,
                           verbose = getOption("meetupr.verbose", rlang::is_interactive())){

  api_path <- sprintf("pro/%s/groups", urlname)
  res <- .fetch_results(api_path = api_path, verbose = verbose)

  tibble(
    group_sorter(res),
    created = .date_helper(map_dbl(res, "founded_date")),
    members = map_chr(res, "member_count"),
    upcoming_events = map_int(res, "upcoming_events"),
    past_events = map_int(res, "past_events"),
    res = res
  )
}


#' @rdname meetup_pro
#' @importFrom tibble tibble
#' @export
get_pro_events <- function(urlname,
                           verbose = getOption("meetupr.verbose", rlang::is_interactive())
                           ){

  api_path <- sprintf("pro/%s/events", urlname)
  res <- .fetch_results(api_path = api_path, verbose = verbose)

  group <- lapply(res, function(x) x[[3]])
  group <- tibble(group_sorter(group), res = group)
  names(group) <- paste0("group_", names(group))

  events <- lapply(res, function(x) x[[1]])

  tibble(
    event_sorter(events),
    group
  )
}
