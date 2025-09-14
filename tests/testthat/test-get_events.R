test_that("get_events() works with one status", {
  vcr::use_cassette("get_events", {
    events <- get_events(
      urlname = "rladies-lagos",
      status = "past"
    )
  })

  expect_s3_class(events, "data.frame")
})

test_that("process_event_data handles complete event data", {
  mock_events <- list(
    list(
      id = "event1",
      title = "Test Event",
      eventUrl = "https://example.com/event1",
      createdTime = "2023-01-01T10:00:00Z",
      status = "UPCOMING",
      dateTime = "2023-06-01T18:00:00Z",
      duration = "PT2H",
      description = "A test event",
      group = list(
        id = "group1",
        name = "Test Group",
        urlname = "test-group"
      ),
      venues = list(
        list(
          id = "venue1",
          name = "Test Venue",
          address = "123 Test St",
          city = "Test City",
          state = "TS",
          postalCode = "12345",
          country = "us",
          lat = 40.7128,
          lon = -74.0060,
          venueType = "venue"
        )
      ),
      rsvps = list(totalCount = 25),
      featuredEventPhoto = list(baseUrl = "https://example.com/photo.jpg")
    )
  )

  result <- process_event_data(mock_events)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
  expect_equal(result$id, "event1")
  expect_equal(result$title, "Test Event")
  expect_equal(result$group_id, "group1")
  expect_equal(result$venues_city, "Test City")
  expect_equal(result$venues_lat, 40.7128)
  expect_equal(result$rsvps_total_count, 25L)
})
