describe("get_event_rsvps", {
  it("gets data correctly", {
    mock_if_no_auth()
    vcr::local_cassette("get_event_rsvps")
    result <- get_event_rsvps(id = event_id)
    expect_s3_class(result, "tbl_df")
    expect_true(nrow(result) > 0)
  })

  it("works with handle_multiples parameter", {
    mock_if_no_auth()
    vcr::local_cassette("get_event_rsvps")

    result <- get_event_rsvps(
      id = event_id,
      handle_multiples = "first"
    )

    expect_s3_class(result, "tbl_df")
  })

  it("respects max_results", {
    mock_if_no_auth()
    vcr::local_cassette("get_event_rsvps_max")

    result <- get_event_rsvps(
      id = event_id,
      max_results = 5
    )

    expect_s3_class(result, "tbl_df")
    expect_lte(nrow(result), 5)
  })
})

describe("get_event_comments", {
  it("returns empty", {
    expect_warning(
      comments <- get_event_comments(id = event_id),
      "no longer available"
    )
    expect_s3_class(comments, "data.frame")
    expect_equal(ncol(comments), 7)
    expect_equal(nrow(comments), 0)
  })

  it("returns warning and empty tibble", {
    withr::local_tempdir()
    expect_warning(
      result <- get_event_comments(id = "103349942"),
      "Event comments functionality has been removed"
    )

    expect_s3_class(result, "tbl_df")
    expect_equal(nrow(result), 0)
    expect_true(all(
      names(result) %in%
        c(
          "id",
          "comment",
          "created",
          "like_count",
          "member_id",
          "member_name",
          "link"
        )
    ))
  })
})

describe("get_event", {
  it("retrieves event data", {
    mock_if_no_auth()
    vcr::local_cassette("get_event")

    result <- get_event(id = event_id)

    expect_s3_class(result, "meetupr_event")
    expect_s3_class(result, "list")
    expect_true("id" %in% names(result))
    expect_true("title" %in% names(result))
    expect_true("eventUrl" %in% names(result))
    expect_true("status" %in% names(result))
  })

  it("returns proper structure", {
    mock_if_no_auth()
    vcr::local_cassette("get_event")

    result <- get_event(id = event_id)

    expect_true(!is.null(result$id))
    expect_true(!is.null(result$title))
    expect_type(result, "list")
    expect_true(inherits(result, "meetupr_event"))
  })

  it("print.meetupr_event snapshot test", {
    mock_if_no_auth()
    vcr::local_cassette("get_event")

    event <- get_event(id = event_id)

    expect_snapshot(print(event))
  })

  it("print.meetupr_event returns invisibly", {
    mock_if_no_auth()
    vcr::local_cassette("get_event")

    event <- get_event(id = event_id)

    result <- withVisible(print(event))
    expect_false(result$visible)
    expect_identical(result$value, event)
  })
})

describe("process_event_data", {
  it("handles missing data", {
    expect_error(
      process_event_data(list()),
      "No event data returned"
    )

    expect_error(
      process_event_data(NULL),
      "No event data returned"
    )
  })

  it("adds correct class", {
    mock_data <- list(
      id = "123",
      title = "Test Event",
      status = "ACTIVE",
      feeSettings = list(
        required = TRUE,
        amount = 10,
        currency = "USD"
      )
    )

    result <- process_event_data(mock_data)
    expect_snapshot(print(result))
    expect_s3_class(result, "meetupr_event")
    expect_equal(result$id, "123")
    expect_match(result$title, "Test Event")
  })
})
