test_that("meetup_call() success case", {
  api_method <- "rladies-nashville/events"
  vcr::use_cassette("quick_fetch", {
    res <- meetup_call(
      api_method = api_method,
      event_status = "past"
      )
  })
  expect_equal(names(res), c("result", "headers"))
  expect_equal(res$headers$`content-type`, "application/json; charset=utf-8")
})

# TODO .fetch_results()

# TODO .fetch_results() no api key
