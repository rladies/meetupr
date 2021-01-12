test_that("get_pro_groups() works", {
  vcr::use_cassette("get_pro_groups", {
    groups <- get_pro_groups(urlname = "rladies",
                                  verbose = TRUE)
  })
  expect_s3_class(groups, "data.frame")
  expect_true(
    all(
      names(groups) == c("id", "name", "urlname", "status", "lat", "lon", "city", "state",
                         "country", "created", "members", "upcoming_events", "past_events",
                         "res")
    ))
})

test_that("get_pro_events() works", {
  vcr::use_cassette("get_pro_events", {
    events <- get_pro_events(urlname = "rladies",
                             verbose = TRUE)
  })
  expect_s3_class(events, "data.frame")
  expect_true(
    all(
      names(events) == c("id", "name", "created", "status", "time", "local_date", "duration",
                         "local_time", "waitlist_count", "yes_rsvp_count", "venue_id",
                         "venue_name", "venue_lat", "venue_lon", "venue_address_1", "venue_city",
                         "venue_state", "venue_zip", "venue_country", "description", "link",
                         "resource", "group_id", "group_name", "group_urlname", "group_status",
                         "group_lat", "group_lon", "group_city", "group_state", "group_country",
                         "group_res")
    ))
})
