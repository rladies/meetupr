context("get_members")

test_that("get_members() no results", {
  options('meetupr.use_oauth' = FALSE)
  set_api_key("yay")

  meetup_events <- with_mock(
    `httr::GET` = function(url, query, ...) {
      load(here::here("tests/testdata/httr_get_empty_content.rda"))
      return(req)
    },
    meetup_members <- get_members(api_key="yay",
                                urlname = "<3")
  )

  expect_equal(nrow(meetup_members), 0, label="check get_members() returns zero results")
})



