
.quick_fetch <- function(api_url, api_key) {

  req <- httr::GET(url = api_url, query = list(key = api_key))
  if (req$status_code >= 400) {
    stop(sprintf("Meetup API returned an error: HTTP status code %s, %s", req$status_code, req$headers$statusmessage))
  }
  httr::stop_for_status(req)
  reslist <- httr::content(req, "parsed")

  return(list(result = reslist, headers = req$headers))
}



.fetch_results <- function(api_url, api_key) {

    # Fetch first set of results (limited to 200 records each call)
    res <- .quick_fetch(api_url = api_url, api_key = api_key)

    # Total number of records matching the query
    total_records <- as.integer(res$headers$`x-total-count`)
    records <- res$result

    # If you have not yet retrieved all records, calculate the # of remaining calls required
    extra_calls <- ifelse((length(records) < total_records), floor(total_records/length(records)), 0)

    if (extra_calls > 0) {
      all_records <- list(records)
      for (i in seq(extra_calls)) {
        # Keep making API requests with an increasing offset value until you get all the records
        # TO DO: clean this strsplit up or replace with regex
        next_url <- strsplit(strsplit(res$headers$link, split = "<")[[1]][2], split = ">")[[1]][1]
        res <- .quick_fetch(next_url, api_key)
        all_records[[i+1]] <- res$result
      }
      records <- unlist(all_records, recursive = FALSE)
    }
    return(records)
}
