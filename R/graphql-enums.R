#' Event Status Enum
#' @keywords internal
#' @noRd
valid_event_status <- c(
  "ACTIVE",
  "AUTOSCHED",
  "AUTOSCHED_CANCELLED",
  "AUTOSCHED_DRAFT",
  "AUTOSCHED_FINISHED",
  "BLOCKED",
  "CANCELLED",
  "CANCELLED_PERM",
  "DRAFT",
  "PAST",
  "PENDING",
  "PROPOSED",
  "TEMPLATE",
  "UPCOMING"
)


validate_event_status <- function(status = NULL) {
  if (is.null(status)) {
    return(valid_event_status)
  }
  event_status <- unique(toupper(status))
  chosen_status <- valid_event_status[valid_event_status %in% event_status]
  invalid_status <- event_status[!event_status %in% valid_event_status]
  if (length(invalid_status) > 0) {
    cli::cli_abort(c(
      "Invalid event status: '{.val {tolower(invalid_status)}}'. Valid values are: ",
      paste(tolower(valid_event_status), collapse = ", ")
    ))
  }
  valid_event_status[valid_event_status %in% event_status]
}
