# Tests for get-group.R

describe("get_group_events", {
  it("calls execute and returns result tibble", {
    local_mocked_bindings(
      execute = function(...) {
        dplyr::tibble(event_id = "evt1")
      }
    )

    res <- get_group_events(
      "rladies-lagos",
      status = "past"
    )

    expect_s3_class(res, "tbl_df")
    expect_equal(res$event_id, "evt1")
  })

  it("passes validated status to execute", {
    local_mocked_bindings(
      execute = function(..., status = NULL) {
        dplyr::tibble(status = as.character(status))
      }
    )

    res <- get_group_events("g", status = "past")
    expect_equal(res$status, "PAST")
  })

  it("handles NULL status and date filters", {
    local_mocked_bindings(
      execute = function(...) dplyr::tibble(n = 1)
    )

    res <- get_group_events(
      "g",
      status = NULL,
      date_before = "2023-01-01T00:00:00Z",
      date_after = NULL
    )

    expect_s3_class(res, "tbl_df")
    expect_equal(nrow(res), 1)
  })
})

describe("get_group_members", {
  it("returns members tibble from execute", {
    local_mocked_bindings(
      execute = function(...) dplyr::tibble(member = c("a", "b"))
    )

    res <- get_group_members("rladies-lagos", max_results = 2)
    expect_s3_class(res, "tbl_df")
    expect_equal(res$member, c("a", "b"))
  })

  it("passes max_results through first/first arg", {
    local_mocked_bindings(
      execute = function(..., first = NULL, max_results = NULL) {
        dplyr::tibble(
          first = as.integer(first),
          max_results = as.integer(max_results)
        )
      }
    )

    res <- get_group_members("g", max_results = 5)
    expect_equal(res$max_results, 5L)
  })
})

describe("get_group", {
  it("returns processed group structure from execute", {
    local_mocked_bindings(
      execute = function(...) {
        structure(
          list(id = "grp1", name = "G1"),
          class = c("meetupr_group", "list")
        )
      }
    )

    res <- get_group("rladies-lagos")
    expect_s3_class(res, "meetupr_group")
    expect_equal(res$id, "grp1")
    expect_equal(res$name, "G1")
  })

  it("propagates asis = TRUE to execute and returns raw list", {
    local_mocked_bindings(
      execute = function(...) list(raw = TRUE)
    )

    res <- get_group("g", asis = TRUE)
    expect_type(res, "list")
    expect_true(res$raw)
  })
})

describe("process_group_data and helpers", {
  it("errors when no group data returned", {
    expect_error(
      process_group_data(NULL),
      regexp = "No group data returned"
    )
  })

  it("processes a full group data input", {
    raw <- list(
      id = "1",
      name = "G",
      description = "<p>hi</p>",
      urlname = "g",
      link = "http://g",
      timezone = "UTC",
      foundedDate = "2020-01-01",
      stats = list(memberCounts = list(all = 10)),
      events = list(totalCount = 3),
      organizer = list(id = "o1", name = "Org"),
      topicCategory = list(id = "t1", name = "Cat"),
      keyGroupPhoto = list(baseUrl = "http://img")
    )

    res <- process_group_data(raw)
    expect_s3_class(res, "meetupr_group")
    expect_equal(res$members, 10)
    expect_equal(res$total_events, 3)
    expect_equal(res$organizer$name, "Org")
    expect_equal(res$category$name, "Cat")
    expect_equal(res$photo_url, "http://img")
  })
})

describe("extract_group_location", {
  it("returns list with city and country", {
    data <- list(city = "A", country = "B")
    loc <- extract_group_location(data)
    expect_named(loc, c("city", "country"))
    expect_equal(loc$city, "A")
    expect_equal(loc$country, "B")
  })
})

describe("extract_organizer_info", {
  it("returns NULL for missing organizer", {
    expect_null(extract_organizer_info(NULL))
  })

  it("extracts id and name", {
    o <- list(id = "o", name = "O")
    res <- extract_organizer_info(o)
    expect_named(res, c("id", "name"))
    expect_equal(res$id, "o")
    expect_equal(res$name, "O")
  })
})

describe("extract_category_info", {
  it("returns NULL for missing category", {
    expect_null(extract_category_info(NULL))
  })

  it("extracts id and name", {
    c <- list(id = "c1", name = "Cats")
    res <- extract_category_info(c)
    expect_named(res, c("id", "name"))
    expect_equal(res$id, "c1")
    expect_equal(res$name, "Cats")
  })
})

describe("print.meetupr_group", {
  it("prints a nicely formatted group summary", {
    grp <- structure(
      list(
        id = "1",
        name = "G",
        urlname = "g",
        link = "http://g",
        location = list(city = "City", country = "CT"),
        timezone = "UTC",
        created = as.POSIXct("2020-01-01", tz = "UTC"),
        members = 12,
        total_events = 4,
        organizer = list(name = "Org"),
        category = list(name = "Cat"),
        description = "<p>Hello world</p>"
      ),
      class = c("meetupr_group", "list")
    )

    expect_snapshot(print(grp))
  })

  it("handles missing optional fields gracefully", {
    grp <- structure(
      list(id = "2", name = "NoDesc", urlname = "nd", link = NULL),
      class = c("meetupr_group", "list")
    )
    expect_snapshot(print(grp))
  })
})
