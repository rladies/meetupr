context("find_groups")

test_that("find_groups() success case", {

  meetup_groups <- with_mock(
    `httr::GET` = function(url, query, ...) {
      print(getwd())
      load(here::here("tests/testdata/httr_get_find_groups.rda"))
      return(req)
    },
    meetup_groups <- find_groups(api_key = "R-Ladies FTW!",
                                 text = "hihi")
  )

  expect_equal(nrow(meetup_groups), 1, label="check find groups returns one result")
  expect_equal(meetup_groups$name, "R-Ladies London", label="check find groups content (name)")
})
