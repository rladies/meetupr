expected_names <- c("id", "comment", "created", "like_count", "member_id", "member_name", "link" )

test_that("get_event_comments() works with one status", {
  vcr::use_cassette("get_event_comments", {
    comments <-  get_event_comments2(id = "103349942")
  })
  expect_s3_class(comments, "data.frame")

  expect_true(
    all(
      names(comments) == expected_names
    ))
})
