test_that("validate_event_status returns all valid statuses when input is NULL", {
  expect_equal(validate_event_status(), valid_event_status)
})


test_that("validate_event_status filters valid statuses correctly", {
  expect_equal(
    validate_event_status(c("ACTIVE", "PAST")),
    c("ACTIVE", "PAST")
  )
  expect_equal(
    validate_event_status(c("active", "Past")),
    c("ACTIVE", "PAST")
  )
})


test_that("validate_event_status handles invalid statuses", {
  expect_error(
    validate_event_status(c("INVALID", "ACTIVE")),
    regexp = "Invalid event status:"
  )
})


test_that("validate_event_status handles case insensitivity and uniqueness", {
  expect_equal(
    validate_event_status(c("active", "ACTIVE")),
    c("ACTIVE")
  )
})
