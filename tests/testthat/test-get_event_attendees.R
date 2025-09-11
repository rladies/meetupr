test_that("get_events_attendees() works with one status", {
  mock_if_no_auth()
  vcr::use_cassette("get_event_attendees", {
    attendees <- get_event_attendees(id = event_id)
  })

  expect_s3_class(attendees, "data.frame")
  expect_equal(ncol(attendees), 9)
  expect_equal(nrow(attendees), 92)
})


test_that("process_attendees_data includes organized_group_count", {
  mock_attendees <- list(
    list(
      id = "rsvp1",
      status = "yes",
      member = list(
        id = "member1",
        name = "Organizer",
        bio = "Event organizer",
        organizedGroups = list(totalCount = 5)
      )
    )
  )

  result <- process_attendees_data(mock_attendees)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
  expect_equal(result$organized_group_count, 5L)
  expect_equal(result$bio, "Event organizer")
})
