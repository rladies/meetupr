test_that("find_groups() success case", {
  mock_if_no_auth()
  vcr::use_cassette("find_groups", {
    groups <- find_groups(query = "R-Ladies")
    groups_15 <- find_groups(query = "data science", max_results = 15)
  })

  expect_s3_class(groups, "data.frame")
  expect_equal(nrow(groups), 200)
  expect_equal(nrow(groups_15), 15)
  expect_equal(ncol(groups), 17)
})

test_that("find_groups ensures extra arguments (...) are empty", {
  mock_if_no_auth()
  expect_error(
    find_groups("test", invalid_arg = TRUE),
    "invalid_arg"
  )
})

test_that("process_groups_data extracts group metadata", {
  mock_groups <- list(
    list(
      id = "group1",
      name = "Test Group",
      urlname = "test-group",
      city = "Test City",
      state = "TS",
      country = "us",
      lat = 40.7128,
      lon = -74.0060,
      memberships = list(totalCount = 150),
      foundedDate = "2020-01-01T00:00:00Z",
      timezone = "America/New_York",
      joinMode = "OPEN",
      who = "Members",
      isPrivate = FALSE,
      category = list(
        id = "cat1",
        name = "Tech"
      ),
      membershipMetadata = list(status = "MEMBER")
    )
  )

  result <- process_groups_data(mock_groups)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
  expect_equal(result$membership_count, 150L)
  expect_equal(result$category_name, "Tech")
  expect_equal(result$membership_status, "MEMBER")
  expect_false(result$is_private)
})

test_that("process_groups_data handles datetime conversion", {
  mock_groups <- list(
    list(
      id = "group1",
      name = "Test Group",
      foundedDate = "2020-01-01T00:00:00Z"
    )
  )

  result <- process_groups_data(mock_groups)

  expect_s3_class(result, "tbl_df")
  expect_s3_class(result$founded_date, "POSIXct")
})
