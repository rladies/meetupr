test_that("get_members() works with one status", {
  mock_if_no_auth()
  vcr::use_cassette("get_members", {
    members <- get_members("rladies-lagos")
  })
  expect_s3_class(members, "data.frame")
})

test_that("get_members validates ellipsis", {
  expect_error(get_members("valid_url", extra_parameter = "unexpected"))
})
