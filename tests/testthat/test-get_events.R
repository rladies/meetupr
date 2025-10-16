test_that("get_events() works with one status", {
  vcr::local_cassette("get_events")
  events <- get_events(
    urlname = "rladies-lagos",
    status = "past"
  )

  expect_s3_class(events, "data.frame")
})

test_that("get_event_rsvps gets data correctly", {
  mock_if_no_auth()
  result <- get_event_rsvps(id = event_id)
  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
})


test_that("get_event_comments() works with one status", {
  vcr::local_cassette("get_event_comments")
  expect_warning(
    comments <- get_event_comments(id = event_id)
  )
  expect_s3_class(comments, "data.frame")
  expect_equal(ncol(comments), 7)
  expect_equal(nrow(comments), 0)
})

test_that("get_event_comments returns warning and empty tibble", {
  withr::local_tempdir()
  expect_warning(
    result <- get_event_comments(id = "103349942"),
    "Event comments functionality has been removed"
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
  expect_true(all(
    names(result) %in%
      c(
        "id",
        "comment",
        "created",
        "like_count",
        "member_id",
        "member_name",
        "link"
      )
  ))
})

test_that("create_empty_comments_tibble returns empty tibble", {
  result <- create_empty_comments_tibble()

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
  expect_true(all(
    names(result) %in%
      c(
        "id",
        "comment",
        "created",
        "like_count",
        "member_id",
        "member_name",
        "link"
      )
  ))
})
