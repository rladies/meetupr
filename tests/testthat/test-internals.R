test_that(".quick_fetch() success case", {
  api_url <- httr::modify_url(meetup_api_prefix(), path = "rladies-nashville/events")
  vcr::use_cassette("quick_fetch", {
    res <- .quick_fetch(
      api_url = api_url,
      event_status = "past"
      )
  })
  expect_equal(names(res), c("result", "headers"))
  expect_equal(res$headers$`content-type`, "application/json; charset=utf-8")
})

# TODO .fetch_results()

# TODO .fetch_results() no api key
