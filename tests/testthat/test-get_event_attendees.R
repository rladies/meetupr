expected_names <- c("id", "name", "url", "photo", "organized_group_count")

test_that("get_events_attendees() works with one status", {
  vcr::use_cassette("get_event_attendees", {
    attendees <-  get_event_attendees(id = "103349942")
  })
  expect_s3_class(attendees, "data.frame")

  expect_true(
    all(
      names(attendees) == expected_names
    ))
})
