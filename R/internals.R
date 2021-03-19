# Wrapper for messages, spotted in googlesheets3
spf <- function(...) stop(sprintf(...), call. = FALSE)

# This helper function makes a single call, given the full API endpoint URL
# Used as the workhorse function inside .fetch_results() below

.meetup_call <- function(api_path,
                         event_status = NULL,
                         offset = 0,
                         verbose = NULL,
                         ...) {
  # list of parameters
  parameters <- list(status = event_status, # you need to add the status
                     # otherwise it will get only the upcoming event
                     offset = offset,
                     ...                    # other parameters
  )

  req <- httr::GET(url = meetup_api_prefix(),          # the host
                   path = api_path,                  # path to append
                   query = parameters,
                   config = meetup_token()
  )

  if (req$status_code == 400) {
    stop("HTTP 400 Bad Request error encountered for: ",
         api_path,".\n As of June 30, 2020, this may be ",
                "because a presumed bug with the Meetup API ",
                "causes this error for a future event. Please ",
                "confirm the event has ended.",
         call. = FALSE)
  }

  httr::stop_for_status(req)

  headers <- httr::headers(req)

  assign(
    "meetupr_rate",
    c(headers$`x-ratelimit-limit`, headers$`x-ratelimit-reset`),
    envir = .meetupr_env
    )

  reslist <- httr::content(req, "parsed")

  if (length(reslist) == 0) {
    if(verbose) {
      cat("Zero records match your filter. Nothing to return.\n")
    }
    return(NULL)
  }

  return(list(result = reslist, headers = req$headers))
}
# from https://stackoverflow.com/questions/34254716/how-to-define-hidden-global-variables-inside-r-packages
.meetupr_env <- new.env(parent=emptyenv())
assign("meetupr_rate", c(30, 10), envir=.meetupr_env)

meetup_call <- ratelimitr::limit_rate(
  .meetup_call,
  rate = ratelimitr::rate(
    .meetupr_env[["meetupr_rate"]][1],
    .meetupr_env[["meetupr_rate"]][2]
  )
)


meetup_api_prefix <- function() {

  Sys.getenv("MEETUP_API_URL", "https://api.meetup.com/")
}

# Fetch all the results of a query given an API Method
# Will make multiple calls to the API if needed
# API Methods listed here: https://www.meetup.com/meetup_api/docs/
.fetch_results <- function(api_path, event_status = NULL, verbose = TRUE, ...) {

  # Fetch first set of results (limited to 200 records each call)
  res <- meetup_call(api_path = api_path,
                      event_status = event_status,
                      offset = 0,
                      verbose = verbose,
                      ...)

  # Total number of records matching the query
  total_records <- as.integer(res$headers$`x-total-count`)
  if (length(total_records) == 0) total_records <- 1L
  records <- res$result

  if (total_records == 0) {
    return(res$result)
  }

  if(verbose) cat("Downloading", total_records, "record(s)...\n", sep = " ")

  if((length(records) < total_records) & !is.null(res$headers$link)){

    # calculate number of offsets for records above 200
    max_pages <- ceiling(total_records/length(records))
    all_records <- list(records)

    # Paginate over res. First page already exists in res and all_records, so we can
    # start from page 2 using the next_page api data returned from Meetup.
    for(i in 2:max_pages) {
      next_url <- strsplit(strsplit(res$headers$link, split = "<")[[1]][2], split = ">")[[1]][1]
      next_url <- gsub(meetup_api_prefix(), "", next_url)
      res <- meetup_call(next_url, event_status, offset = NULL) # offset is already in the next_url

      all_records[[i]] <- res$result
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

.collapse = function(x){
  paste(x, collapse = ",")
}

