expected_names <- c("id", "name", "created", "status", "time", "local_date", "local_time",
                    "waitlist_count", "yes_rsvp_count", "venue_id", "venue_name",
                    "venue_lat", "venue_lon", "venue_address_1", "venue_city", "venue_state",
                    "venue_zip", "venue_country", "description", "link", "resource"
)

test_that("get_events() works with one status", {
  urlname <- "rladies-nashville"
  vcr::use_cassette("get_events", {
    past_events <- get_events(urlname = urlname,
                              event_status = "past")
  })

  expect_s3_class(past_events, "data.frame")
  expect_true(
    all(
      names(past_events) == expected_names
    ))
})

test_that("get_events() works with multiple statuses", {
  skip("Not working for now (the test, not the function)")
  urlname <- "rladies-johannesburg"
  vcr::use_cassette("get_events-2-status", {
    past_events <- get_events(urlname = urlname,
                              event_status = c("past", "upcoming"))
  })

  expect_s3_class(past_events, "data.frame")
  expect_true(
    all(
      names(past_events) == expected_names
    ))

})

test_that("get_events() has informative error messages", {
  urlname <- "rladies-johannesburg"
  expect_error(
    get_events(urlname = urlname, event_status = "pasttt"),
    "should be one of"
    )
  expect_error(
    get_events(event_status = "past")
  )
})
# TODO: event type is not allowed

# TODO: "urlname is missing"


