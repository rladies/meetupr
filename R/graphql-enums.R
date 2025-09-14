#' Event Status Enums
#' @keywords internal
#' @noRd
valid_event_status <- c(
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

#' Validate event status for regular group events
#' @param status Event status values to validate
#' @return Validated status values
#' @keywords internal
#' @noRd
validate_event_status <- function(status = NULL) {
  if (is.null(status)) {
    return(valid_event_status)
  }
  validate_status_enum(status, valid_event_status)
}

#' Generic status validation function
#' @param status Status values to validate
#' @param valid_values Valid status enum values
#' @return Validated status values
#' @keywords internal
#' @noRd
validate_status_enum <- function(status, valid_values) {
  event_status <- unique(toupper(status))
  chosen_status <- valid_values[valid_values %in% event_status]
  invalid_status <- event_status[!event_status %in% valid_values]

  if (length(invalid_status) > 0) {
    cli::cli_abort(c(
      "Invalid event status: '{.val {tolower(invalid_status)}}'.",
      "Valid values are: ",
      paste(tolower(valid_values), collapse = ", ")
    ))
  }

  chosen_status
}
