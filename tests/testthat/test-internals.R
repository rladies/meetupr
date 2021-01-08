test_that(".quick_fetch() success case", {
  api_method <- "rladies-nashville/events"
  vcr::use_cassette("quick_fetch", {
    res <- .quick_fetch(
      api_method = api_method,
      event_status = "past"
      )
  })
  expect_equal(names(res), c("result", "headers"))
  expect_equal(res$headers$`content-type`, "application/json; charset=utf-8")
})

test_that(".quick_fetch() empty case", {
  api_method <- "rladies-nashville/events"
  vcr::skip_if_vcr_off()
  vcr::use_cassette("quick_fetch_empty", {
    res <- testthat::expect_warning(.quick_fetch(
      api_method = api_method,
      event_status = "upcoming"
    ))
  })
  expect_equal(names(res), c("result", "headers"))
  expect_equal(res$headers$`content-type`, "application/json; charset=utf-8")
})


# TODO .fetch_results()

# TODO .fetch_results() no api key
