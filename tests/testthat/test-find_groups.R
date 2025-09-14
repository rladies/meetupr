test_that("find_groups() success case", {
  mock_if_no_auth()
  vcr::use_cassette("find_groups", {
    groups <- find_groups(query = "R-Ladies")
    groups_15 <- find_groups(query = "data science", max_results = 15)
  })

  expect_s3_class(groups, "data.frame")
  expect_equal(nrow(groups), 200)
  expect_equal(nrow(groups_15), 15)
  expect_equal(ncol(groups), 15)
})

test_that("find_groups ensures extra arguments (...) are empty", {
  mock_if_no_auth()
  expect_error(
    find_groups("test", invalid_arg = TRUE),
    "invalid_arg"
  )
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
