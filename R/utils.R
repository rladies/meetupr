#' Utility Functions
#' @keywords internal

#' Validate GraphQL Variables
#' This function checks if the provided GraphQL variables are named.
#' If any variable is unnamed, it raises an error.
#' @param variables A list
#' @noRd
#' @keywords internal
validate_graphql_variables <- function(variables) {
  unnamed <- variables |>
    not_named() |>
    unlist()

  if (length(unnamed) > 0) {
    cli::cli_abort(c(
      "All GraphQL variables must be named. Unnamed variable values:",
      unnamed
    ))
  }
  invisible(variables)
}

#' Check if a List is Not Named
#' This function checks if a list is not named.
#' @param x A list
#' @return TRUE if the list is not named, FALSE otherwise
#' @noRd
#' @keywords internal
not_named <- function(x) {
  x[!rlang::is_named(x)]
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

  if (!file.exists(file_name)) {
    return(file_name)
  }

  normalized_path <- normalize_path(
    file_name,
    winslash = "/",
    mustWork = FALSE
  )
  dir_path <- dirname(normalized_path)

  existing_files <- normalize_path(
    list.files(dir_path, all.files = TRUE, full.names = TRUE),
    winslash = "/",
    mustWork = FALSE
  )

  ext <- ext(normalized_path)
  base <- tools::file_path_sans_ext(normalized_path)

  candidates <- paste0(base, seq_len(1000), ext)

  available <- candidates[!candidates %in% existing_files]

  if (length(available) > 0L) {
    return(available[1L])
  }
  paste0(base, "1001", ext)
}

#' Get File Extension with Leading Dot
#' This function returns the file extension of a given file name,
#' including the leading dot. If the file has no extension,
#' it returns an empty string.
#' @param x A character string representing the file name.
#' @return A character string
#' @noRd
#' @keywords internal
ext <- function(x) {
  extension <- tools::file_ext(x)
  if (nzchar(extension)) {
    return(paste0(".", extension))
  }
  ""
}

#' Process Date-Time Fields in a Data Table
#' @keywords internal
#' @noRd
process_datetime_fields <- function(dt, fields) {
  existing_fields <- intersect(fields, names(dt))
  dt[existing_fields] <- lapply(
    dt[existing_fields],
    fix_datetime
  )
  dt
}

fix_datetime <- function(x) {
  gsub(
    "([+-]\\d{2}):(\\d{2})$",
    "\\1\\2",
    x
  ) |>
    as.POSIXct(format = "%Y-%m-%dT%H:%M:%S%z")
}


#' Get Country Name from ISO2 Country Code or List of Codes
#' @param x ISO2 country code or list of codes
#' @return Full country name(s) or NA if code is invalid
#' @keywords internal
#' @noRd
get_country_code <- function(x) {
  if (is.list(x)) {
    return(
      lapply(x, get_country_code)
    )
  }
  country_code(x)
}

#' Get Country Name from ISO2 Country Code
#' @param x ISO2 country code
#' @return Full country name or NA if code is invalid
#' @keywords internal
#' @noRd
country_code <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }
  countrycode::countrycode(
    x,
    origin = "iso2c",
    destination = "country.name",
    warn = FALSE
  )
}

#' Temporarily enable debug mode
#'
#' Sets the level of verbosity for `httr2::local_verbosity()`,
#' and the MEETUPR_DEBUG environment variable.
#' Can help debug issues with API requests.
#'
#' @param verbosity How much debug information to show.
#'   0 = off, 1 = basic, 2 = verbose, 3 = very verbose
#' @param env The environment in which to set the variable.
#' @return The old debug value (invisibly)
#' @export
#' @examples
#' \dontrun{
#' local_meetupr_debug(2)
#'
#' # Turn off debug mode
#' local_meetupr_debug(0)
#' }
local_meetupr_debug <- function(verbosity = 0, env = rlang::caller_env()) {
  if (verbosity < 0 || verbosity > 3) {
    cli::cli_abort("Verbosity must be between 0 and 3.")
  }
  httr2::local_verbosity(verbosity, env = env)

  withr::local_envvar(
    "MEETUPR_DEBUG" = verbosity,
    .local_envir = env
  )
}

#' Check if debug mode is enabled
#' @keywords internal
#' @noRd
check_debug_mode <- function() {
  val <- suppressWarnings(
    Sys.getenv("MEETUPR_DEBUG") |>
      as.integer()
  )

  if (is.na(val)) {
    return(FALSE)
  }
  val > 0
}


#' Check if variable is empty
#' @return Logical
#' @keywords internal
#' @noRd
is_empty <- function(x) {
  if (is.null(x)) {
    return(TRUE)
  }
  if (length(x) == 0) {
    return(TRUE)
  }
  if (all(is.na(x))) {
    return(TRUE)
  }
  if (is.character(x) && all(!nzchar(x))) {
    return(TRUE)
  }
  FALSE
}

#' Normalize Path with Debug Info
#' @keywords internal
#' @noRd
normalize_path <- function(path, ...) {
  base::normalizePath(path, ...)
}
