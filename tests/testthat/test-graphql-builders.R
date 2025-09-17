test_that("meetup_template_query creates a meetup_template object", {
  obj <- meetup_template_query(
    template = "template",
    page_info_path = "path.to.pageInfo",
    edges_path = "path.to.edges"
  )

  expect_true(S7::S7_inherits(obj, S7::S7_object))
  expect_equal(obj@template, "template")
  expect_equal(obj@page_info_path, "path.to.pageInfo")
  expect_equal(obj@edges_path, "path.to.edges")
})

test_that("execute handles no data returned", {
  local_mocked_bindings(
    execute_from_template = function(...) list(data = NULL)
  )
  obj <- meetup_template_query("template", "path.to.pageInfo", "path.to.edges")
  result <- execute(obj)
  expect_s3_class(result, "tbl")
})

test_that("execute respects max_results", {
  local_mocked_bindings(
    execute_from_template = function(...) {
      list(
        data = list(
          edges = list(
            list(node = "a"),
            list(node = "b"),
            list(node = "c")
          )
        )
      )
    },
    extract_at_path = function(object, response) response$data$edges
  )
  obj <- meetup_template_query("template", "data.pageInfo", "data.edges")
  result <- execute(obj, max_results = 2)
  expect_equal(nrow(result), 2)
  expect_equal(result$node, c("a", "b"))
})

test_that("execute stops on static cursor", {
  local_mocked_bindings(
    execute_from_template = function(...) {
      list(
        data = list(
          pageInfo = list(hasNextPage = TRUE, endCursor = "cursor1"),
          edges = list(list(node = "a"))
        )
      )
    },
    extract_at_path = function(object, response) response$data$edges
  )
  obj <- meetup_template_query("template", "path.to.pageInfo", "path.to.edges")
  result <- execute(obj)
  expect_equal(result$node, c("a"))
})

test_that("extract_at_path returns appropriate data", {
  response <- list(
    data = list(
      edges = list(
        list(node = "a"),
        list(node = "b")
      )
    )
  )
  obj <- meetup_template_query("template", "path.to.pageInfo", "data.edges")
  result <- extract_at_path(obj, response)
  expect_equal(result, list("a", "b"))
})

test_that("extract_at_path handles non-standard edges", {
  response <- list(data = list(edges = list("a", "b")))
  obj <- meetup_template_query("template", "path.to.pageInfo", "data.edges")
  result <- extract_at_path(obj, response)
  expect_equal(result, list("a", "b"))
})

test_that("get_cursor returns correct cursor", {
  response <- list(
    data = list(pageInfo = list(hasNextPage = TRUE, endCursor = "cursor1"))
  )
  obj <- meetup_template_query("template", "data.pageInfo", "path.to.edges")
  cursor <- get_cursor(obj, response)
  expect_equal(cursor, list(cursor = "cursor1"))
})

test_that("get_cursor returns NULL if no next page", {
  response <- list(data = list(pageInfo = list(hasNextPage = FALSE)))
  obj <- meetup_template_query("template", "data.pageInfo", "path.to.edges")
  cursor <- get_cursor(obj, response)
  expect_null(cursor)
})

test_that("parse_path_to_pluck splits path correctly", {
  path <- "data.pageInfo.endCursor"
  result <- parse_path_to_pluck(path)
  expect_equal(result, c("data", "pageInfo", "endCursor"))
})

test_that("standard_query constructs correctly", {
  result <- standard_query("template", "base.path")
  expect_true(S7::S7_inherits(result, S7::S7_object))

  expect_equal(result@template, "template")
  expect_equal(result@page_info_path, "base.path.pageInfo")
  expect_equal(result@edges_path, "base.path.edges")
})
