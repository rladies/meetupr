.fetch_results <- function(...) {
  lifecycle::deprecate_warn(
    "0.3.0",
    ".fetch_results()",
    "meetupr_query()",
    details = "The REST API is no longer supported.
    Use GraphQL functions instead."
  )
}

meetupr_call <- function(...) {
  lifecycle::deprecate_warn(
    "0.3.0",
    "meetupr_call()",
    "meetupr_query()",
    details = "The REST API is no longer supported.
     Use GraphQL functions instead."
  )
}

.quick_fetch <- function(...) {
  lifecycle::deprecate_warn(
    "0.3.0",
    ".quick_fetch()",
    "meetupr_query()",
    details = "The REST API is no longer supported.
     Use GraphQL functions instead."
  )
}

get_meetupr_comments <- function(...) {
  lifecycle::deprecate_stop(
    "0.3.0",
    "get_meetupr_comments()",
    NULL,
    details = "Comments are no longer supported in the Meetup API."
  )
}
