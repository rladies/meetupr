context("get_boards")

test_that("get_boards() no results", {
  options('meetupr.use_oauth' = FALSE)
  set_api_key("yay")

  meetup_events <- with_mock(
    `httr::GET` = function(url, query, ...) {
      load(here::here("tests/testdata/httr_get_empty_content.rda"))
      return(req)
    },
    meetup_boards <- get_boards(api_key="yay",
                                urlname = "<3")
  )

  expect_equal(nrow(meetup_boards), 0, label="check get_boards() returns zero results")
})



