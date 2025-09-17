test_that("validate_graphql_variables works correctly", {
  # Test valid named variables
  named_vars <- list(query = "test", limit = 10)
  expect_invisible(validate_graphql_variables(named_vars))

  # Test empty list
  expect_invisible(validate_graphql_variables(list()))

  # Test unnamed variables
  unnamed_vars <- list("test", "value")
  expect_error(
    validate_graphql_variables(unnamed_vars),
    "All GraphQL variables must be named"
  )

  # Test partially named variables
  partial_vars <- list(query = "test", "unnamed_value")
  expect_error(
    validate_graphql_variables(partial_vars),
    "All GraphQL variables must be named"
  )
})

test_that("paste_before_ext works correctly", {
  expect_equal(
    paste_before_ext("file.txt", "_backup"),
    "file_backup.txt"
  )

  expect_equal(
    paste_before_ext("file.tar.gz", "_v2"),
    "file.tar_v2.gz"
  )

  # File without extension
  expect_equal(
    paste_before_ext("filename", "_suffix"),
    "filename_suffix"
  )

  # Multiple files
  expect_equal(
    paste_before_ext("file.txt", c("_1", "_2")),
    c("file_1.txt", "file_2.txt")
  )
})


test_that("uq_filename generates unique filenames", {
  temp_dir <- withr::local_tempdir()
  test_file <- file.path(temp_dir, "test.txt")

  # First call - file doesn't exist
  result1 <- uq_filename(test_file)
  expect_equal(result1, test_file)

  # Create the file and test again
  file.create(test_file)
  result2 <- uq_filename(test_file)
  expect_true(result2 != test_file)
  expect_true(grepl("test1\\.txt$", result2))

  # Create the numbered file and test again
  file.create(result2)
  result3 <- uq_filename(test_file)
  expect_true(grepl("test2\\.txt$", result3))
})

test_that("uq_filename validates input", {
  expect_error(
    uq_filename(c("file1.txt", "file2.txt")),
    "length\\(file_name\\) == 1L"
  )

  expect_error(
    uq_filename(123),
    "is.character\\(file_name\\)"
  )
})

test_that("process_datetime_fields converts datetime strings", {
  test_data <- dplyr::tibble(
    id = "test",
    created = "2023-01-01T10:00:00Z",
    not_datetime = "regular_string",
    number_field = 42
  )

  result <- process_datetime_fields(test_data, c("created"))

  expect_s3_class(result$created, "POSIXct")
  expect_equal(result$not_datetime, "regular_string")
  expect_equal(result$number_field, 42)
})

test_that("process_datetime_fields handles missing fields gracefully", {
  test_data <- dplyr::tibble(
    id = "test",
    name = "Test"
  )

  result <- process_datetime_fields(test_data, c("missing_field", "created"))

  expect_equal(result, test_data)
})

test_that("nzchar_null handles NULL input", {
  result <- nzchar_null(NULL)
  expect_true(result)
})

test_that("nzchar_null handles empty string", {
  result <- nzchar_null("")
  expect_false(result)
})

test_that("nzchar_null handles non-empty string", {
  result <- nzchar_null("text")
  expect_true(result)
})

test_that("validate_graphql_variables handles mixed named/unnamed variables", {
  mixed_vars <- list(
    query = "test",
    "unnamed",
    limit = 10
  )
  expect_error(
    validate_graphql_variables(mixed_vars),
    "All GraphQL variables must be named"
  )

  # Test with NULL names
  vars_with_null_names <- list("value1", "value2")
  names(vars_with_null_names) <- c("name1", "")
  expect_error(
    validate_graphql_variables(vars_with_null_names),
    "All GraphQL variables must be named"
  )
})


test_that("uq_filename handles complex scenarios", {
  temp_dir <- withr::local_tempdir()

  # Test with file that has no extension
  base_file <- file.path(temp_dir, "testfile")
  result1 <- uq_filename(base_file)
  expect_equal(result1, base_file)

  # Create file and test numbering
  file.create(base_file)
  result2 <- uq_filename(base_file)
  expect_equal(result2, paste0(base_file, "1"))

  # Test with deeply nested path
  nested_dir <- file.path(temp_dir, "nested", "path")
  dir.create(nested_dir, recursive = TRUE)
  nested_file <- file.path(nested_dir, "nested.txt")
  result3 <- uq_filename(nested_file)
  expect_equal(result3, nested_file)
})

test_that("uq_filename finds first available number", {
  temp_dir <- withr::local_tempdir()
  test_file <- file.path(temp_dir, "test.txt")

  # Create original and first few numbered versions
  file.create(test_file)
  file.create(file.path(temp_dir, "test1.txt"))
  file.create(file.path(temp_dir, "test2.txt"))

  result <- uq_filename(test_file)
  expect_equal(result, file.path(temp_dir, "test3.txt"))
})

test_that("process_datetime_fields handles various datetime formats", {
  test_data <- dplyr::tibble(
    id = 1:3,
    created = c(
      "2023-01-01T10:00:00Z",
      "2023-01-02T15:30:00+05:30",
      "2023-01-03T20:45:00-08:00"
    ),
    updated = c(
      "2023-01-01T12:00:00Z",
      "2023-01-02T17:30:00+02:00",
      "2023-01-03T22:45:00-05:00"
    )
  )

  result <- process_datetime_fields(test_data, c("created", "updated"))

  expect_s3_class(result$created, "POSIXct")
  expect_s3_class(result$updated, "POSIXct")
  expect_equal(length(result$created), 3)
  expect_equal(length(result$updated), 3)
})

