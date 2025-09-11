test_that("create_meetup_query builds valid MeetupQuery object", {
  mock_processor <- function(x) dplyr::tibble(id = character(0))

  query <- create_meetup_query(
    template = "test_template",
    pageinfo_path = "data.test.pageInfo",
    edges_path = "data.test.edges",
    total_path = "data.test.totalCount",
    data_processor_fn = mock_processor
  )

  expect_s7_class(query, MeetupQuery)
})

test_that("create_event_query creates proper event query", {
  query <- create_event_query("get_events")

  expect_s7_class(query, MeetupQuery)
  expect_equal(query@template, "get_events")

  # Test the transform function is applied (country name addition)
  mock_response <- list(
    data = list(
      groupByUrlname = list(
        events = list(
          edges = list(
            list(
              node = list(
                id = "test",
                venues = list(list(country = "us"))
              )
            )
          )
        )
      )
    )
  )

  extracted <- query@extract_fn(mock_response)
  expect_length(extracted, 1)
  expect_equal(extracted[[1]]$country_name, "United States")
})

test_that("create_rsvp_query creates proper RSVP query", {
  query <- create_rsvp_query("get_events_rsvps")

  expect_s7_class(query, MeetupQuery)
  expect_equal(query@template, "get_events_rsvps")

  # Test with mock RSVP data
  mock_response <- list(
    data = list(
      event = list(
        rsvps = list(
          pageInfo = list(hasNextPage = FALSE),
          edges = list(
            list(
              node = list(
                id = "rsvp1",
                status = "yes",
                member = list(id = "member1", name = "Test User")
              )
            )
          )
        )
      )
    )
  )

  extracted <- query@extract_fn(mock_response)
  expect_length(extracted, 1)
  expect_equal(extracted[[1]]$id, "rsvp1")
})

test_that("create_members_query handles special cursor format", {
  query <- create_members_query(100)

  expect_s7_class(query, MeetupQuery)
  expect_equal(query@template, "get_members")

  # Test cursor function returns 'after' instead of 'cursor'
  mock_response <- list(
    data = list(
      groupByUrlname = list(
        memberships = list(
          pageInfo = list(hasNextPage = TRUE, endCursor = "test_cursor"),
          edges = list(list(node = list()))
        )
      )
    )
  )

  cursor_result <- query@cursor_fn(mock_response)
  expect_equal(cursor_result$after, "test_cursor")
  expect_null(cursor_result$cursor)
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
