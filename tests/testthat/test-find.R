describe("find_groups", {
  it("success case", {
    mock_if_no_auth()
    vcr::local_cassette("find_groups")
    groups <- find_groups(query = "R-Ladies")
    groups_15 <- find_groups(query = "data science", max_results = 15)

    expect_s3_class(groups, "data.frame")
    expect_equal(nrow(groups), 200)
    expect_equal(nrow(groups_15), 15)
    expect_equal(ncol(groups), 13)
  })

  it("returns correct data structure", {
    mock_if_no_auth()
    vcr::local_cassette("find_groups_correct")
    groups <- find_groups(
      query = "R-Ladies",
      max_results = 10
    )

    expect_s3_class(groups, "data.frame")
    expect_true(nrow(groups) <= 10)
    expect_true("founded_date" %in% names(groups))
  })

  it("processes datetime fields correctly", {
    mock_if_no_auth()
    vcr::local_cassette("find_groups_datetime")
    groups <- find_groups(
      query = "JavaScript",
      max_results = 10
    )

    if (nrow(groups) > 0) {
      expect_s3_class(groups$founded_date, c("POSIXct", "POSIXt"))
    }
  })

  it("handles different max_results values", {
    mock_if_no_auth()
    vcr::local_cassette("find_groups_limits")
    groups_10 <- find_groups(
      query = "Python",
      max_results = 10
    )
    groups_25 <- find_groups(
      query = "Python",
      max_results = 25
    )

    expect_true(nrow(groups_10) <= 10)
    expect_true(nrow(groups_25) <= 25)
    expect_gte(nrow(groups_25), nrow(groups_10))
  })

  it("handles handle_multiples parameter", {
    mock_if_no_auth()
    vcr::local_cassette("find_groups_multiples")
    groups_list <- find_groups(
      query = "React",
      max_results = 10,
      handle_multiples = "list"
    )
    groups_first <- find_groups(
      query = "React",
      max_results = 10,
      handle_multiples = "first"
    )

    expect_s3_class(groups_list, "data.frame")
    expect_s3_class(groups_first, "data.frame")
  })

  it("passes extra_graphql correctly", {
    mock_if_no_auth()

    local_mocked_bindings(
      execute = function(...) {
        args <- list(...)
        expect_equal(args$extra_graphql, "{ customField }")
        data.frame(founded_date = Sys.time())
      }
    )

    result <- find_groups(
      "test",
      max_results = 10,
      extra_graphql = "{ customField }"
    )

    expect_s3_class(result, "data.frame")
  })

  it("uses standard_query correctly", {
    mock_if_no_auth()

    local_mocked_bindings(
      standard_query = function(query_name, data_path) {
        expect_equal(query_name, "find_groups")
        expect_equal(data_path, "data.groupSearch")
        "mock_query"
      },
      execute = function(std_query, ...) {
        expect_equal(std_query, "mock_query")
        data.frame(founded_date = Sys.time())
      }
    )

    result <- find_groups("test")
    expect_s3_class(result, "data.frame")
  })

  it("handles empty query results", {
    mock_if_no_auth()

    local_mocked_bindings(
      execute = function(...) {
        data.frame(founded_date = as.POSIXct(character(0)))
      }
    )

    result <- find_groups("nonexistent_query_string")
    expect_s3_class(result, "data.frame")
    expect_equal(nrow(result), 0)
  })

  it("calls process_datetime_fields correctly", {
    mock_if_no_auth()

    mock_datetime <- as.POSIXct("2023-01-01")

    local_mocked_bindings(
      execute = function(...) {
        data.frame(founded_date = "2023-01-01T00:00:00Z")
      },
      process_datetime_fields = function(data, field) {
        expect_equal(field, "founded_date")
        data$founded_date <- mock_datetime
        data
      }
    )

    result <- find_groups("test")
    expect_equal(result$founded_date, mock_datetime)
  })

  it("works with extra_graphql", {
    mock_if_no_auth()
    vcr::local_cassette("find_groups_extra")

    groups <- find_groups(
      "R Ladies",
      extra_graphql = "description"
    )

    expect_s3_class(groups, "tbl_df")
    expect_true("description" %in% names(groups))
  })

  it("handles asis parameter", {
    mock_if_no_auth()

    vcr::local_cassette("find_groups_asis")
    groups_raw <- find_groups("R Ladies", asis = TRUE)
    groups_processed <- find_groups(
      "R Ladies",
      asis = FALSE
    )

    expect_type(groups_raw, "list")
  })

  it("handles location filter", {
    mock_if_no_auth()
    vcr::local_cassette("find_groups_location")

    groups <- find_groups(
      "R Ladies",
      lat = 51.5074,
      lon = -0.1278,
      radius = 50
    )

    expect_s3_class(groups, "tbl_df")
  })
})

describe("find_topics", {
  it("returns correct data structure", {
    mock_if_no_auth()
    vcr::local_cassette("find_topics")
    topics <- find_topics(query = "Data Science", max_results = 20)

    expect_s3_class(topics, "data.frame")
    expect_true(nrow(topics) <= 20)
  })

  it("handles different max_results values", {
    mock_if_no_auth()
    vcr::local_cassette("find_topics_limits")
    topics_5 <- find_topics(query = "Machine Learning", max_results = 5)
    topics_15 <- find_topics(query = "Machine Learning", max_results = 15)

    expect_gte(nrow(topics_5), 5)
    expect_gte(nrow(topics_15), 15)
    expect_gte(nrow(topics_15), nrow(topics_5))
  })

  it("handles handle_multiples parameter", {
    mock_if_no_auth()
    vcr::local_cassette("find_topics_multiples")
    topics_list <- find_topics(
      query = "AI",
      max_results = 8,
      handle_multiples = "list"
    )
    topics_first <- find_topics(
      query = "AI",
      max_results = 8,
      handle_multiples = "first"
    )

    expect_s3_class(topics_list, "data.frame")
    expect_s3_class(topics_first, "data.frame")
  })

  it("validates empty dots", {
    mock_if_no_auth()
    expect_error(
      find_topics("blockchain", invalid_arg = "value"),
      "invalid_arg"
    )
  })

  it("passes extra_graphql correctly", {
    mock_if_no_auth()

    local_mocked_bindings(
      execute = function(...) {
        args <- list(...)
        expect_equal(args$extra_graphql, "{ additionalInfo }")
        data.frame(name = "test_topic")
      }
    )

    result <- find_topics(
      "test",
      max_results = 5,
      extra_graphql = "{ additionalInfo }"
    )

    expect_s3_class(result, "data.frame")
  })

  it("uses standard_query correctly", {
    mock_if_no_auth()

    local_mocked_bindings(
      standard_query = function(query_name, data_path) {
        expect_equal(query_name, "find_topics")
        expect_equal(data_path, "data.suggestTopics")
        "mock_query"
      },
      execute = function(std_query, ...) {
        expect_equal(std_query, "mock_query")
        data.frame(name = "test_topic")
      }
    )

    result <- find_topics("test")
    expect_s3_class(result, "data.frame")
  })

  it("handles empty query results", {
    mock_if_no_auth()

    local_mocked_bindings(
      execute = function(...) {
        data.frame(name = character(0))
      }
    )

    result <- find_topics("nonexistent_topic")
    expect_s3_class(result, "data.frame")
    expect_equal(nrow(result), 0)
  })
})