test_that("process_datetime_fields handles malformed dates gracefully", {
  test_data <- dplyr::tibble(
    id = 1:2,
    bad_date = c("not-a-date", "2023-13-45T25:70:00Z"),
    good_date = c("2023-01-01T10:00:00Z", "2023-01-02T11:00:00Z")
  )

  # Should handle malformed dates without crashing
  result <- process_datetime_fields(test_data, c("bad_date", "good_date"))

  expect_s3_class(result$good_date, "POSIXct")
  expect_true(all(is.na(result$bad_date)))
})

test_that("process_datetime_fields handles empty data frames", {
  empty_df <- dplyr::tibble()
  result <- process_datetime_fields(empty_df, c("created", "updated"))
  expect_equal(result, empty_df)

  # Data frame with no matching fields
  test_df <- dplyr::tibble(id = 1, name = "test")
  result2 <- process_datetime_fields(test_df, c("created", "updated"))
  expect_equal(result2, test_df)
})

test_that("get_country_code handles single values", {
  testthat::local_mocked_bindings(
    country_code = function(x) {
      if (x == "US") {
        return("United States")
      }
      if (x == "GB") {
        return("United Kingdom")
      }
      if (x == "XX") {
        return(NA_character_)
      }
      NA_character_
    }
  )

  expect_equal(get_country_code("US"), "United States")
  expect_equal(get_country_code("GB"), "United Kingdom")
  expect_true(is.na(get_country_code("XX")))
})

test_that("get_country_code handles lists", {
  testthat::local_mocked_bindings(
    country_code = function(x) {
      switch(
        x,
        "US" = "United States",
        "CA" = "Canada",
        "GB" = "United Kingdom",
        NA_character_
      )
    }
  )

  result <- get_country_code(list("US", "CA", "GB"))
  expect_equal(result, list("United States", "Canada", "United Kingdom"))

  # Empty list
  empty_result <- get_country_code(list())
  expect_equal(empty_result, list())
})

test_that("country_code calls countrycode correctly", {
  local_mocked_bindings(
    countrycode = function(x, origin, destination, warn) {
      expect_equal(origin, "iso2c")
      expect_equal(destination, "country.name")
      expect_false(warn)

      switch(x, "US" = "United States", "DE" = "Germany", NA_character_)
    },
    .package = "countrycode"
  )

  expect_equal(country_code("US"), "United States")
  expect_equal(country_code("DE"), "Germany")
  expect_true(is.na(country_code("ZZ")))
})

test_that("nzchar_null handles various inputs", {
  expect_true(nzchar_null(NULL))
  expect_false(nzchar_null(""))
  expect_true(nzchar_null("text"))
  expect_true(nzchar_null("0"))
  expect_true(nzchar_null(" "))
  expect_true(nzchar_null("\t"))
  expect_true(nzchar_null("\n"))
})

test_that("mock_if_no_auth sets environment variables when needed", {
  # Test when no credentials exist
  testthat::local_mocked_bindings(
    has_jwt_credentials = function() FALSE,
    has_oauth_credentials = function() FALSE
  )

  withr::local_envvar(c(
    MEETUP_CLIENT_ID = "",
    MEETUP_CLIENT_SECRET = "",
    MEETUP_MEMBER_ID = "",
    MEETUP_RSA_KEY = ""
  ))

  mock_if_no_auth()

  expect_equal(Sys.getenv("MEETUP_CLIENT_ID"), "123456")
  expect_equal(Sys.getenv("MEETUP_CLIENT_SECRET"), "aB3xK9mP2")
  expect_equal(Sys.getenv("MEETUP_MEMBER_ID"), "1111111")
  expect_equal(Sys.getenv("MEETUP_RSA_KEY"), "-----BEGIN PRIVATE KEY-----")
})

test_that("mock_if_no_auth does nothing when credentials exist", {
  local_mocked_bindings(
    has_jwt_credentials = function() TRUE,
    has_oauth_credentials = function() TRUE
  )

  withr::local_envvar(c(
    MEETUP_CLIENT_ID = "existing_id",
    MEETUP_CLIENT_SECRET = "existing_secret"
  ))

  original_id <- Sys.getenv("MEETUP_CLIENT_ID")
  original_secret <- Sys.getenv("MEETUP_CLIENT_SECRET")

  result <- mock_if_no_auth()

  expect_equal(Sys.getenv("MEETUP_CLIENT_ID"), original_id)
  expect_equal(Sys.getenv("MEETUP_CLIENT_SECRET"), original_secret)
})

test_that("validate_graphql_variables returns invisibly", {
  result <- validate_graphql_variables(list(query = "test", limit = 10))
  expect_true(result)
})

test_that("uq_filename handles edge case with numbered files", {
  temp_dir <- withr::local_tempdir()
  test_file <- file.path(temp_dir, "test.txt")

  # Create files with gaps in numbering
  file.create(test_file)
  file.create(file.path(temp_dir, "test1.txt"))
  file.create(file.path(temp_dir, "test3.txt")) # Skip test2.txt
  file.create(file.path(temp_dir, "test4.txt"))

  result <- uq_filename(test_file)
  expect_equal(result, file.path(temp_dir, "test2.txt"))
})

test_that("process_datetime_fields preserves non-datetime columns", {
  test_data <- dplyr::tibble(
    id = 1:2,
    name = c("Alice", "Bob"),
    created = c("2023-01-01T10:00:00Z", "2023-01-02T11:00:00Z"),
    count = c(5, 10),
    active = c(TRUE, FALSE)
  )

  result <- process_datetime_fields(test_data, "created")

  expect_equal(result$id, test_data$id)
  expect_equal(result$name, test_data$name)
  expect_equal(result$count, test_data$count)
  expect_equal(result$active, test_data$active)
  expect_s3_class(result$created, "POSIXct")
})
