
api_key <- Sys.getenv("rladies_api_key")
event_status <- "past"
urlname <- "rladies-san-francisco"
meetup_api_prefix <- "https://api.meetup.com/"
api_url <- paste0(meetup_api_prefix, urlname, "/events")

res <- .quick_fetch(api_url = api_url,
                    api_key = api_key,
                    event_status = event_status)

total_records <- as.integer(res$headers$`x-total-count`)
length_results <- length(res$result)


test_that("parse content is null if no body", {
  total_records <- as.integer(res$headers$`x-total-count`)
  length_results <- length(res$result)
  expect_equal(total_records,length_results)
})

