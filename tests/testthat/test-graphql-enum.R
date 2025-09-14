test_that("validate_event_status returns when input is NULL", {
  expect_equal(
    validate_event_status(),
    valid_event_status
  )
})

test_that("validate_event_status validates single valid status", {
  expect_equal(validate_event_status("PAST"), "PAST")
})

test_that("validate_event_status validates multiple valid statuses", {
  expect_equal(
    validate_event_status(
      c("DRAFT", "PAST")
    ),
    c("DRAFT", "PAST")
  )
})

test_that("validate_event_status throws an error for invalid status", {
  expect_error(
    validate_event_status("INVALID"),
    "Invalid event status"
  )
})
