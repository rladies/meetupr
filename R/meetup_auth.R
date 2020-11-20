# Credit to Jenny Bryan and the Googlesheets3 package for this pattern of
# OAuth handling, see https://github.com/jennybc/googlesheets/blob/master/R/gs_auth.R
# And credit to Michael Kearney and the rtweet package.
#
# environment to store credentials
.state <- new.env(parent = emptyenv())

#' Authorize \code{meetupr}
#'
#' Authorize \code{meetupr} via the OAuth API. You will be directed to a web
#' browser, asked to sign in to your Meetup account, and to grant \code{meetupr}
#' permission to operate on your behalf. By default, these user credentials are
#' saved to a file in your home directory whose path is saved in `.Renviron`
#' as `MEETUPR_PAT`.
#' If you set `set_env` to `FALSE` but `cache` to `TRUE`,
#' they are cached in a file named \code{.httr-oauth} in the current working directory.
#'
#' @section How to force meetupr to use a given token?
#'
#' Save this token somewhere on disk (`token_path` argument of `meetup_auth`).
#' Set the environment variable `MEETUPR_PAT` to the path to that file.
#' Call `meetup_token_path()` and check it returns the right path.
#'
#' @section Advanced usage
#'
#' Most users, most of the time, do not need to call this function explicitly --
#' it will be triggered by the first action that requires authorization. Even
#' when called, the default arguments will often suffice. However, when
#' necessary, this function allows the user to
#'
#' \itemize{
#'   \item force the creation of a new token
#'   \item retrieve current token as an object, for possible storage to an
#'   \code{.rds} file
#'   \item read the token from an object or from an \code{.rds} file
#'   \item provide your own app key and secret -- this requires setting up
#'   a new OAuth consumer on \href{https://secure.meetup.com/meetup_api/oauth_consumers/}{Meetup}
#'   \item prevent caching of credentials
#' }
#'
#' In a direct call to \code{meetup_auth}, the user can provide the token, app
#' key and secret explicitly and can dictate whether interactively-obtained
#' credentials will be cached. If unspecified, these
#' arguments are controlled via options, which, if undefined at the time
#' \code{meetupr} is loaded, are defined like so:
#'
#' \describe{
#'   \item{key}{Set to option \code{meetupr.consumer_key}, which defaults to a
#'   consumer key that ships with the package}
#'   \item{secret}{Set to option \code{meetupr.consumer_secret}, which defaults to
#'   a consumer secret that ships with the package}
#'   \item{cache}{Set to option \code{meetupr.httr_oauth_cache}, which defaults
#'   to \code{TRUE}}
#' }
#'
#' To override these defaults in persistent way, predefine one or more of them
#' with lines like this in a \code{.Rprofile} file:
#' \preformatted{
#' options(meetupr.consumer_key = "FOO",
#'         meetupr.consumer_secret = "BAR",
#'         meetupr.httr_oauth_cache = FALSE)
#' }
#' See \code{\link[base]{Startup}} for possible locations for this file and the
#' implications thereof.
#'
#' More detail is available from
#' \href{https://www.meetup.com/meetup_api/auth/#oauth2-resources}{Authenticating
#' with the Meetup API}.
#'
#' @param token optional; an actual token object or the path to a valid token
#'   stored as an \code{.rds} file
#' @param new_user logical, defaults to \code{FALSE}. Set to \code{TRUE} if you
#'   want to wipe the slate clean and re-authenticate with the same or different
#'   Meetup account. This disables the \code{.httr-oauth} file in current
#'   working directory.
#' @param key,secret the "Client ID" and "Client secret" for the application;
#'   defaults to the ID and secret built into the \code{meetupr} package
#' @param cache logical indicating if \code{meetupr} should cache
#'   credentials in the default cache file \code{.httr-oauth} or `token_path`.
#' @param set_renv Logical indicating whether to save the created token
#'   as the default environment meetup token variable. Defaults to TRUE,
#'   meaning the token is saved to user's home directory as either the user
#'   provided path, or
#'   ".meetup_token.rds" (or, if that already exists, then
#'   .meetup_token1.rds or .meetup_token2.rds, etc.) and the path to the
#'   token to said token is then set in the user's .Renviron file and re-
#'   read to start being used in current active session.
#'   If \code{cache} is `FALSE` this is ignored.
#' @param token_path Path where to save the token. If `set_renv` is `FALSE`,
#'  this is ignored.
#' @template verbose
#'
#' @rdname meetup-auth
#' @export
#' @family auth functions
#' @examples
#' \dontrun{
#' ## load/refresh existing credentials, if available
#' ## otherwise, go to browser for authentication and authorization
#' meetup_auth()
#'
#' ## store token in an object and then to file
#' ttt <- meetup_auth()
#' saveRDS(ttt, "ttt.rds")
#'
#' ## load a pre-existing token
#' meetup_auth(token = ttt)       # from an object
#' meetup_auth(token = "ttt.rds") # from .rds file
#' }
meetup_auth <- function(token = meetup_token_path(),
                        new_user = FALSE,
                        key = getOption("meetupr.consumer_key"),
                        secret = getOption("meetupr.consumer_secret"),
                        cache = getOption("meetupr.httr_oauth_cache"),
                        verbose = TRUE,
                        set_renv = TRUE,
                        token_path = NULL) {

  if (new_user) {
    meetup_deauth(clear_cache = TRUE, verbose = verbose)
  }

  if (is.null(token)) {

    message(paste0('Meetup is moving to OAuth *only* as of 2019-08-15. Set\n',
                  '`meetupr.use_oauth = FALSE` in your .Rprofile, to use\nthe ',
                  'legacy `api_key` authorization.'))

    meetup_app       <- httr::oauth_app("meetup", key = key, secret = secret)
    meetup_endpoints <- httr::oauth_endpoint(
      authorize = 'https://secure.meetup.com/oauth2/authorize',
      access    = 'https://secure.meetup.com/oauth2/access'
    )


    if (cache) {
      if (set_renv) {
        if (is.null(token_path)) {
          token_path <- uq_filename(file.path(home(), ".meetup_token.rds"))
        }

      }

      if (!is.null(token_path)) {
        cache <- token_path
      }
    }

    meetup_token <- httr::oauth2.0_token(
      meetup_endpoints,
      meetup_app,
      cache = cache
      )

    stopifnot(is_legit_token(meetup_token, verbose = TRUE))

    if (set_renv && cache) {
      set_renv("MEETUPR_PAT" = token_path)
    }

    save_and_refresh_token(meetup_token, token_path)
    return(invisible(.state$token))

  }

  if (inherits(token, "Token2.0")) {

    stopifnot(is_legit_token(token, verbose = TRUE))
    .state$token <- token

    # If you provide a token directly we're not gonna save it for you
    save_and_refresh_token(token, NULL)
    return(invisible(.state$token))

  }

  if (inherits(token, "character")) {

    token_path <- token
    meetup_token <- try(suppressWarnings(readRDS(token)), silent = TRUE)
    if (inherits(meetup_token, "try-error")) {
      spf("Cannot read token from alleged .rds file:\n%s", token)
    } else if (!is_legit_token(meetup_token, verbose = TRUE)) {
      spf("File does not contain a proper token:\n%s", token)
    }

    save_and_refresh_token(meetup_token, token_path)
    return(invisible(.state$token))
  }

  spf(paste0("Input provided via 'token' is neither a token,\n",
               "nor a path to an .rds file containing a token."))

}

