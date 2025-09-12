#' Utility Functions
#' @keywords internal

#' Validate GraphQL Variables
#' This function checks if the provided GraphQL variables are named.
#' If any variable is unnamed, it raises an error.
#' @param variables A list
#' @noRd
#' @keywords internal
validate_graphql_variables <- function(variables) {
  unnamed <- variables[!rlang::is_named(variables)] |>
    unlist()
  if (length(unnamed) > 0) {
    cli::cli_abort(c(
      "All GraphQL variables must be named. Unnamed variable values:",
      unnamed
    ))
  }
  invisible(TRUE)
}

#' Paste a String Before the File Extension
#' This function takes a file name and a string (or vector of strings)
#' and inserts the string(s) before the file extension.
#' If the file has no extension, the string is appended
#' to the end of the file name.
#' @param x A character string representing the file name.
#' @param p A character string or vector of strings to insert
#' before the file extension.
#' @noRd
#' @keywords internal
paste_before_ext <- function(x, p) {
  ext <- tools::file_ext(x)
  base <- tools::file_path_sans_ext(x)

  if (nzchar(ext)) {
    return(paste0(base, p, ".", ext))
  }
  paste0(base, p)
}

#' Generate a Unique Filename
#' This function checks if a file with the given name already exists.
#' If it does, it appends a numeric suffix before the
#' file extension to create a unique filename.
#' @param file_name A character string representing the desired file name.
#' @noRd
#' @keywords internal
uq_filename <- function(file_name) {
  stopifnot(is.character(file_name) && length(file_name) == 1L)
  if (file.exists(file_name)) {
    files <- list.files(dirname(file_name), all.files = TRUE, full.names = TRUE)
    file_name <- paste_before_ext(file_name, 1:1000)
    file_name <- file_name[!file_name %in% files][1]
  }
  file_name
}

#' Add Country Names to Items Based on Country Codes
#'
#' This function takes a list of items and a function to extract country
#' codes from each item.
#' It adds a new element `country_name` to each item, which
#' contains the full country
#' name
#' corresponding to the 2-letter country
#' code. If the country code is missing or unrecognized,
#' `country_name` will be set to `NA`.
#' @param items A list of items (e.g., groups, events) where each item
#' is a list or named list.
#' @param get_country A function that takes an item and returns
#' its 2-letter country code.
#' @noRd
#' @keywords internal
add_country_name <- function(items, get_country) {
  lapply(items, function(item) {
    country_code <- get_country(item)

    # Handle missing/empty country codes
    if (
      is.null(country_code) ||
        length(country_code) == 0 ||
        is.na(country_code) ||
        country_code == ""
    ) {
      item$country_name <- NA_character_
    } else {
      # Convert 2-letter country code to country name
      item$country_name <- countrycode::countrycode(
        country_code,
        origin = "iso2c",
        destination = "country.name",
        warn = FALSE
      )
    }

    item
  })
}

#' Process Date-Time Fields in a Data Table
#' @keywords internal
#' @noRd
process_datetime_fields <- function(dt, fields) {
  existing_fields <- intersect(fields, names(dt))
  dt[existing_fields] <- lapply(dt[existing_fields], anytime::anytime)
  dt
}

# nocov start
mock_if_no_auth <- function() {
  if (has_jwt_credentials() && has_oauth_credentials()) {
    return(invisible())
  }
  Sys.setenv(
    MEETUP_CLIENT_ID = "123456",
    MEETUP_CLIENT_SECRET = "aB3xK9mP2",
    MEETUP_MEMBER_ID = "1111111",
    MEETUP_RSA_KEY = "-----BEGIN PRIVATE KEY-----"
  )
}
# nocov end
