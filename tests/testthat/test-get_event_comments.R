context("get_event_attendees")

test_that("get_event_attendees() no results", {
  options('meetupr.use_oauth' = FALSE)
  set_api_key("yay")

  meetup_events <- with_mock(
    `httr::GET` = function(url, query, ...) {
      load(here::here("tests/testdata/httr_get_empty_content.rda"))
      return(req)
    },
    meetup_event_attendees <- get_event_attendees(api_key="yay",
                                urlname = "<3",
                                event_id = 1)
  )

  expect_equal(nrow(meetup_event_attendees), 0, label="check get_event_attendees() returns zero results")
})

# TODO check no event id throws error
# TODO no urlname throws error



