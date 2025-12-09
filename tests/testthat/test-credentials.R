describe("meetupr_key_set", {
  it("sets an environment variable for a valid key", {
    withr::local_envvar(c())
    meetupr_key_set("client_key", "abc123", "testclient")
    expect_equal(Sys.getenv("testclient_client_key"), "abc123")
  })

  it("overwrites an existing environment variable", {
    withr::local_envvar("testclient_client_key" = "old")
    meetupr_key_set("client_key", "new", "testclient")
    expect_equal(Sys.getenv("testclient_client_key"), "new")
  })

  it("errors for invalid key name", {
    expect_error(
      meetupr_key_set("notakey", "val", "testclient"),
      "'arg' should be one of"
    )
  })
})

describe("meetupr_key_get", {
  it("returns value if env var is set", {
    withr::local_envvar("testclient_client_key" = NA)
    meetupr_key_set("client_key", "abc123", "testclient")
    expect_equal(meetupr_key_get("client_key", "testclient"), "abc123")
  })

  it("returns NA if env var is not set and error = FALSE", {
    withr::local_envvar("testclient_client_key" = NA)
    expect_true(is.na(meetupr_key_get(
      "client_key",
      "testclient",
      error = FALSE
    )))
  })

  it("errors if env var is not set and error = TRUE", {
    withr::local_envvar(
      "testclient_client_key" = NA
    )
    expect_error(
      meetupr_key_get("client_key", "testclient", error = TRUE),
      "not found."
    )
  })

  it("errors for invalid key name", {
    expect_error(
      meetupr_key_get("notakey", "testclient"),
      "'arg' should be one of"
    )
  })
})

describe("meetupr_key_delete", {
  it("unsets an environment variable", {
    withr::local_envvar("testclient_client_key" = "abc123")
    meetupr_key_delete("client_key", "testclient")
    expect_equal(
      Sys.getenv("testclient_client_key", unset = "notset"),
      "notset"
    )
  })

  it("does nothing if env var is not set", {
    withr::local_envvar("testclient_client_key" = NA)
    expect_invisible(meetupr_key_delete("client_key", "testclient"))
    expect_equal(
      Sys.getenv("testclient_client_key", unset = "notset"),
      "notset"
    )
  })

  it("errors for invalid key name", {
    expect_error(
      meetupr_key_delete("notakey", "testclient"),
      "'arg' should be one of"
    )
  })
})

describe("key_name", {
  it("validates input", {
    expect_equal(key_name("client_key"), "client_key")
    expect_equal(key_name("client_secret"), "client_secret")
    expect_error(key_name("invalid"))
  })

  it("returns valid key names", {
    expect_equal(key_name("client_key"), "client_key")
    expect_equal(key_name("client_secret"), "client_secret")
    expect_equal(key_name("encrypt_pwd"), "encrypt_pwd")
    expect_equal(key_name("jwt_token"), "jwt_token")
  })

  it("errors for invalid key", {
    expect_error(key_name("notakey"), "'arg' should be one of")
  })
})
describe("clear_meetupr_token()", {
  it("unsets envvars and removes oauth cache dir", {
    td <- local_tempdir()
    # create client cache dir
    client_dir <- file.path(td, "testclient")
    dir.create(client_dir, recursive = TRUE)
    file.create(file.path(client_dir, "dummy"))
    withr::local_envvar(
      c(
        "testclient_client_key" = "id",
        "testclient_client_secret" = "sec",
        "testclient_encrypt_pwd" = "p",
        "testclient_jwt_token" = "j"
      )
    )

    local_mocked_bindings(
      oauth_cache_path = function() td,
      .package = "httr2"
    )

    clear_meetupr_token("testclient")

    expect_false(dir.exists(client_dir))
    expect_equal(
      Sys.getenv("testclient_client_key", unset = "notset"),
      "notset"
    )
    expect_equal(
      Sys.getenv("testclient_jwt_token", unset = "notset"),
      "notset"
    )
  })
})

describe("get_input() and key_available()", {
  it("detects presence and absence of env keys", {
    withr::local_envvar("testclient_client_key" = "x")
    expect_true(
      key_available("client_key", "testclient")
    )

    withr::local_envvar("testclient_client_key" = NA)
    expect_false(
      key_available("client_key", "testclient")
    )
  })

  it("returns the readline value via meetupr_readline mock", {
    local_mocked_bindings(
      read_input = function(prompt = "") "my-input"
    )

    expect_identical(get_input("client_key"), "my-input")
  })
})


describe("get_cached_token()", {
  it("returns NULL when meetupr_client() yields NULL", {
    local_mocked_bindings(
      oauth_token_cached = function(...) stop("should not be called"),
      .package = "httr2"
    )
    local_mocked_bindings(
      meetupr_client = function(...) NULL
    )

    expect_null(get_cached_token(NULL))
  })

  it("returns token list when httr2::oauth_token_cached succeeds", {
    local_mocked_bindings(
      oauth_token_cached = function(client, flow, flow_params) {
        structure(list(access_token = "cached-abc"))
      },
      .package = "httr2"
    )

    local_mocked_bindings(
      meetupr_client = function(...) structure(list(name = "testclient"))
    )

    res <- get_cached_token(client_name = "testclient")
    expect_true(is.list(res))
    expect_equal(res$access_token, "cached-abc")
  })

  it("returns NULL when httr2::oauth_token_cached errors", {
    local_mocked_bindings(
      oauth_token_cached = function(...) stop("no cache"),
      .package = "httr2"
    )

    local_mocked_bindings(
      meetupr_client = function(...) structure(list(name = "testclient"))
    )

    expect_null(get_cached_token(client_name = "testclient"))
  })
})
