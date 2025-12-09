describe("validate_graphql_variables()", {
  it("works correctly", {
    named_vars <- list(query = "test", limit = 10)
    expect_equal(validate_graphql_variables(named_vars), named_vars)
    expect_equal(validate_graphql_variables(list()), list())

    unnamed_vars <- list("test", "value")
    expect_error(
      validate_graphql_variables(unnamed_vars),
      "All GraphQL variables must be named"
    )

    partial_vars <- list(query = "test", "unnamed_value")
    expect_error(
      validate_graphql_variables(partial_vars),
      "All GraphQL variables must be named"
    )
  })

  it("handles mixed named/unnamed variables", {
    mixed_vars <- list(query = "test", "unnamed", limit = 10)
    expect_error(
      validate_graphql_variables(mixed_vars),
      "All GraphQL variables must be named"
    )

    vars_with_null_names <- list("value1", "value2")
    names(vars_with_null_names) <- c("name1", "")
    expect_error(
      validate_graphql_variables(vars_with_null_names),
      "All GraphQL variables must be named"
    )
  })
})

describe("paste_before_ext()", {
  it("works correctly", {
    expect_equal(paste_before_ext("file.txt", "_backup"), "file_backup.txt")
    expect_equal(paste_before_ext("file.tar.gz", "_v2"), "file.tar_v2.gz")
    expect_equal(paste_before_ext("filename", "_suffix"), "filename_suffix")
    expect_equal(
      paste_before_ext("file.txt", c("_1", "_2")),
      c("file_1.txt", "file_2.txt")
    )
  })
})

