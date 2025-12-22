describe("meetupr_sitrep()", {
  it("prints setup when no auth and returns auth invisibly", {
    local_mocked_bindings(
      cli_h1 = function(x) message("H1: ", x),
      cli_h2 = function(x) message("H2: ", x),
      cli_h3 = function(x) message("H3: ", x),
      cli_alert_success = function(x) message("SUCCESS: ", x),
      cli_alert_danger = function(x) message("DANGER: ", x),
      cli_alert_info = function(x) message("INFO: ", x),
      cli_alert_warning = function(x) message("WARN: ", x),
      cli_ol = function(x) message("OL: ", paste(x, collapse = "; ")),
      cli_ul = function(x) message("UL: ", paste(x, collapse = "; ")),
      .package = "cli"
    )

    auth <- list(
      auth = list(any = FALSE, method = NA, client_name = NA),
      jwt = list(available = FALSE, issuer = NA, client_key = NA),
      encrypted = list(available = FALSE, path = NA, pwd = FALSE),
      refresh = list(available = FALSE),
      cache = list(available = FALSE)
    )

    local_mocked_bindings(
      meetupr_auth_status = function(...) auth,
      get_self = function() stop("should not be called"),
      .package = "meetupr"
    )

    expect_snapshot(meetupr_sitrep())

    out <- meetupr_sitrep()
    expect_identical(out, auth)
  })

  it("runs full report when auth available and API works", {
    local_mocked_bindings(
      cli_h1 = function(x) message("H1: ", x),
      cli_h2 = function(x) message("H2: ", x),
      cli_h3 = function(x) message("H3: ", x),
      cli_alert_success = function(x) message("SUCCESS: ", x),
      cli_alert_danger = function(x) message("DANGER: ", x),
      cli_alert_info = function(x) message("INFO: ", x),
      cli_alert_warning = function(x) message("WARN: ", x),
      cli_ol = function(x) message("OL: ", paste(x, collapse = "; ")),
      cli_ul = function(x) message("UL: ", paste(x, collapse = "; ")),
      .package = "cli"
    )

    auth <- list(
      auth = list(any = TRUE, method = "jwt", client_name = "rladies"),
      jwt = list(available = TRUE, issuer = "251470805", client_key = "sr9210"),
      encrypted = list(available = FALSE, path = NA, pwd = FALSE),
      refresh = list(available = FALSE),
      cache = list(available = FALSE)
    )

    local_mocked_bindings(
      meetupr_auth_status = function(...) auth,
      get_self = function() list(name = "Tester", id = 7),
      .package = "meetupr"
    )

    expect_snapshot(meetupr_sitrep())

    out <- meetupr_sitrep()
    expect_identical(out, auth)
  })
})

