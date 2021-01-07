# Wrapper for messages, spotted in googlesheets3
spf <- function(...) stop(sprintf(...), call. = FALSE)

# This helper function makes a single call, given the full API endpoint URL
# Used as the workhorse function inside .fetch_results() below
.quick_fetch <- function(api_method,
                         api_key = NULL, # deprecated, unused, can't swallow this in `...`
                         event_status = NULL,
                         offset = 0,
                         ...) {

  # list of parameters
  parameters <- list(status = event_status, # you need to add the status
                     # otherwise it will get only the upcoming event
                     offset = offset,
                     ...                    # other parameters
  )

  # Only need API keys if OAuth is disabled...
  if (!getOption("meetupr.use_oauth")) {
    parameters <- append(parameters, list(key = get_api_key()))
  }

  req <- httr::GET(url = meetup_api_prefix(),          # the host
                   path = api_method,                  # path to append
                   query = parameters,
                   config = meetup_token()
  )

  if (req$status_code == 400) {
    stop("HTTP 400 Bad Request error encountered for: ",
                api_method,".\n As of June 30, 2020, this may be ",
                "because a presumed bug with the Meetup API ",
                "causes this error for a future event. Please ",
                "confirm the event has ended.",
         call. = FALSE)
  }

  httr::stop_for_status(req)
  reslist <- httr::content(req, "parsed")

  if (length(reslist) == 0) {
    warning("Zero records match your filter. Nothing to return.\n",
         call. = FALSE)
    invisible(NULL)
  }

  return(list(result = reslist, headers = req$headers))
}

meetup_api_prefix <- function() {

  env_url <- Sys.getenv("MEETUP_API_URL")

  if(nzchar(env_url)) {
    return(env_url)
  }

  "https://api.meetup.com/"
}

# Fetch all the results of a query given an API Method
# Will make multiple calls to the API if needed
# API Methods listed here: https://www.meetup.com/meetup_api/docs/
.fetch_results <- function(api_method, api_key = NULL, event_status = NULL, verbose = TRUE, ...) {

  # Fetch first set of results (limited to 200 records each call)
  res <- .quick_fetch(api_method = api_method,
                      api_key = api_key,
                      event_status = event_status,
                      offset = 0,
                      ...)

  res <-  .quick_fetch(api_method, event_status = event_status, ...)


  # Total number of records matching the query
  total_records <- as.integer(res$headers$`x-total-count`)
  if (length(total_records) == 0) total_records <- 1L
  records <- res$result
  if(verbose) cat("Downloading", total_records, "record(s)...\n", sep = " ")

  if((length(records) < total_records) & !is.null(res$headers$link)){

    # calculate number of offsets for records above 200
    offsetn <- ceiling(total_records/length(records))
    all_records <- list(records)

    for(i in 1:(offsetn - 1)) {
      res <- .quick_fetch(api_method = api_method,
                          api_key = api_key,
                          event_status = event_status,
                          offset = i,
                          ...)

      next_url <- strsplit(strsplit(res$headers$link, split = "<")[[1]][2], split = ">")[[1]][1]
      next_url <- gsub(meetup_api_prefix(), "", next_url)
      res <- .quick_fetch(next_url, event_status)

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

# Helper to check event status
.check_event_status <- function(event_status){
  match.arg(event_status,
            c("cancelled", "draft", "past", "proposed", "suggested", "upcoming"),
            several.ok = TRUE)
}

#' to avoid making too many
#' requests too rapidly when
#' getting pro events
slowly_get_events <- purrr::slowly(
  get_events,
  rate = purrr::rate_delay(pause = .3,
                           max_times = Inf)
)

.collapse = function(x){
  paste(x, collapse = ",")
}
