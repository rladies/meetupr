test_that("find_groups() success case", {

  vcr::use_cassette("find_groups", {
    groups <- find_groups(query = "R-Ladies")
  })

  expect_s3_class(groups, "data.frame")
})
