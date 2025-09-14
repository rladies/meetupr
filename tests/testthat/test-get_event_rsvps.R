test_that("get_event_rsvps gets data correctly", {
  mock_if_no_auth()
  vcr::use_cassette("get_event_rsvps", {
    result <- get_event_rsvps(id = event_id)
  })
  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
})
