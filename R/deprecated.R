.fetch_results <- function(...) {
  lifecycle::deprecate_warn(
    "0.3.0",
    ".fetch_results()",
    "meetup_query()",
    details = "The REST API is no longer supported. Use GraphQL functions instead."
  )
}

meetup_call <- function(...) {
  lifecycle::deprecate_warn(
    "0.3.0",
    "meetup_call()",
    "meetup_query()",
    details = "The REST API is no longer supported. Use GraphQL functions instead."
  )
}

.quick_fetch <- function(...) {
  lifecycle::deprecate_warn(
    "0.3.0",
    ".quick_fetch()",
    "meetup_query()",
    details = "The REST API is no longer supported. Use GraphQL functions instead."
  )
}

get_meetup_comments <- function(...) {
  lifecycle::deprecate_stop(
    "0.3.0",
    "get_meetup_comments()",
    NULL,
    details = "Comments are no longer supported in the Meetup API."
  )
}