describe("display_auth_status()", {
  it("alerts danger when no auth available", {
    local_mocked_bindings(
      cli_h2 = function(x) message("H2: ", x),
      cli_alert_success = function(x) message("SUCCESS: ", x),
      cli_alert_danger = function(x) message("DANGER: ", x),
      .package = "cli"
    )

    auth <- list(
      auth = list(any = FALSE, method = NA, client_name = NA),
      jwt = list(available = FALSE, issuer = NA, client_key = NA),
      encrypted = list(available = FALSE, path = NA, pwd = FALSE),
      refresh = list(available = FALSE),
      cache = list(available = FALSE)
    )

    expect_snapshot(display_auth_status(auth))
  })

  it("prefers JWT over other available methods", {
    local_mocked_bindings(
      cli_h2 = function(x) message("H2: ", x),
      cli_alert_success = function(x) message("SUCCESS: ", x),
      cli_alert_danger = function(x) message("DANGER: ", x),
      .package = "cli"
    )

    auth <- list(
      auth = list(any = TRUE, method = "jwt", client_name = "rladies"),
      jwt = list(available = TRUE, issuer = "251470805", client_key = "sr9210"),
      encrypted = list(available = TRUE, path = "/tmp/token", pwd = TRUE),
      refresh = list(available = TRUE),
      cache = list(available = TRUE)
    )

    expect_snapshot(display_auth_status(auth))
  })

  it("shows Encrypted when JWT missing", {
    local_mocked_bindings(
      cli_h2 = function(x) message("H2: ", x),
      cli_alert_success = function(x) message("SUCCESS: ", x),
      cli_alert_danger = function(x) message("DANGER: ", x),
      .package = "cli"
    )

    auth <- list(
      auth = list(any = TRUE, method = "encrypted", client_name = "rladies"),
      jwt = list(available = FALSE, issuer = NA, client_key = NA),
      encrypted = list(available = TRUE, path = "/tmp/token", pwd = FALSE),
      refresh = list(available = FALSE),
      cache = list(available = FALSE)
    )

    expect_snapshot(display_auth_status(auth))
  })

  it("shows Refresh when earlier methods missing", {
    local_mocked_bindings(
      cli_h2 = function(x) message("H2: ", x),
      cli_alert_success = function(x) message("SUCCESS: ", x),
      cli_alert_danger = function(x) message("DANGER: ", x),
      .package = "cli"
    )

    auth <- list(
      auth = list(any = TRUE, method = "refresh", client_name = "rladies"),
      jwt = list(available = FALSE, issuer = NA, client_key = NA),
      encrypted = list(available = FALSE, path = NA, pwd = FALSE),
      refresh = list(available = TRUE),
      cache = list(available = FALSE)
    )

    expect_snapshot(display_auth_status(auth))
  })

  it("shows OAuth cache when others missing", {
    local_mocked_bindings(
      cli_h2 = function(x) message("H2: ", x),
      cli_alert_success = function(x) message("SUCCESS: ", x),
      cli_alert_danger = function(x) message("DANGER: ", x),
      .package = "cli"
    )

    auth <- list(
      auth = list(any = TRUE, method = "cache", client_name = "rladies"),
      jwt = list(available = FALSE, issuer = NA, client_key = NA),
      encrypted = list(available = FALSE, path = NA, pwd = FALSE),
      refresh = list(available = FALSE),
      cache = list(available = TRUE)
    )

    expect_snapshot(display_auth_status(auth))
  })
})

describe("test_api_connectivity()", {
  it("prints setup and returns NULL when no auth", {
    local_mocked_bindings(
      cli_h2 = function(x) message("H2: ", x),
      cli_h3 = function(x) message("H3: ", x),
      cli_ol = function(x) message("OL: ", paste(x, collapse = "; ")),
      cli_ul = function(x) message("UL: ", paste(x, collapse = "; ")),
      cli_alert_success = function(x) message("SUCCESS: ", x),
      cli_alert_danger = function(x) message("DANGER: ", x),
      .package = "cli"
    )

    local_mocked_bindings(
      has_auth = function() FALSE,
      .package = "meetupr"
    )

    expect_snapshot(test_api_connectivity())

    out <- test_api_connectivity()
    expect_null(out)
  })

  it("reports working when get_self returns user info", {
    local_mocked_bindings(
      cli_h2 = function(x) message("H2: ", x),
      cli_alert_success = function(x) message("SUCCESS: ", x),
      cli_alert_info = function(x) message("INFO: ", x),
      .package = "cli"
    )

    local_mocked_bindings(
      has_auth = function() TRUE,
      get_self = function() list(name = "Alice", id = 42),
      .package = "meetupr"
    )

    expect_snapshot(test_api_connectivity())
  })

  it("warns on unexpected NULL response from get_self", {
    local_mocked_bindings(
      cli_h2 = function(x) message("H2: ", x),
      cli_alert_warning = function(x) message("WARN: ", x),
      .package = "cli"
    )

    local_mocked_bindings(
      has_auth = function() TRUE,
      get_self = function() NULL,
      .package = "meetupr"
    )

    expect_snapshot(test_api_connectivity())
  })

  it("handles errors from get_self and shows danger", {
    local_mocked_bindings(
      cli_h2 = function(x) message("H2: ", x),
      cli_alert_danger = function(x) message("DANGER: ", x),
      .package = "cli"
    )

    local_mocked_bindings(
      has_auth = function() TRUE,
      get_self = function() stop("boom"),
      .package = "meetupr"
    )

    expect_snapshot(test_api_connectivity())
  })
})
