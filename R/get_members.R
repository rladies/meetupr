#' Get the current meetup members from a meetup group
#'
#' @template urlname
#' @template verbose
#'
#' @return A tibble with the following columns:
#'    * id
#'    * name
#'    * bio
#'    * status
#'    * joined
#'    * city
#'    * country
#'    * state
#'    * lat
#'    * lon
#'    * photo_link
#'    * resource
#' @references
#' \url{https://www.meetup.com/meetup_api/docs/:urlname/members/#list}
#' @examples
#' \dontrun{
#' urlname <- "rladies-nashville"
#' members <- get_members(urlname)
#'}
#' @export
get_members <- function(urlname,
                        verbose = meetupr_verbose()){
  api_path <- paste0(urlname, "/members/")
  res <- .fetch_results(api_path = api_path, verbose = verbose)
  tibble::tibble(
    id = purrr::map_int(res, "id"),
    name = purrr::map_chr(res, "name", .default = NA),
    bio = purrr::map_chr(res, "bio", .default = NA),
    status = purrr::map_chr(res, "status"),
    created = .date_helper(purrr::map_dbl(res, c("group_profile", "created"))),
    city = purrr::map_chr(res, "city", .default = NA),
    country = purrr::map_chr(res, "country", .default = NA),
    state = purrr::map_chr(res, "state", .default = NA),
    lat = purrr::map_dbl(res, "lat", .default = NA),
    lon = purrr::map_dbl(res, "lon", .default = NA),
    photo_link = purrr::map_chr(res, c("photo", "photo_link"), .default = NA),
    resource = res
  )
}


# @param query Required search text
# @param ... Should be empty. Used for parameter expansion
#' @importFrom dplyr %>%
get_members2 <- function(
  urlname,
  ...,
  extra_graphql = NULL,
  token = meetup_token()
) {
  ellipsis::check_dots_empty()

  dt <- gql_get_members(
    urlname = urlname,
    .extra_graphql = extra_graphql,
    .token = token
  )

  dt

}

