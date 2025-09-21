test_that(".fetch_results throws deprecation error", {
  expect_warning(
    .fetch_results()
  )
})

test_that("meetup_call throws deprecation error", {
  expect_warning(
    meetup_call()
  )
})

test_that(".quick_fetch throws deprecation error", {
  expect_warning(
    .quick_fetch()
  )
})

test_that("get_meetup_comments warns about using get_event_comments", {
  expect_error(
    get_meetup_comments()
  )
})
