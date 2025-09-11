.fetch_results <- function(...) {
  .Deprecated(
    msg = paste(
      ".fetch_results() is deprecated as the REST API is no longer supported.",
      "Use GraphQL functions instead."
    )
  )
  cli::cli_abort(
    "REST API functions are no longer supported. Please use GraphQL equivalents."
  )
}

meetup_call <- function(...) {
  .Deprecated(
    msg = paste(
      "meetup_call() is deprecated as the REST API is no longer supported.",
      "Use GraphQL functions instead."
    )
  )
  cli::cli_abort(
    "REST API functions are no longer supported. Please use GraphQL equivalents."
  )
}

.quick_fetch <- function(...) {
  .Deprecated(
    msg = paste(
      ".quick_fetch() is deprecated as the REST API is no longer supported.",
      "Use GraphQL functions instead."
    )
  )
  cli::cli_abort(
    "REST API functions are no longer supported. Please use GraphQL equivalents."
  )
}

get_meetup_comments <- function(...) {
  .Deprecated("get_event_comments")
  get_event_comments(...)
}
