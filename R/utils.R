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

  normalized_path <- normalizePath(
    file_name,
    winslash = "/",
    mustWork = FALSE
  )
  dir_path <- dirname(normalized_path)

  existing_files <- normalizePath(
    list.files(dir_path, all.files = TRUE, full.names = TRUE),
    winslash = "/",
    mustWork = FALSE
  )

  ext <- tools::file_ext(normalized_path)
  base <- tools::file_path_sans_ext(normalized_path)

  if (nzchar(ext)) {
    ext_with_dot <- paste0(".", ext)
    candidates <- paste0(base, seq_len(1000), ext_with_dot)
  } else {
    candidates <- paste0(base, seq_len(1000))
  }

  available <- candidates[!candidates %in% existing_files]

  if (length(available) > 0L) {
    return(available[1L])
  }

  if (nzchar(ext)) {
    return(
      paste0(base, "1001", ext_with_dot)
    )
  }
  paste0(base, "1001")
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
#' @param level Debug level: 1 for on, 0 for off
#' @param env The environment to use for scoping
#' @return The old debug value (invisibly)
#' @export
#' @examples
#' \dontrun{
#' # Within a function or test
#' local_meetupr_debug(1)
#' # Debug output enabled for remainder of scope
#'
#' # Manual cleanup
#' old <- local_meetupr_debug(1, env = emptyenv())
#' # ... code with debugging ...
#' Sys.setenv(MEETUPR_DEBUG = old)
#' }
local_meetupr_debug <- function(
  level = 1,
  env = parent.frame()
) {
  level <- match.arg(
    as.character(level),
    c("0", "1")
  )
  old <- Sys.getenv("MEETUPR_DEBUG", unset = "0")
  Sys.setenv(MEETUPR_DEBUG = level)
  withr::defer(
    Sys.setenv(MEETUPR_DEBUG = old),
    envir = env
  )
  invisible(old)
}

# nocov start
mock_if_no_auth <- function() {
  if (meetup_auth_status(silent = TRUE)) {
    return(invisible())
  }
  Sys.setenv(
    MEETUP_TOKEN = "123456",
    MEETUP_TOKEN_FILE = "aB3xK9mP2.rds.enc"
  )
  invisible()
}
# nocov end