#' Produce Meetup token
#'
#' If token is not already available, call \code{\link{meetup_auth}} to either
#' load from cache or initiate OAuth2.0 flow. Return the token -- not "bare"
#' but, rather, prepared for inclusion in downstream requests.
#'
#' @return a \code{request} object (an S3 class provided by \code{httr})
#'
#' @keywords internal
#' @export
#' @rdname meetup-auth
#' @family auth functions
#' @examples
#' \dontrun{
#' meetup_token()
#' }
meetup_token <- function(verbose = FALSE) {
  if (getOption("meetupr.use_oauth")) {
    if (!token_available(verbose = verbose)) meetup_auth(verbose = verbose)
    httr::config(token = .state$token)
  } else {
    httr::config()
  }
}

#' Check token availability
#'
#' Check if a token is available in \code{\link{meetupr}}'s internal
#' \code{.state} environment.
#'
#' @return logical
#'
#' @keywords internal
token_available <- function(verbose = TRUE) {

  if (is.null(.state$token)) {
    if (verbose) {
      if (!is.null(meetup_token_path()) && file.exists(meetup_token_path())) {
        message("A .httr-oauth file exists in current working ",
                "directory.\nWhen/if needed, the credentials cached in ",
                ".httr-oauth will be used for this session.\nOr run ",
                "meetup_auth() for explicit authentication and authorization.")
      } else {
        message("No .httr-oauth file exists in current working directory.\n",
                "When/if needed, 'meetupr' will initiate authentication ",
                "and authorization.\nOr run meetup_auth() to trigger this ",
                "explicitly.")
      }
    }
    return(FALSE)
  }

  TRUE

}

