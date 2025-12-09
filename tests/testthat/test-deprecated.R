describe("Deprecated internal functions", {
  it(".fetch_results throws deprecation error", {
    expect_warning(
      .fetch_results()
    )
  })

  it("meetupr_call throws deprecation error", {
    expect_warning(
      meetupr_call()
    )
  })

  it(".quick_fetch throws deprecation error", {
    expect_warning(
      .quick_fetch()
    )
  })
})

describe("Deprecated exported functions", {
  it("get_meetupr_comments warns about using get_event_comments", {
    expect_error(
      get_meetupr_comments()
    )
  })
})
