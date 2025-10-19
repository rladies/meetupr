test_that("execute_from_template handles missing file", {
  mock_if_no_auth()
  local_mocked_bindings(
    get_template_path = function(...) stop("file missing"),
    read_template = function(...) stop("file missing")
  )
  expect_error(execute_from_template("nonexistent"))
})

test_that("execute_from_template works with basic parameters", {
  mock_if_no_auth()
  local_mocked_bindings(
    get_template_path = function(.file) "/path/to/file.graphql",
    read_template = function(path) "query { test }",
    validate_extra_graphql = function(x) x %||% "",
    insert_extra_graphql = function(query, extra) query,
    meetup_query = function(graphql, ..., .envir) list(data = "success")
  )

  result <- execute_from_template("test_file", var1 = "value1")
  expect_equal(result$data, "success")
})

test_that("execute_from_template passes extra_graphql correctly", {
  mock_if_no_auth()
  local_mocked_bindings(
    get_template_path = function(.file) "/path/to/file.graphql",
    read_template = function(path) "query { test }",
    validate_extra_graphql = function(x) {
      expect_equal(x, "fragment Test { id }")
      "fragment Test { id }"
    },
    insert_extra_graphql = function(query, extra) {
      expect_equal(extra, "fragment Test { id }")
      paste(query, extra)
    },
    meetup_query = function(graphql, ..., .envir) {
      expect_true(grepl("fragment Test", graphql))
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
    get_template_path = function(.file) "/path/to/file.graphql",
    read_template = function(path) "query { test }",
    validate_extra_graphql = function(x) {
      expect_null(x)
      ""
    },
    insert_extra_graphql = function(query, extra) query,
    meetup_query = function(graphql, ..., .envir) list(data = "success")
  )

  result <- execute_from_template("test")
  expect_equal(result$data, "success")
})

test_that("build_request handles empty variables", {
  mock_if_no_auth()
  local_mocked_bindings(
    meetup_req = function() httr2::request("https://api.example.com")
  )

  req <- build_request("query { test }", list())
  body <- req$body$data

  expect_equal(body$query, "query { test }")
  expect_equal(body$variables, structure(list(), names = character(0)))
})

test_that("build_request handles NULL variables", {
  mock_if_no_auth()
  local_mocked_bindings(
    meetup_req = function() httr2::request("https://api.example.com")
  )

  req <- build_request("query { test }", NULL)
  body <- req$body$data

  expect_equal(body$query, "query { test }")
  expect_equal(body$variables, structure(list(), names = character(0)))
})

test_that("build_request includes variables in request", {
  mock_if_no_auth()
  local_mocked_bindings(
    meetup_req = function() httr2::request("https://api.example.com")
  )

  variables <- list(var1 = "value1", var2 = 123)
  req <- build_request("query { test }", variables)
  body <- req$body$data

  expect_equal(body$query, "query { test }")
  expect_equal(body$variables, variables)
})

test_that("build_request debug mode outputs JSON", {
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

  result <- build_request("query { test }", list(var = "value"))
  expect_s3_class(result, "httr2_request")
})

test_that("build_request debug mode disabled", {
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
    build_request("query { test }", list())
  )
})

test_that("validate_event_status returns when input is NULL", {
  expect_equal(
    validate_event_status(),
    valid_event_status
  )
})

test_that("validate_event_status validates single valid status", {
  expect_equal(validate_event_status("PAST"), "PAST")
})

test_that("validate_event_status validates multiple valid statuses", {
  expect_equal(
    validate_event_status(
      c("DRAFT", "PAST")
    ),
    c("DRAFT", "PAST")
  )
})

test_that("validate_event_status throws an error for invalid status", {
  expect_error(
    validate_event_status("INVALID"),
    "Invalid event status"
  )
})

test_that("get_template_path fails when file doesn't exist", {
  expect_error(
    get_template_path("nonexistent_file.graphql"),
    "GraphQL template file not found"
  )
})


