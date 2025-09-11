test_that("meetup_introspect returns expected schema format", {
  vcr::use_cassette("introspection_query", {
    schema <- meetup_introspect()
    expect_true(is.list(schema))
  })
})

test_that("meetup_introspect handles raw response", {
  vcr::use_cassette("introspection_raw", {
    raw_schema <- meetup_introspect(asis = TRUE)
    expect_true(jsonlite::validate(raw_schema))
  })
})

test_that("explore_query_fields extracts query fields", {
  vcr::use_cassette("query_fields", {
    schema <- meetup_introspect()
    query_fields <- explore_query_fields(schema)
    expect_true(is.data.frame(query_fields))
  })
})

test_that("explore_mutations handles schema without mutationType", {
  local_mocked_bindings(meetup_introspect = function(...) {
    list(mutationType = NULL)
  })
  mutations <- explore_mutations()
  expect_true(all(mutations$message == "No mutations available"))
})

test_that("explore_mutations extracts mutation fields", {
  vcr::use_cassette("explore_mutations", {
    schema <- meetup_introspect()
    mutations <- explore_mutations(schema)
    expect_true(is.data.frame(mutations))
  })
})

test_that("search_types identifies matching types", {
  vcr::use_cassette("search_types", {
    schema <- meetup_introspect()
    types <- search_types(schema, "user")
    expect_true(is.data.frame(types))
    expect_gt(nrow(types), 0)
  })
})

test_that("get_type_fields handles missing types", {
  local_mocked_bindings(meetup_introspect = function(...) list(types = list()))
  expect_error(get_type_fields(
    schema = list(types = list()),
    type_name = "InvalidType"
  ))
})

test_that("get_type_fields returns fields for a valid type", {
  vcr::use_cassette("get_type_fields", {
    schema <- meetup_introspect()
    fields <- get_type_fields(schema, "User")
    expect_true(is.data.frame(fields))
  })
})
