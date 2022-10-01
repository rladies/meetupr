#' #' Get the discussion boards from a meetup group
#' #'
#' #' @template urlname
#' #' @template verbose
#' #' @return A tibble with the following columns:
#' #'    * id
#' #'    * name
#' #'    * description
#' #'    * created
#' #'    * updated
#' #'    * post_count
#' #'    * discussion_count
#' #'    * latest_reply_created
#' #'    * latest_reply_member_name
#' #'    * resource
#' #'
#' #' @references
#' #' \url{https://www.meetup.com/meetup_api/docs/:urlname/boards/}
#' #'@examples
#' #' \dontrun{
#' #' urlname <- "rladies-nashville"
#' #' meetup_boards <- get_boards(urlname = urlname)
#' #'}
#' #' @export
#' get_boards <- function(urlname,
#'                        verbose = meetupr_verbose()) {
#'   api_path <- paste0(urlname, "/boards")
#'   res <- .fetch_results(api_path = api_path, verbose = verbose)
#'   tibble::tibble(
#'     id = purrr::map_int(res, "id"),
#'     name = purrr::map_chr(res, "name"),
#'     description = purrr::map_chr(res, "description"),
#'     created = .date_helper(purrr::map_dbl(res, "created")),
#'     updated = .date_helper(purrr::map_dbl(res, "updated")),
#'     post_count = purrr::map_int(res, "post_count", .default = NA),
#'     discussion_count = purrr::map_int(res, "discussion_count", .default = NA),
#'     latest_reply_created = .date_helper(purrr::map_dbl(res, c("latest_reply", "created"), .default = NA)),
#'     latest_reply_member_name = purrr::map_chr(res, c("latest_reply", "member", "name"), .default = NA),
#'     resource = res
#'   )
#' }
