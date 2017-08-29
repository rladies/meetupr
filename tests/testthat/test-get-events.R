
test_that(".quick_fetch() works properly", {
  skip_on_travis()
  skip_on_cran()
  api_key <- Sys.getenv("MEETUP_KEY")
  event_status <- "past"
  urlname <- "rladies-nashville"
  meetup_api_prefix <- "https://api.meetup.com/"
  api_url <- paste0(meetup_api_prefix, urlname, "/events")

  res <- .quick_fetch(api_url = api_url,
                      api_key = api_key,
                      event_status = event_status)
  total_records <- as.integer(res$headers$`x-total-count`)
  length_results <- length(res$result)
  expect_equal(total_records,length_results)
})

