expected_names <- c("member_id", "member_name", "member_url", "member_is_host",
                    "response", "guests", "event_id", "event_title",
                    "event_url", "created", "updated")

test_that("get_event_rsvps() works with one status", {
  vcr::use_cassette("get_event_rspvs", {
    rsvps <-  get_event_rsvps(id = "103349942")
  })
  expect_s3_class(rsvps, "data.frame")

  expect_true(
    all(
      names(rsvps) == expected_names
    ))
})
