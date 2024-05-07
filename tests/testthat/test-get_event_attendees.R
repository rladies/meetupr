test_that("get_events_attendees() works with one status", {

  expected_names <- c("id", "name", "url", "photo", "organized_group_count")

  vcr::use_cassette("get_event_attendees", {
    attendees <-  get_event_attendees(id = "103349942")
  })
  expect_s3_class(attendees, "data.frame")

  expect_setequal(expected_names, names(attendees))
})
