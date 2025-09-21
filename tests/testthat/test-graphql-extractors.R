test_that("process_graphql_list returns empty tibble for empty input", {
  result <- process_graphql_list(list())

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
  expect_equal(ncol(result), 0)
})

test_that("process_graphql_list handles single item", {
  dlist <- list(
    list(name = "test", value = 42)
  )

  result <- process_graphql_list(dlist)

  expect_equal(nrow(result), 1)
  expect_equal(result$name, "test")
  expect_equal(result$value, 42)
})

test_that("process_graphql_list flattens nested structures", {
  dlist <- list(
    list(
      user = list(name = "John", id = 123),
      event = list(title = "Test Event")
    )
  )

  result <- process_graphql_list(dlist)

  expect_true("user_name" %in% names(result))
  expect_true("user_id" %in% names(result))
  expect_true("event_title" %in% names(result))
  expect_equal(result$user_name, "John")
})

test_that("multiples_to_listcol handles single column case", {
  df <- dplyr::tibble(
    name = c("John", "Jane"),
    age = c(30, 25)
  )

  result <- multiples_to_listcol(df)

  expect_equal(names(result), c("name", "age"))
  expect_equal(result$name, c("John", "Jane"))
  expect_equal(result$age, c(30, 25))
})

test_that("multiples_to_listcol handles duplicate columns", {
  df <- dplyr::tibble(
    name...1 = c("John", "Jane"),
    name...2 = c("Johnny", "Janie"),
    age = c(30, 25)
  )

  result <- multiples_to_listcol(df)

  expect_true("name" %in% names(result))
  expect_true("age" %in% names(result))
  expect_equal(result$age, c(30, 25))
})

test_that("multiples_to_listcol handles base name with suffixed columns", {
  df <- dplyr::tibble(
    name = c("base1", "base2"),
    name...1 = c("first1", "first2"),
    name...2 = c("second1", "second2")
  )

  result <- multiples_to_listcol(df)

  expect_true("name" %in% names(result))
  expect_length(result$name, 2)
})

test_that("multiples_to_listcol handles NA values correctly", {
  df <- dplyr::tibble(
    field...1 = c("value1", NA),
    field...2 = c(NA, "value2")
  )

  result <- multiples_to_listcol(df)

  expect_true("field" %in% names(result))
  expect_equal(result$field[[1]], "value1")
  expect_equal(result$field[[2]], "value2")
})

test_that("multiples_to_listcol handles all NA values", {
  df <- dplyr::tibble(
    field...1 = c(NA, NA),
    field...2 = c(NA, NA)
  )

  result <- multiples_to_listcol(df)

  expect_true("field" %in% names(result))
  expect_equal(length(result$field[[1]]), 0)
  expect_equal(length(result$field[[2]]), 0)
})

test_that("multiples_to_listcol handles single non-NA value", {
  df <- dplyr::tibble(
    field...1 = c("only_value", NA),
    field...2 = c(NA, NA)
  )

  result <- multiples_to_listcol(df)

  expect_equal(result$field[[1]], "only_value")
})

test_that("multiples_keep_first handles single columns", {
  df <- dplyr::tibble(
    name = c("John", "Jane"),
    age = c(30, 25)
  )

  result <- multiples_keep_first(df)

  expect_equal(names(result), c("name", "age"))
  expect_equal(result$name, c("John", "Jane"))
  expect_equal(result$age, c(30, 25))
})

test_that("multiples_keep_first prefers base name when present", {
  df <- dplyr::tibble(
    field = c("base1", "base2"),
    field...1 = c("first1", "first2"),
    other = c("other1", "other2")
  )

  result <- multiples_keep_first(df)

  expect_equal(result$field, c("base1", "base2"))
  expect_equal(result$other, c("other1", "other2"))
})

test_that("multiples_keep_first takes first numbered when no base", {
  df <- dplyr::tibble(
    field...2 = c("second1", "second2"),
    field...1 = c("first1", "first2"),
    other = c("other1", "other2")
  )

  result <- multiples_keep_first(df)

  expect_equal(result$field, c("first1", "first2"))
  expect_equal(result$other, c("other1", "other2"))
})

test_that("escape_regex handles special characters", {
  expect_equal(escape_regex("test.name"), "test\\.name")
  expect_equal(escape_regex("test(name)"), "test\\(name\\)")
  expect_equal(escape_regex("test[name]"), "test\\[name\\]")
  expect_equal(escape_regex("test^name"), "test\\^name")
  expect_equal(escape_regex("test$name"), "test\\$name")
  expect_equal(escape_regex("test*name"), "test\\*name")
  expect_equal(escape_regex("test+name"), "test\\+name")
  expect_equal(escape_regex("test?name"), "test\\?name")
  expect_equal(escape_regex("test{name}"), "test\\{name\\}")
  expect_equal(escape_regex("test|name"), "test\\|name")
})

test_that("clean_field_names converts camelCase to snake_case", {
  df <- dplyr::tibble(
    firstName = "John",
    lastName = "Doe",
    eventType = "meetup"
  )

  result <- clean_field_names(df)

  expect_true("first_name" %in% names(result))
  expect_true("last_name" %in% names(result))
  expect_true("event_type" %in% names(result))
})

test_that("clean_field_names handles dots and dashes", {
  df <- dplyr::tibble(
    `user.name` = "John",
    `event-title` = "Test",
    `long--dash` = "value"
  )

  result <- clean_field_names(df)

  expect_true("user_name" %in% names(result))
  expect_true("event_title" %in% names(result))
  expect_true("long_dash" %in% names(result))
})

test_that("clean_field_names removes duplicate underscores", {
  df <- dplyr::tibble(
    `user__name` = "John",
    `event___title` = "Test"
  )

  result <- clean_field_names(df)

  expect_true("user_name" %in% names(result))
  expect_true("event_title" %in% names(result))
})

test_that("clean_field_names handles special suffixes", {
  df <- dplyr::tibble(
    eventTotalCount = 10,
    imageBaseUrl = "http://example.com",
    userMetadataField = "value"
  )

  result <- clean_field_names(df)

  expect_true("event_count" %in% names(result))
  expect_true("image_url" %in% names(result))
  expect_true("user_field" %in% names(result))
})

test_that("clean_field_names removes duplicate words", {
  df <- dplyr::tibble(
    eventEventTitle = "Test Event",
    userUserName = "John Doe"
  )

  result <- clean_field_names(df)

  expect_true("event_title" %in% names(result))
  expect_true("user_name" %in% names(result))
})

test_that("clean_field_name works with edge cases", {
  expect_equal(clean_field_name(""), "")
  expect_equal(clean_field_name("a"), "a")
  expect_equal(clean_field_name("A"), "a")
  expect_equal(clean_field_name("camelCase"), "camel_case")
  expect_equal(clean_field_name("snake_case"), "snake_case")
})

test_that("gsub2 works as gsub wrapper", {
  expect_equal(gsub2("hello world", "world", "R"), "hello R")
  expect_equal(gsub2("test.test", "\\.", "_"), "test_test")
})

test_that("silent_bind_rows suppresses messages", {
  df1 <- dplyr::tibble(a = 1, b = "x")
  df2 <- dplyr::tibble(a = 2, c = "y")

  expect_silent({
    result <- silent_bind_rows(df1, df2)
  })

  expect_equal(nrow(result), 2)
  expect_true(all(c("a", "b", "c") %in% names(result)))
})
