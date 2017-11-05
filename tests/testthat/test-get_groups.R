context("get_groups")

test_that("Exact query rladieslondon returns 1 group", {
  skip_on_travis()
  skip_on_cran()
  meetup_groups <- get_groups(api_key = Sys.getenv("MEETUP_KEY"),
                              text = "rladieslondon")
  expect_equal(dim(meetup_groups), c(1, 12))
})
