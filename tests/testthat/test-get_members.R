expected_names <- c("id", "name", "member_url", "photo_link", "status",
                    "role", "created", "most_recent_visit")

test_that("get_members() works with one status", {
  vcr::use_cassette("get_members", {
    members <-  get_members2("rladies-remote")
  })
  expect_s3_class(members, "data.frame")

  expect_true(
    all(
      names(members) == expected_names
    ))
})
