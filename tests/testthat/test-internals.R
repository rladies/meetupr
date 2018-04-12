context("internals")

test_that(".quick_fetch() success case", {
  res <- with_mock(
    `httr::GET` = function(url, query, ...) {
      print(getwd())
      load(here::here("tests/testdata/httr_get_find_groups.rda"))
      return(req)
    },
    res <- .quick_fetch(api_url = "fake url", # intentionally invalid as there is currently no validation
                      api_key = "I <3 R-Ladies")
    )

  expect_equal(names(res), c("result", "headers"), info="check .quick_fetch() return value")
  expect_equal(res$headers$`content-type`, "application/json;charset=utf-8", info="check .quick_fetch() header content-type")
})

# TODO .fetch_results()

# TODO .fetch_results() no api key
