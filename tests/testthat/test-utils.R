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

test_that("add_country_name adds country names correctly", {
  mock_items <- list(
    list(id = "1", country = "us"),
    list(id = "2", country = "ca"),
    list(id = "3", country = "fr")
  )

  get_country_fn <- function(item) item$country

  result <- add_country_name(mock_items, get_country_fn)

  expect_length(result, 3)
  expect_equal(result[[1]]$country_name, "United States")
  expect_equal(result[[2]]$country_name, "Canada")
  expect_equal(result[[3]]$country_name, "France")
})

test_that("add_country_name handles missing country codes", {
  mock_items <- list(
    list(id = "1"), # Missing country
    list(id = "2", country = ""), # Empty country
    list(id = "3", country = NULL), # NULL country
    list(id = "4", country = NA_character_), # NA country
    list(id = "5", country = "invalid") # Invalid country code
  )

  get_country_fn <- function(item) item$country

  result <- add_country_name(mock_items, get_country_fn)

  expect_length(result, 5)
  expect_true(is.na(result[[1]]$country_name)) # Missing
  expect_true(is.na(result[[2]]$country_name)) # Empty
  expect_true(is.na(result[[3]]$country_name)) # NULL
  expect_true(is.na(result[[4]]$country_name)) # NA
  # Invalid country code behavior depends on countrycode package
})

test_that("add_country_name works with custom extraction function", {
  # Test with nested country data
  mock_items <- list(
    list(
      id = "1",
      venue = list(location = list(country = "gb"))
    ),
    list(
      id = "2",
      venue = list(location = list(country = "de"))
    )
  )

  get_nested_country <- function(item) {
    if (!is.null(item$venue) && !is.null(item$venue$location)) {
      return(item$venue$location$country)
    }
    return(NULL)
  }

  result <- add_country_name(mock_items, get_nested_country)

  expect_length(result, 2)
  expect_equal(result[[1]]$country_name, "United Kingdom")
  expect_equal(result[[2]]$country_name, "Germany")
})

test_that("add_country_name preserves original item structure", {
  mock_items <- list(
    list(
      id = "1",
      name = "Test Item",
      country = "jp",
      other_data = list(value = 42)
    )
  )

  get_country_fn <- function(item) item$country

  result <- add_country_name(mock_items, get_country_fn)

  expect_length(result, 1)

  # Original fields should be preserved
  expect_equal(result[[1]]$id, "1")
  expect_equal(result[[1]]$name, "Test Item")
  expect_equal(result[[1]]$other_data$value, 42)

  # New field should be added
  expect_equal(result[[1]]$country_name, "Japan")
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

  expect_equal(result, test_data) # Should be unchanged
})
