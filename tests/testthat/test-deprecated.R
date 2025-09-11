test_that(".fetch_results throws deprecation error", {
  expect_error(
    .fetch_results(),
    "REST API functions are no longer supported",
    fixed = TRUE
  )
})

test_that("meetup_call throws deprecation error", {
  expect_error(
    meetup_call(),
    "REST API functions are no longer supported",
    fixed = TRUE
  )
})

test_that(".quick_fetch throws deprecation error", {
  expect_error(
    .quick_fetch(),
    "REST API functions are no longer supported",
    fixed = TRUE
  )
})

test_that("get_meetup_comments warns about using get_event_comments", {
  expect_warning(
    get_meetup_comments(),
    "get_event_comments"
  )
})
