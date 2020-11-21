test_that("find_groups() success case", {

  vcr::use_cassette("find_groups", {
    groups <- find_groups(text = "R-Ladies", radius = 1)
  })

  expect_s3_class(groups, "data.frame")
})