test_that("get_template_path accepts user file with full path", {
  temp_file <- withr::local_tempfile(fileext = ".graphql")
  writeLines("query { test }", temp_file)

  path <- get_template_path(temp_file)
  expect_equal(normalizePath(path), normalizePath(temp_file))
  expect_true(file.exists(path))
})


test_that("get_template_path handles relative paths", {
  # Create temporary directory structure
  temp_dir <- withr::local_tempdir()
  queries_dir <- file.path(temp_dir, "queries")
  dir.create(queries_dir)

  query_file <- file.path(queries_dir, "custom.graphql")
  writeLines("query { test }", query_file)

  # Change to temp directory to test relative path
  withr::local_dir(temp_dir)

  path <- get_template_path("queries/custom.graphql")
  expect_true(file.exists(path))
  expect_match(path, "queries/custom\\.graphql$")
})

test_that("get_template_path normalizes paths", {
  temp_file <- withr::local_tempfile(fileext = ".graphql")
  writeLines("query { test }", temp_file)

  # Test with redundant path separators
  messy_path <- gsub("/", "//", temp_file)
  path <- get_template_path(messy_path)

  # Should return normalized path
  expect_equal(path, normalizePath(temp_file, mustWork = TRUE))
})

test_that("get_template_path returns absolute path", {
  temp_file <- withr::local_tempfile(fileext = ".graphql")
  writeLines("query { test }", temp_file)

  path <- get_template_path(temp_file)

  # Result should be absolute (not relative)
  expect_true(grepl("^/", path) || grepl("^[A-Z]:", path)) # Unix or Windows
})
test_that("get_template_path handles symlinks", {
  skip_on_os("windows") # Symlink behavior differs on Windows

  temp_file <- withr::local_tempfile(fileext = ".graphql")
  writeLines("query { test }", temp_file)

  # Create symlink
  temp_dir <- withr::local_tempdir()
  link_path <- file.path(temp_dir, "link.graphql")
  file.symlink(temp_file, link_path)

  if (file.exists(link_path)) {
    path <- get_template_path(link_path)
    expect_true(file.exists(path))
    # Should resolve to real path
    expect_equal(normalizePath(path), normalizePath(temp_file))
  }
})

test_that("get_template_path validates file is readable", {
  skip_on_os("windows") # Permission testing works differently

  temp_file <- withr::local_tempfile(fileext = ".graphql")
  writeLines("query { test }", temp_file)

  # Remove read permissions
  Sys.chmod(temp_file, mode = "000")
  withr::defer(Sys.chmod(temp_file, mode = "644"))

  # File exists but isn't readable - normalizePath should still work
  # (actual read error happens in read_template, not here)
  expect_no_error(get_template_path(temp_file))
})

test_that("read_template strips end-of-line", {
  temp_file <- withr::local_tempfile(fileext = ".graphql")

  query_with_cr <- "query GetEvent($id: ID!) {\r\n
    event(id: $id) {\r\n
      id\r\n
      title\r\n
    }\r\n}"

  writeChar(
    query_with_cr,
    temp_file,
    eos = NULL
  )

  result <- read_template(temp_file)

  # Should have Unix line endings only
  expect_false(grepl("\r", result))
  expect_match(result, "query GetEvent")
})

test_that("insert_extra_graphql handles all code paths", {
  base_query <- "query { test << extra_graphql >> }"

  expect_equal(
    insert_extra_graphql(
      base_query,
      "fragment Test on Node { id }"
    ),
    "query { test fragment Test on Node { id } }"
  )

  expect_equal(
    insert_extra_graphql(base_query, ""),
    "query { test  }"
  )

  expect_equal(
    insert_extra_graphql(base_query, NULL),
    "query { test  }"
  )
})

test_that("validate_extra_graphql rejects invalid input", {
  expect_error(
    validate_extra_graphql(123),
    "extra_graphql.*must be a single string"
  )

  expect_error(
    validate_extra_graphql(c("a", "b")),
    "extra_graphql.*must be a single string"
  )

  expect_error(
    validate_extra_graphql(list("a")),
    "extra_graphql.*must be a single string"
  )
})
