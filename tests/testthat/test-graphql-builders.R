describe("meetupr_template_query", {
  it("creates a meetupr_template object", {
    obj <- meetupr_template_query(
      template = "template",
      page_info_path = "path.to.pageInfo",
      edges_path = "path.to.edges"
    )

    expect_true(S7::S7_inherits(obj, S7::S7_object))
    expect_equal(obj@template, "template")
    expect_equal(obj@page_info_path, "path.to.pageInfo")
    expect_equal(obj@edges_path, "path.to.edges")
  })
})

describe("execute", {
  it("handles no data returned", {
    local_mocked_bindings(
      execute_from_template = function(...) list(data = NULL)
    )
    obj <- meetupr_template_query(
      "template",
      "path.to.pageInfo",
      "path.to.edges"
    )
    result <- execute(obj)
    expect_s3_class(result, "tbl")
  })

  it("respects max_results", {
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
      extract_at_path = function(response, ...) response$data$edges
    )
    obj <- meetupr_template_query(
      "template",
      "data.pageInfo",
      "data.edges"
    )
    result <- execute(obj, max_results = 2)
    expect_equal(nrow(result), 2)
    expect_equal(result$node, c("a", "b"))
  })

  it("stops on static cursor", {
    local_mocked_bindings(
      execute_from_template = function(...) {
        list(
          data = list(
            pageInfo = list(hasNextPage = TRUE, endCursor = "cursor1"),
            edges = list(list(node = "a"))
          )
        )
      },
      extract_at_path = function(response, ...) response$data$edges
    )
    obj <- meetupr_template_query(
      "template",
      "path.to.pageInfo",
      "path.to.edges"
    )
    result <- execute(obj)
    expect_equal(result$node, c("a"))
  })

  it("asis parameter controls output format", {
    mock_response <- list(
      data = list(
        edges = list(
          list(node = list(id = "1", name = "First")),
          list(node = list(id = "2", name = "Second"))
        ),
        pageInfo = list(hasNextPage = FALSE)
      )
    )

    local_mocked_bindings(
      execute_from_template = function(...) mock_response
    )

    obj <- meetupr_template_query(
      template = "template",
      page_info_path = "data.pageInfo",
      edges_path = "data.edges"
    )

    result_raw <- execute(obj, asis = TRUE)
    expect_type(result_raw, "list")
    expect_false(inherits(result_raw, "tbl_df"))
    expect_length(result_raw, 2)
    expect_equal(result_raw[[1]]$node$id, "1")
    expect_equal(result_raw[[2]]$node$id, "2")

    result_processed <- execute(obj, asis = FALSE)
    expect_s3_class(result_processed, "tbl_df")
    expect_equal(nrow(result_processed), 2)
    expect_true("id" %in% names(result_processed))
    expect_true("name" %in% names(result_processed))
  })
})

describe("extract_at_path", {
  it("returns appropriate data", {
    response <- list(
      data = list(
        edges = list(
          list(node = "a"),
          list(node = "b")
        )
      )
    )
    obj <- meetupr_template_query("template", "path.to.pageInfo", "data.edges")
    result <- extract_at_path(response, "data.edges")
    expect_length(result, 2)
    expect_equal(result[[1]]$node, "a")
    expect_equal(result[[2]]$node, "b")
  })

  it("handles non-standard edges", {
    response <- list(data = list(edges = list("a", "b")))
    obj <- meetupr_template_query("template", "path.to.pageInfo", "data.edges")
    result <- extract_at_path(response, "data.edges")
    expect_equal(result, list("a", "b"))
  })
})

describe("get_cursor", {
  it("returns correct cursor", {
    response <- list(
      data = list(pageInfo = list(hasNextPage = TRUE, endCursor = "cursor1"))
    )
    obj <- meetupr_template_query("template", "data.pageInfo", "path.to.edges")
    cursor <- get_cursor(response, "data.pageInfo")
    expect_equal(cursor, list(cursor = "cursor1"))
  })

  it("returns NULL if no next page", {
    response <- list(data = list(pageInfo = list(hasNextPage = FALSE)))
    cursor <- get_cursor(response, "data.pageInfo")
    expect_null(cursor)
  })
})

describe("parse_path_to_pluck", {
  it("splits path correctly", {
    path <- "data.pageInfo.endCursor"
    result <- parse_path_to_pluck(path)
    expect_equal(result, c("data", "pageInfo", "endCursor"))
  })
})

describe("standard_query", {
  it("constructs correctly", {
    result <- standard_query("template", "base.path")
    expect_true(S7::S7_inherits(result, S7::S7_object))

    expect_equal(result@template, "")
    expect_equal(result@page_info_path, "base.path.pageInfo")
    expect_equal(result@edges_path, "base.path.edges")
  })
})
