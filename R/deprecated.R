.fetch_results <- function(...) {
  .Deprecated(
    msg = paste(
      ".fetch_results() is deprecated as the REST API is no longer supported.",
      "Use GraphQL functions instead."
    )
  )
  abort_dep()
}

meetup_call <- function(...) {
  .Deprecated(
    msg = paste(
      "meetup_call() is deprecated as the REST API is no longer supported.",
      "Use GraphQL functions instead."
    )
  )
  abort_dep()
}

.quick_fetch <- function(...) {
  .Deprecated(
    msg = paste(
      ".quick_fetch() is deprecated as the REST API is no longer supported.",
      "Use GraphQL functions instead."
    )
  )
  abort_dep()
}

get_meetup_comments <- function(...) {
  .Deprecated("get_event_comments")
  get_event_comments(...)
}

abort_dep <- function(.envir = parent.frame()) {
  cli::cli_abort(
    c(
      "REST API functions are no longer supported.",
      "Please use GraphQL equivalents."
    ),
    .envir = .envir
  )
}
