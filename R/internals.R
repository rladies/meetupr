# This helper function makes a single call, given the full API endpoint URL
# Used as the workhorse function inside .fetch_results() below
.quick_fetch <- function(api_url,
                         api_key = NULL,
                         event_status = NULL,
                         offset = 0,
                         ...) {

  # list of parameters
  parameters <- list(key = api_key,         # your api_key
                     status = event_status, # you need to add the status
                     # otherwise it will get only the upcoming event
                     offset = offset,
                     ...                    # other parameters
  )

  req <- httr::GET(url = api_url,          # the endpoint
                   query = parameters)

  httr::stop_for_status(req)
  reslist <- httr::content(req, "parsed")

  if (length(reslist) == 0) {
    stop("Zero records match your filter. Nothing to return.\n",
         call. = FALSE)
  }

  return(list(result = reslist, headers = req$headers))
}


# Fetch all the results of a query given an API Method
# Will make multiple calls to the API if needed
# API Methods listed here: https://www.meetup.com/meetup_api/docs/
.fetch_results <- function(api_method, api_key = NULL, event_status = NULL, ...) {

  # Build the API endpoint URL
  meetup_api_prefix <- "https://api.meetup.com/"
  api_url <- paste0(meetup_api_prefix, api_method)

  # Get the API key from MEETUP_KEY environment variable if NULL
  if (is.null(api_key)) api_key <- .get_api_key()
  if (!is.character(api_key)) stop("api_key must be a character string")

  # Fetch first set of results (limited to 200 records each call)
  res <- .quick_fetch(api_url = api_url,
                      api_key = api_key,
                      event_status = event_status,
                      offset = 0,
                      ...)

  # Total number of records matching the query
  total_records <- as.integer(res$headers$`x-total-count`)
  if (length(total_records) == 0) total_records <- 1L
  records <- res$result
  cat(paste("Downloading", total_records, "record(s)..."))

  if((length(records) < total_records) & !is.null(res$headers$link)){

    # calculate number of offsets for records above 200
    offsetn <- ceiling(total_records/length(records))
    all_records <- list(records)

    for(i in 1:(offsetn - 1)) {
      res <- .quick_fetch(api_url = api_url,
                          api_key = api_key,
                          event_status = event_status,
                          offset = i,
                          ...)
      all_records[[i + 1]] <- res$result
    }
    records <- unlist(all_records, recursive = FALSE)

  }

  return(records)
}


# helper function to convert a vector of milliseconds since epoch into POSIXct
.date_helper <- function(time) {
  if (is.character(time)) {
    # if date is character string, try to convert to numeric
    time <- tryCatch(expr = as.numeric(time),
                     error = warning("One or more dates could not be converted properly"))
  }
  if (is.numeric(time)) {
    # divide milliseconds by 1000 to get seconds; convert to POSIXct
    seconds <- time / 1000
    out <- as.POSIXct(seconds, origin = "1970-01-01")
  } else {
    # if no conversion can be done, then return NA
    warning("One or more dates could not be converted properly")
    out <- rep(NA, length(time))
  }
  return(out)
}

# function to return meetup.com API key stored in the MEETUP_KEY environment variable
.get_api_key <- function() {
  api_key <- Sys.getenv("MEETUP_KEY")
  if (api_key == "") {
    stop("You have not set a MEETUP_KEY environment variable.\nIf you do not yet have a meetup.com API key, you can retrieve one here:\n  * https://secure.meetup.com/meetup_api/key/",
         call. = FALSE)
  }
  return(api_key)
}
