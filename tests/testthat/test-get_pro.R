test_that("get_pro_groups() works", {
  mock_if_no_auth()
  vcr::use_cassette("get_pro_groups", {
    groups <- get_pro_groups(urlname = "rladies")
  })
  expect_s3_class(groups, "data.frame")
})

test_that("get_pro_events() works", {
  mock_if_no_auth()
  vcr::use_cassette("get_pro_events", {
    events <- get_pro_events(urlname = "rladies", status = "active")
  })
  expect_s3_class(events, "data.frame")
})
