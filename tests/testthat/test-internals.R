context("internals")

test_that(".quick_fetch() success case", {
  withr::local_options(list(meetupr.use_oauth = FALSE))
  set_api_key("yay")

  res <- with_mock(
    `httr::GET` = function(url, query, ...) {
      load(here::here("tests/testdata/httr_get_find_groups.rda"))
      return(req)
    },
    # intentionally invalid as there is currently no validation
    res <- .quick_fetch(api_url = "fake url")
    )

  expect_equal(names(res), c("result", "headers"), info="check .quick_fetch() return value")
  expect_equal(res$headers$`content-type`, "application/json;charset=utf-8", info="check .quick_fetch() header content-type")
})

# TODO .fetch_results()

# TODO .fetch_results() no api key
