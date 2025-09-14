test_that("execute_from_template handles missing file", {
  mock_if_no_auth()
  local_mocked_bindings(
    get_execute_from_template_path = function(...) stop("file missing"),
    read_execute_from_template = function(...) stop("file missing")
  )
  expect_error(execute_from_template("nonexistent"))
})

test_that("execute_from_template works with basic parameters", {
  mock_if_no_auth()
  local_mocked_bindings(
    get_execute_from_template_path = function(.file) "/path/to/file.graphql",
    read_execute_from_template = function(path) "query { test }",
    validate_extra_graphql = function(x) x %||% "",
    insert_extra_graphql = function(query, extra) query,
    meetup_query = function(.query, ..., .envir) list(data = "success")
  )

  result <- execute_from_template("test_file", var1 = "value1")
  expect_equal(result$data, "success")
})

test_that("execute_from_template passes extra_graphql correctly", {
  mock_if_no_auth()
  local_mocked_bindings(
    get_execute_from_template_path = function(.file) "/path/to/file.graphql",
    read_execute_from_template = function(path) "query { test }",
    validate_extra_graphql = function(x) {
      expect_equal(x, "fragment Test { id }")
      "fragment Test { id }"
    },
    insert_extra_graphql = function(query, extra) {
      expect_equal(extra, "fragment Test { id }")
      paste(query, extra)
    },
    meetup_query = function(.query, ..., .envir) {
      expect_true(grepl("fragment Test", .query))
      list(data = "with_fragment")
    }
  )

  result <- execute_from_template(
    "test",
    extra_graphql = "fragment Test { id }"
  )
  expect_equal(result$data, "with_fragment")
})

test_that("execute_from_template handles NULL extra_graphql", {
  mock_if_no_auth()
  local_mocked_bindings(
    get_execute_from_template_path = function(.file) "/path/to/file.graphql",
    read_execute_from_template = function(path) "query { test }",
    validate_extra_graphql = function(x) {
      expect_null(x)
      ""
    },
    insert_extra_graphql = function(query, extra) query,
    meetup_query = function(.query, ..., .envir) list(data = "success")
  )

  result <- execute_from_template("test")
  expect_equal(result$data, "success")
})

test_that("meetup_query executes successfully with variables", {
  mock_if_no_auth()
  local_mocked_bindings(
    validate_graphql_variables = function(vars) invisible(),
    build_template_request = function(query, vars) {
      expect_equal(query, "query { test }")
      expect_equal(vars, list(var1 = "value1", var2 = "value2"))
      "mock_request"
    }
  )
  local_mocked_bindings(
    req_perform = function(req) "mock_response",
    resp_body_json = function(resp) list(data = "success"),
    .package = "httr2"
  )

  result <- meetup_query("query { test }", var1 = "value1", var2 = "value2")
  expect_equal(result$data, "success")
})

test_that("meetup_query handles empty variables", {
  mock_if_no_auth()
  local_mocked_bindings(
    validate_graphql_variables = function(vars) invisible(),
    build_template_request = function(query, vars) {
      expect_equal(vars, list())
      "mock_request"
    }
  )

  local_mocked_bindings(
    req_perform = function(req) "mock_response",
    resp_body_json = function(resp) list(data = "success"),
    .package = "httr2"
  )

  result <- meetup_query("query { test }")
  expect_equal(result$data, "success")
})

test_that("meetup_query filters NULL variables with purrr::compact", {
  mock_if_no_auth()
  local_mocked_bindings(
    build_template_request = function(query, vars) "mock_request",
    validate_graphql_variables = function(vars) {
      expect_equal(vars, list(var1 = "value1", var3 = ""))
      invisible()
    }
  )
  local_mocked_bindings(
    req_perform = function(req) "mock_response",
    resp_body_json = function(resp) list(data = "success"),
    .package = "httr2"
  )

  result <- meetup_query(
    "query",
    var1 = "value1",
    var2 = NULL,
    var3 = ""
  )
  expect_equal(result$data, "success")
})


test_that("meetup_query handles GraphQL errors", {
  mock_if_no_auth()
  local_mocked_bindings(
    validate_graphql_variables = function(vars) invisible(),
    build_template_request = function(query, vars) "mock_request"
  )
  local_mocked_bindings(
    req_perform = function(req) "mock_response",
    resp_body_json = function(resp) {
      list(
        errors = list(
          list(message = "Field 'test' not found"),
          list(message = "Invalid {syntax} here")
        )
      )
    },
    .package = "httr2"
  )

  expect_error(
    meetup_query("query { test }"),
    "Failed to execute GraphQL query"
  )
})

test_that("meetup_query escapes curly braces in error messages", {
  mock_if_no_auth()
  local_mocked_bindings(
    validate_graphql_variables = function(vars) invisible(),
    build_template_request = function(query, vars) "mock_request"
  )
  local_mocked_bindings(
    req_perform = function(req) "mock_response",
    resp_body_json = function(resp) {
      list(
        errors = list(
          list(message = "Error with {variable} and }brace{")
        )
      )
    },
    .package = "httr2"
  )

  expect_error(
    meetup_query("query"),
    "Error with \\{variable\\}"
  )
})

test_that("build_template_request handles empty variables", {
  mock_if_no_auth()
  local_mocked_bindings(
    meetup_req = function() httr2::request("https://api.example.com")
  )

  req <- build_template_request("query { test }", list())
  body <- req$body$data

  expect_equal(body$query, "query { test }")
  expect_equal(body$variables, structure(list(), names = character(0)))
})

test_that("build_template_request handles NULL variables", {
  mock_if_no_auth()
  local_mocked_bindings(
    meetup_req = function() httr2::request("https://api.example.com")
  )

  req <- build_template_request("query { test }", NULL)
  body <- req$body$data

  expect_equal(body$query, "query { test }")
  expect_equal(body$variables, structure(list(), names = character(0)))
})

test_that("build_template_request includes variables in request", {
  mock_if_no_auth()
  local_mocked_bindings(
    meetup_req = function() httr2::request("https://api.example.com")
  )

  variables <- list(var1 = "value1", var2 = 123)
  req <- build_template_request("query { test }", variables)
  body <- req$body$data

  expect_equal(body$query, "query { test }")
  expect_equal(body$variables, variables)
})

test_that("build_template_request debug mode outputs JSON", {
  mock_if_no_auth()
  withr::local_envvar(MEETUPR_DEBUG = "true")

  local_mocked_bindings(
    meetup_req = function() httr2::request("https://api.example.com")
  )
  local_mocked_bindings(
    cli_alert_info = function(msg) {
      expect_equal(msg, "DEBUG: JSON to be sent:")
    },
    cli_code = function(body) {
      expect_true(any(grepl("query", body)))
      expect_true(any(grepl("variables", body)))
    },
    .package = "cli"
  )

  build_template_request("query { test }", list(var = "value"))
})

test_that("build_template_request debug mode disabled", {
  mock_if_no_auth()
  withr::local_envvar(MEETUPR_DEBUG = "")

  local_mocked_bindings(
    meetup_req = function() httr2::request("https://api.example.com")
  )
  local_mocked_bindings(
    cli_alert_info = function(msg) stop("Should not be called"),
    cli_code = function(body) stop("Should not be called"),
    .package = "cli"
  )

  expect_no_error(
    build_template_request("query { test }", list())
  )
})
