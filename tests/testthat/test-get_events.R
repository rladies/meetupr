expected_names <- c("id", "title", "link", "status", "time", "duration",
                   "going", "waiting", "description", "venue_id", "venue_lat",
                   "venue_lon", "venue_name", "venue_address", "venue_city",
                   "venue_state", "venue_zip", "venue_country"
)

test_that("get_events() works with one status", {
  urlname <- "rladies-lagos"
  vcr::use_cassette("get_events", {
    past_events <- get_events(urlname = urlname)
  })

  expect_s3_class(past_events, "data.frame")
  expect_true(
    all(
      names(past_events) == expected_names
    ))
})