#' Suspend authorization
#'
#' Suspend \code{\link{meetupr}}'s authorization to place requests to the Meetup
#' APIs on behalf of the authenticated user.
#'
#' @param clear_cache logical indicating whether to disable the
#'   \code{.httr-oauth} file in working directory, if such exists, by renaming
#'   to \code{.httr-oauth-SUSPENDED}
#' @template verbose
#' @export
#' @rdname meetup-auth
#' @family auth functions
#' @examples
#' \dontrun{
#' meetup_deauth()
#' }
meetup_deauth <- function(clear_cache = TRUE, verbose = TRUE) {

  if (clear_cache && file.exists(meetup_token_path())) {
    if (verbose) {
      message(
        sprintf(
        "Disabling %s by renaming to %s-SUSPENDED",
        meetup_token_path(),
        meetup_token_path()
        )
        )
    }
    file.rename(meetup_token_path(), paste0(meetup_token_path(), "-SUSPENDED"))
  }

  if (token_available(verbose = FALSE)) {
    if (verbose) {
      message("Removing google token stashed internally in 'meetupr'.")
    }
    rm("token", envir = .state)
  } else {
    message("No token currently in force.")
  }

  invisible(NULL)

}

#' Check that token appears to be legitimate
#'
#' @keywords internal
is_legit_token <- function(x, verbose = FALSE) {

  if (!inherits(x, "Token2.0")) {
    if (verbose) message("Not a Token2.0 object.")
    return(FALSE)
  }

  if ("invalid_client" %in% unlist(x$credentials)) {
    # shouldn't happen if id and secret are good
    if (verbose) {
      message("Authorization error. Please check consumer_key and consumer_secret")
    }
    return(FALSE)
  }

  if ("invalid_request" %in% unlist(x$credentials)) {
    # in past, this could happen if user clicks "Cancel" or "Deny" instead of
    # "Accept" when OAuth2 flow kicks to browser ... but httr now catches this
    if (verbose) message("Authorization error. No access token obtained.")
    return(FALSE)
  }

  TRUE

}


#' Store a legacy API key in the .state environment
#'
#' @keywords internal
set_api_key <- function(x = NULL) {

  if (is.null(x)) {
    key <- Sys.getenv("MEETUP_KEY")
    if (key == "") {
      spf(paste0("You have not set a MEETUP_KEY environment variable.\nIf you ",
                 "do not yet have a meetup.com API key, use OAuth2\ninstead, ",
                 "as API keys are now deprecated - see here:\n",
                 "* https://www.meetup.com/meetup_api/auth/"))
    }
    .state$legacy_api_key <- key
  } else {
    .state$legacy_api_key <- x
  }

  invisible(NULL)

}

#' Get the legacy API key from the .state environment
#'
#' @keywords internal
get_api_key <- function() {

  if (is.null(.state$legacy_api_key)) {
    set_api_key()
  }

  .state$legacy_api_key

}

#' @return Either NULL or the path in which the token is saved.
#' @export
#' @rdname meetup-auth
#' @family auth functions
#'
#' @examples
#' meetup_token_path()
meetup_token_path <- function() {
  token_path <- Sys.getenv("MEETUPR_PAT")

  if (token_path != "") {
    return(token_path)
  }

  if (file.exists(".httr-oauth")) {
    return(".httr-oauth")
  }

  return(NULL)
}

save_and_refresh_token <- function(token, path) {

  if (token$credentials$expires_in < 60) {
    token$refresh

    if(!is.null(path)) {
      saveRDS(token, path)
    }
  }

  .state$token <- token
}
