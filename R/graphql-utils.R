#' Execute GraphQL query from file
#'
#' This function reads a GraphQL query from a specified file,
#' optionally inserts additional GraphQL fragments or queries,
#' and executes the query with provided variables.
#'
#' @param .file Name of the file containing the GraphQL
#' query (without extension)
#' @param ... Variables to pass to query
#' @param extra_graphql Additional GraphQL fragments or queries to include
#' @param .envir Environment for error handling
#' @noRd
#' @keywords internal
execute_from_template <- function(
  .file,
  ...,
  extra_graphql = NULL,
  .envir = parent.frame()
) {
  extra_graphql <- validate_extra_graphql(
    extra_graphql
  )

  template <- get_template_path(.file) |>
    read_template() |>
    insert_extra_graphql(extra_graphql)

  meetup_query(
    graphql = template,
    ...,
    .envir = .envir
  )
}

#' Get template path
#' This function constructs the file path for a given GraphQL
#' template file and checks if it exists.
#' @param .file Name of the file containing the GraphQL
#' query (without extension)
#' @return The full file path to the GraphQL template file.
#' @keywords internal
#' @noRd
get_template_path <- function(.file) {
  file_path <- system.file(
    file.path("graphql", paste0(.file, ".graphql")),
    package = "meetupr"
  )

  if (!file.exists(file_path)) {
    cli::cli_abort("GraphQL file not found: {.path {file_path}}")
  }

  file_path
}

#' Read template file
#' This function reads the content of a GraphQL template file.
#' @param file_path Full path to the GraphQL template file.
#' @return The content of the GraphQL template file as a string.
#' @keywords internal
#' @noRd
read_template <- function(file_path) {
  tryCatch(
    {
      content <- readChar(
        file_path,
        file.info(file_path)$size
      )
      gsub("\r", "", content)
    },
    error = function(e) {
      cli::cli_abort("Failed to read GraphQL file: {e$message}")
    }
  )
}

#' Insert extra GraphQL into query
#' This function inserts additional GraphQL fragments or queries
#' into a base GraphQL query string.
#' @param query The base GraphQL query string.
#' @param extra_graphql Additional GraphQL fragments or queries to include
#' @return The modified GraphQL query string with the extra GraphQL included.
#' @keywords internal
#' @noRd
insert_extra_graphql <- function(query, extra_graphql = NULL) {
  if (is.null(extra_graphql)) {
    extra_graphql <- ""
  }

  if (nzchar(extra_graphql)) {
    extra <- glue::glue_data(
      list(extra_graphql = extra_graphql),
      query,
      .open = "<<",
      .close = ">>",
      trim = FALSE
    )
    return(extra)
  }

  gsub("<< extra_graphql >>", "", query)
}

#' Validate GraphQL Variables
#' This function checks that the provided GraphQL variables
#' are in the correct format (a named list).
#' @param extra_graphql Additional GraphQL fragments or queries to include
#' @keywords internal
#' @noRd
validate_extra_graphql <- function(extra_graphql) {
  extra_graphql <- extra_graphql %||% ""

  if (
    !is.null(extra_graphql) &&
      (length(extra_graphql) != 1 || !is.character(extra_graphql))
  ) {
    cli::cli_abort("{.code extra_graphql} must be a single string")
  }

  extra_graphql
}

#' Event Status Enums
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
  "TEMPLATE"
)

#' Event Status Enums including Pro-only statuses
#' @keywords internal
#' @noRd
valid_pro_status <- c(
  valid_event_status,
  "UPCOMING"
)

#' Validate event status for regular group events
#' @param status Event status values to validate
#' @param pro Boolean indicating if Pro event statuses should be used
#' @return Validated status values
#' @keywords internal
#' @noRd
validate_event_status <- function(status = NULL, pro = FALSE) {
  valid_events <- valid_event_status
  if (pro) {
    valid_events <- valid_pro_status
  }
  if (is.null(status)) {
    return(valid_events)
  }
  validate_status_enum(status, valid_events)
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