describe("process_datetime_fields()", {
  it("converts datetime strings", {
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

  it("handles missing fields gracefully", {
    test_data <- dplyr::tibble(id = "test", name = "Test")
    result <- process_datetime_fields(test_data, c("missing_field", "created"))
    expect_equal(result, test_data)
  })

  it("preserves non-datetime columns", {
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

  it("handles various datetime formats", {
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

  it("handles malformed dates gracefully", {
    test_data <- dplyr::tibble(
      id = 1:2,
      bad_date = c("not-a-date", "2023-13-45T25:70:00Z"),
      good_date = c("2023-01-01T10:00:00Z", "2023-01-02T11:00:00Z")
    )
    result <- process_datetime_fields(test_data, c("bad_date", "good_date"))
    expect_s3_class(result$good_date, "POSIXct")
    expect_true(all(is.na(result$bad_date)))
  })

  it("handles empty data frames", {
    empty_df <- dplyr::tibble()
    result <- process_datetime_fields(empty_df, c("created", "updated"))
    expect_equal(result, empty_df)
    test_df <- dplyr::tibble(id = 1, name = "test")
    result2 <- process_datetime_fields(test_df, c("created", "updated"))
    expect_equal(result2, test_df)
  })
})

describe("uq_filename()", {
  it("generates unique filenames", {
    temp_dir <- withr::local_tempdir()
    test_file <- file.path(temp_dir, "test.txt")
    result1 <- uq_filename(test_file)
    expect_equal(result1, test_file)
    file.create(test_file)
    result2 <- uq_filename(test_file)
    expect_true(result2 != test_file)
    expect_true(grepl("test1\\.txt$", result2))
    file.create(result2)
    result3 <- uq_filename(test_file)
    expect_true(grepl("test2\\.txt$", result3))
  })

  it("validates input", {
    expect_error(
      uq_filename(c("file1.txt", "file2.txt")),
      "length\\(file_name\\) == 1L"
    )
    expect_error(uq_filename(123), "is.character\\(file_name\\)")
  })

  it("handles complex scenarios", {
    temp_dir <- withr::local_tempdir()
    base_file <- file.path(temp_dir, "testfile")
    result1 <- uq_filename(base_file)
    expect_equal(result1, base_file)
    file.create(base_file)
    result2 <- uq_filename(base_file)
    expect_true(grepl("testfile1$", result2))
    nested_dir <- file.path(temp_dir, "nested", "path")
    dir.create(nested_dir, recursive = TRUE)
    nested_file <- file.path(nested_dir, "nested.txt")
    result3 <- uq_filename(nested_file)
    expect_equal(result3, nested_file)
  })

  it("finds first available number", {
    temp_dir <- withr::local_tempdir()
    test_file <- file.path(temp_dir, "test.txt")
    file.create(test_file)
    file.create(file.path(temp_dir, "test1.txt"))
    file.create(file.path(temp_dir, "test2.txt"))
    result <- uq_filename(test_file)
    expect_true(grepl("test3\\.txt$", result))
    expect_false(file.exists(result))
  })

  it("handles edge case with numbered files", {
    temp_dir <- withr::local_tempdir()
    test_file <- file.path(temp_dir, "test.txt")
    file.create(test_file)
    file.create(file.path(temp_dir, "test1.txt"))
    file.create(file.path(temp_dir, "test3.txt"))
    file.create(file.path(temp_dir, "test4.txt"))
    result <- uq_filename(test_file)
    expect_true(grepl("test2\\.txt$", result))
    expect_false(file.exists(result))
  })

  it("handles exhausted candidates", {
    temp_dir <- withr::local_tempdir()
    test_file <- file.path(temp_dir, "test.txt")
    file.create(test_file)
    for (i in seq_len(1000)) {
      file.create(file.path(temp_dir, paste0("test", i, ".txt")))
    }
    result <- uq_filename(test_file)
    expect_true(grepl("test1001\\.txt$", result))
    expect_false(file.exists(result))
  })
})

describe("get_country_code()", {
  it("handles single values", {
    local_mocked_bindings(
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

  it("handles lists", {
    local_mocked_bindings(
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
    empty_result <- get_country_code(list())
    expect_equal(empty_result, list())
  })

  it("calls countrycode correctly", {
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

  it("handles NULL", {
    expect_null(country_code(NULL))
  })
})

describe("local_meetupr_debug()", {
  it("sets and resets debug level", {
    withr::local_envvar(MEETUPR_DEBUG = 0)
    local_meetupr_debug(2)
    expect_equal(Sys.getenv("MEETUPR_DEBUG"), "2")
  })

  it("handles custom environments", {
    withr::local_envvar(MEETUPR_DEBUG = "0")
    env <- new.env()
    local_meetupr_debug(2, env = env)
    Sys.setenv(MEETUPR_DEBUG = 0)
    expect_equal(Sys.getenv("MEETUPR_DEBUG"), "0")
    eval(withr::defer(Sys.setenv(MEETUPR_DEBUG = 1), envir = env))
  })

  it("accepts valid debug levels", {
    withr::local_envvar(MEETUPR_DEBUG = 0)
    local_meetupr_debug(1)
    expect_equal(Sys.getenv("MEETUPR_DEBUG"), "1")
  })

  it("rejects invalid debug levels", {
    expect_error(local_meetupr_debug(level = "invalid"))
  })
})

describe("check_debug_mode()", {
  it("detects debug flag", {
    withr::local_envvar(MEETUPR_DEBUG = "1")
    expect_true(check_debug_mode())
    withr::local_envvar(MEETUPR_DEBUG = "0")
    expect_false(check_debug_mode())
    withr::local_envvar(MEETUPR_DEBUG = "true")
    expect_false(check_debug_mode())
    withr::local_envvar(MEETUPR_DEBUG = "")
    expect_false(check_debug_mode())
    withr::local_envvar(MEETUPR_DEBUG = 1)
    expect_true(check_debug_mode())
  })
})


describe("is_empty()", {
  it("returns TRUE for NULL", {
    expect_true(is_empty(NULL))
  })

  it("returns TRUE for NA", {
    expect_true(is_empty(NA))
  })

  it("returns TRUE for empty string", {
    expect_true(is_empty(""))
  })

  it("returns FALSE for non-empty string", {
    expect_false(is_empty("a"))
    expect_false(is_empty("0"))
    expect_false(is_empty("FALSE"))
  })

  it("returns FALSE for logical TRUE/FALSE", {
    expect_false(is_empty(TRUE))
    expect_false(is_empty(FALSE))
  })

  it("returns FALSE for numeric values", {
    expect_false(is_empty(0))
    expect_false(is_empty(1))
    expect_false(is_empty(-1))
  })

  it("returns FALSE for vectors of length > 1", {
    expect_false(is_empty(c("a", "b")))
    expect_false(is_empty(c(NA, "")))
    expect_false(is_empty(c(1, 2)))
    expect_false(is_empty(c(TRUE, FALSE)))
  })

  it("returns FALSE for list of length > 1", {
    expect_false(is_empty(list("a", "b")))
  })

  it("returns TRUE for character(0)", {
    expect_true(is_empty(character(0)))
  })

  it("returns FALSE for raw vectors", {
    expect_false(is_empty(as.raw(1)))
  })
})
