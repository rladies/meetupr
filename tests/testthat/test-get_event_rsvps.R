test_that("get_event_rsvps gets data correctly", {
  mock_if_no_auth()
  vcr::use_cassette("get_event_rsvps", {
    result <- get_event_rsvps(id = event_id)
  })
  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
})

test_that("process_rsvps_data extracts RSVP data correctly", {
  mock_rsvps <- list(
    list(
      id = "rsvp1",
      status = "yes",
      guestsCount = 2,
      member = list(
        id = "member1",
        name = "Test Member",
        memberUrl = "https://meetup.com/members/1",
        memberPhoto = list(baseUrl = "https://example.com/photo1.jpg")
      )
    ),
    list(
      id = "rsvp2",
      status = "no",
      guestsCount = 0,
      member = list(
        id = "member2",
        name = "Another Member"
        # memberUrl and memberPhoto missing
      )
    )
  )

  result <- process_rsvps_data(mock_rsvps)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_equal(result$rsvp_id, c("rsvp1", "rsvp2"))
  expect_equal(result$response, c("yes", "no"))
  expect_equal(result$guests_count, c(2L, 0L))
  expect_equal(result$member_name, c("Test Member", "Another Member"))
  expect_true(is.na(result$member_url[2]))
})
