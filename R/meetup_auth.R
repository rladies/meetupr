# Credit to Jenny Bryan for OAuth wisdom.
#
# environment to store credentials
.state <- new.env(parent = emptyenv())

#' Authorize \code{meetupr}
#'
#' Authorize \code{meetupr} via the OAuth API. You will be directed to a web
#' browser, asked to sign in to your Meetup account, and to grant \code{meetupr}
#' permission to operate on your behalf. By default, these user credentials are
#' saved to an app dir as determined by `rappdirs::user_data_dir("meetupr", "meetupr")`.
#' If you set `use_appdir` to `FALSE` but `cache` to `TRUE`,
#' they are cached in a file named \code{.httr-oauth} in the current working directory.
#' To control where the file is saved, use `token_path`.
#'
#' @section How to force meetupr to use a given token?:
#'
#' Save this token somewhere on disk (`token_path` argument of `meetup_auth`).
#' Then in future sessions call `meetup_auth()` with `token` set to that path.
#'
#' @section Advanced usage:
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
#' }
#'
#' To override these defaults in persistent way, predefine one or more of them
#' with lines like this in a \code{.Rprofile} file:
#' \preformatted{
#' options(meetupr.consumer_key = "FOO",
#'         meetupr.consumer_secret = "BAR")
#' }
#' See \code{\link[base]{Startup}} for possible locations for this file and the
#' implications thereof.
#'
#' More detail is available from
#' \href{https://www.meetup.com/meetup_api/auth/#oauth2-resources}{Authenticating
#' with the Meetup API}.
#'
#' @param token optional; an actual token object or the path to a valid token
#'   stored as an \code{.rds} file.
#' @param new_user logical, defaults to \code{FALSE}. Set to \code{TRUE} if you
#'   want to wipe the slate clean and re-authenticate with the same or different
#'   Meetup account. This disables the \code{.httr-oauth} file in current
#'   working directory.
#' @param key,secret the "Client ID" and "Client secret" for the application;
#'   defaults to the ID and secret built into the \code{meetupr} package
#' @param cache logical indicating if \code{meetupr} should cache
#'   credentials in the default cache file \code{.httr-oauth} or `token_path`.
#' @param use_appdir Logical indicating whether to save the created token
#'   in app dir as determined by `rappdirs::user_data_dir("meetupr", "meetupr")`.
#'   If \code{cache} is `FALSE` this is ignored.
#' @param token_path Path where to save the token. If `use_appdir` is `TRUE`,
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
                        cache = getOption("meetupr.httr_oauth_cache", TRUE),
                        verbose = getOption("meetupr.verbose", rlang::is_interactive()),
                        use_appdir = TRUE,
                        token_path = NULL) {

  if (new_user) {
    meetup_deauth(clear_cache = TRUE, verbose = verbose)
  }

  if (is.null(token)) {

    meetup_app       <- httr::oauth_app(
      "meetup",
      key = key,
      secret = secret,
      redirect_uri = httr::oauth_callback()
      )

    meetup_endpoints <- httr::oauth_endpoint(
      authorize = paste0(meetup_auth_prefix(), 'authorize'),
      access    = paste0(meetup_auth_prefix(), 'access')
    )

    if (!cache && !is.null(token_path)) {
      stop(
        "You chose `cache` FALSE (no saving to disk) but input a `token_path`.",
        "Should you set `cache` to TRUE?",
        call. = FALSE
        )
    }


    if (cache) {
      if (use_appdir) {
        if (is.null(token_path)) {
          token_path <- appdir_path()
          # from https://github.com/r-hub/rhub/blob/5c339d7b95d75172beec85603ee197c2502903b1/R/email.R#L192
          parent <- dirname(token_path)
          if (!file.exists(parent)) dir.create(parent, recursive = TRUE)
        }

      }

      # In all cases if cache is TRUE we want to set it to the filepath
      if (!is.null(token_path)) {
        cache <- token_path
      }
    }

    meetup_token <- TOKEN_FUNCTION(
      meetup_endpoints,
      meetup_app,
      cache = cache # if FALSE won't be saved, if character will be saved
      # to character (filepath)
      )

    stopifnot(is_legit_token(meetup_token, verbose = TRUE))


    # save token to .state$token after refreshing if need be
    # here we've just created it so probably no need to refresh it
    save_and_refresh_token(meetup_token, token_path)
    return(invisible(.state$token))

  }

  if (inherits(token, "Token2.0")) {

    stopifnot(is_legit_token(token, verbose = TRUE))
    .state$token <- token

    save_and_refresh_token(token, token_path)
    return(invisible(.state$token))

  }

  if (inherits(token, "character")) {

    token_path <- token
    meetup_token <- try(suppressWarnings(readRDS(token)[[1]]), silent = TRUE)
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
  if (nzchar(Sys.getenv("MEETUPR_TESTING"))) {
    return(httr::config())
  }
    if (!token_available(verbose = verbose)) meetup_auth(verbose = verbose)
    httr::config(token = .state$token)

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
#'   token file, if such exists, by apprending "-SUSPENDED" to its name
#' @template verbose
#' @export
#' @rdname meetup-auth
#' @family auth functions
#' @examples
#' \dontrun{
#' meetup_deauth()
#' }
meetup_deauth <- function(clear_cache = TRUE,
                          verbose = getOption("meetupr.verbose", rlang::is_interactive())) {
  if (is.null(meetup_token_path())) {
    return(NULL)
  }
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
      message("Removing Meetup token stashed internally in 'meetupr'.")
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

#' @return Either NULL or the path in which the token is saved.
#' @export
#' @rdname meetup-auth
#' @family auth functions
#'
#' @examples
#' meetup_token_path()
meetup_token_path <- function() {
  token_path <- appdir_path()

  if (file.exists(appdir_path())) {
    return(token_path)
  }

  if (file.exists(".httr-oauth")) {
    return(".httr-oauth")
  }

  return(NULL)
}

save_and_refresh_token <- function(token, path) {

  if (purrr::compact(c(token$credentials$expires_in, token$credentials$expiry)) < 60) {
    token$refresh()

    if(!is.null(path)) {
      saveRDS(token, path)
    }
  }

  .state$token <- token
}

appdir_path <- function() {
  file.path(rappdirs::user_data_dir("meetupr", "meetupr"), "meetupr-token.rds")
}

meetup_auth_prefix <- function() {

  Sys.getenv("MEETUP_AUTH_URL", "https://secure.meetup.com/oauth2/")
}

TOKEN_FUNCTION <- function(...) {
  if (nzchar(Sys.getenv("MEETUP_TESTTHAT"))) {
    return(webfakes::oauth2_httr_login(httr::oauth2.0_token(...)))
  }

    return(httr::oauth2.0_token(...))
}
