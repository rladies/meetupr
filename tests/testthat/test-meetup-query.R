test_that("create_meetup_query builds valid MeetupQuery object", {
  mock_processor <- function(x) dplyr::tibble(id = character(0))

  query <- create_meetup_query(
    template = "test_template",
    page_info_path = "data.test.pageInfo",
    edges_path = "data.test.edges",
    total_path = "data.test.totalCount",
    process_data = mock_processor
  )

  expect_s7_class(query, MeetupQuery)
})


test_that("create_pro_query builds correct paths", {
  mock_processor <- function(x) dplyr::tibble(id = character(0))

  groups_query <- create_pro_query(
    "get_pro_groups",
    "groupsSearch",
    mock_processor
  )

  events_query <- create_pro_query(
    "get_pro_events",
    "eventsSearch",
    mock_processor
  )
  expect_s7_class(groups_query, MeetupQuery)
  expect_s7_class(events_query, MeetupQuery)
  expect_equal(groups_query@template, "get_pro_groups")
  expect_equal(events_query@template, "get_pro_events")
})
