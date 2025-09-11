test_that("MeetupQuery S7 class is properly defined", {
  # Test class properties
  expect_true(S7::S7_inherits(MeetupQuery, S7::S7_object))
})

test_that("MeetupQuery can be constructed with valid properties", {
  query <- MeetupQuery(
    template = "test_template",
    cursor_fn = function(x) NULL,
    total_fn = function(x) 0L,
    extract_fn = function(x) list(),
    finalizer_fn = function(x) data.frame()
  )

  expect_s7_class(query, MeetupQuery)
  expect_equal(query@template, "test_template")
  expect_true(is.function(query@cursor_fn))
  expect_true(is.function(query@total_fn))
  expect_true(is.function(query@extract_fn))
  expect_true(is.function(query@finalizer_fn))
})

test_that("MeetupQuery validates property types", {
  expect_error(
    MeetupQuery(
      template = 123, # Should be character
      cursor_fn = function(x) NULL,
      total_fn = function(x) 0L,
      extract_fn = function(x) list(),
      finalizer_fn = function(x) data.frame()
    ),
    "object properties are invalid"
  )

  expect_error(
    MeetupQuery(
      template = "test",
      cursor_fn = "not_a_function", # Should be function
      total_fn = function(x) 0L,
      extract_fn = function(x) list(),
      finalizer_fn = function(x) data.frame()
    ),
    "object properties are invalid"
  )
})


test_that("execute generic works with MeetupQuery", {
  mock_if_no_auth()

  # Create a simple mock query
  test_query <- MeetupQuery(
    template = "test_template",
    cursor_fn = function(x) NULL, # No pagination
    total_fn = function(x) 1L,
    extract_fn = function(x) list(list(id = "test", name = "Test Item")),
    finalizer_fn = function(x) {
      dplyr::tibble(
        id = purrr::map_chr(x, "id", .default = NA_character_),
        name = purrr::map_chr(x, "name", .default = NA_character_)
      )
    }
  )

  # Mock the execute_from_template function
  local_mocked_bindings(
    execute_from_template = function(...) {
      list(data = list(test = list(id = "test", name = "Test Item")))
    }
  )

  result <- execute(test_query, test_param = "value")

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
  expect_equal(result$id, "test")
  expect_equal(result$name, "Test Item")
})

test_that("execute handles pagination correctly", {
  mock_if_no_auth()

  call_count <- 0

  # Create a query that returns data on first call, empty on second
  test_query <- MeetupQuery(
    template = "test_template",
    cursor_fn = function(x) {
      if (call_count == 1) {
        list(cursor = "next_page")
      } else {
        NULL
      }
    },
    total_fn = function(x) 2L,
    extract_fn = function(x) {
      if (call_count == 1) {
        list(list(id = "item1"))
      } else if (call_count == 2) {
        list(list(id = "item2"))
      } else {
        list()
      }
    },
    finalizer_fn = function(x) {
      dplyr::tibble(
        id = purrr::map_chr(x, "id", .default = NA_character_)
      )
    }
  )

  local_mocked_bindings(
    execute_from_template = function(...) {
      call_count <<- call_count + 1
      list(data = list())
    }
  )

  result <- execute(test_query, .progress = FALSE)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2)
  expect_equal(result$id, c("item1", "item2"))
  expect_equal(call_count, 2)
})

test_that("parse_path_to_pluck works correctly", {
  expect_equal(
    parse_path_to_pluck("data.groupSearch.pageInfo"),
    c("data", "groupSearch", "pageInfo")
  )

  expect_equal(
    parse_path_to_pluck("simple"),
    "simple"
  )

  expect_equal(
    parse_path_to_pluck("a.b.c.d.e"),
    c("a", "b", "c", "d", "e")
  )
})

test_that("build_standard_pagination creates correct cursor function", {
  pagination <- build_standard_pagination(
    "data.test.pageInfo",
    "data.test.edges",
    max_results = 10
  )

  expect_true(is.function(pagination$cursor_fn))
  expect_true(is.function(pagination$get_results_fetched))

  # Test with hasNextPage = TRUE
  response_with_next <- list(
    data = list(
      test = list(
        pageInfo = list(hasNextPage = TRUE, endCursor = "cursor123"),
        edges = list(list(node = list(id = "1")), list(node = list(id = "2")))
      )
    )
  )

  cursor_result <- pagination$cursor_fn(response_with_next)
  expect_equal(cursor_result$cursor, "cursor123")

  # Test with hasNextPage = FALSE
  response_no_next <- list(
    data = list(
      test = list(
        pageInfo = list(hasNextPage = FALSE, endCursor = "cursor123"),
        edges = list(list(node = list(id = "1")))
      )
    )
  )

  cursor_result <- pagination$cursor_fn(response_no_next)
  expect_null(cursor_result)
})

test_that("build_standard_pagination respects max_results", {
  pagination <- build_standard_pagination(
    "data.test.pageInfo",
    "data.test.edges",
    max_results = 3
  )

  # First call - should continue (2 items, under limit)
  response1 <- list(
    data = list(
      test = list(
        pageInfo = list(hasNextPage = TRUE, endCursor = "cursor1"),
        edges = list(list(node = list(id = "1")), list(node = list(id = "2")))
      )
    )
  )

  cursor_result1 <- pagination$cursor_fn(response1)
  expect_equal(cursor_result1$cursor, "cursor1")

  # Second call - should stop (would exceed max_results)
  response2 <- list(
    data = list(
      test = list(
        pageInfo = list(hasNextPage = TRUE, endCursor = "cursor2"),
        edges = list(list(node = list(id = "3")), list(node = list(id = "4")))
      )
    )
  )

  cursor_result2 <- pagination$cursor_fn(response2)
  expect_null(cursor_result2) # Should stop due to max_results
})

test_that("build_edge_extractor extracts nodes correctly", {
  extractor <- build_edge_extractor("data.test.edges", node_only = TRUE)

  response <- list(
    data = list(
      test = list(
        edges = list(
          list(node = list(id = "1", name = "Item 1")),
          list(node = list(id = "2", name = "Item 2"))
        )
      )
    )
  )

  result <- extractor(response)
  expect_length(result, 2)
  expect_equal(result[[1]]$id, "1")
  expect_equal(result[[2]]$name, "Item 2")
})

test_that("build_total_counter works correctly", {
  counter <- build_total_counter("data.test.totalCount")

  response <- list(data = list(test = list(totalCount = 42)))
  result <- counter(response)
  expect_equal(result, 42)

  # Test with missing count
  response_missing <- list(data = list(test = list()))
  result <- counter(response_missing)
  expect_equal(result, 0)
})
