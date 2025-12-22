describe("get_pro_groups", {
  it("works", {
    mock_if_no_auth()
    vcr::local_cassette("get_pro_groups")
    groups <- get_pro_groups(urlname = "rladies", max_results = 10)
    expect_s3_class(groups, "data.frame")
    expect_gt(nrow(groups), 5)
    expect_lte(nrow(groups), 10)
  })
})

describe("get_pro_events", {
  it("works", {
    mock_if_no_auth()
    vcr::local_cassette("get_pro_events_cancelled")
    skip_if_not(is_self_pro(), "Skipping Pro tests")
    events <- get_pro_events(
      urlname = "rladies",
      status = "cancelled",
      max_results = 5
    )
    expect_s3_class(events, "data.frame")
    expect_gt(nrow(events), 0)
    expect_lte(nrow(events), 5)
  })
})
