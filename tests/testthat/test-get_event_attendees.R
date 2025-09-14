test_that("get_events_attendees() works with one status", {
  mock_if_no_auth()
  vcr::use_cassette("get_event_attendees", {
    attendees <- get_event_attendees(id = event_id)
  })

  expect_s3_class(attendees, "data.frame")
  expect_equal(ncol(attendees), 8)
  expect_equal(nrow(attendees), 92)
})
