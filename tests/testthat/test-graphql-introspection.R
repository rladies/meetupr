test_that("meetup_introspect returns expected schema format", {
  vcr::local_cassette("introspection_query")
  schema <- meetup_introspect()
  expect_true(is.list(schema))
})

test_that("meetup_introspect handles raw response", {
  vcr::local_cassette("introspection_raw")
  raw_schema <- meetup_introspect(asis = TRUE)
  expect_true(jsonlite::validate(raw_schema))
})

test_that("explore_query_fields extracts query fields", {
  vcr::local_cassette("introspection_query_fields")
  schema <- meetup_introspect()
  query_fields <- explore_query_fields(schema)
  expect_true(is.data.frame(query_fields))
})

test_that("explore_query_fields handles NULL descriptions", {
  mock_schema <- list(
    queryType = list(name = "Query"),
    types = list(
      list(
        name = "Query",
        fields = list(
          list(
            name = "test",
            description = NULL,
            args = list(),
            type = list(kind = "SCALAR", name = "String")
          )
        )
      )
    )
  )

  result <- explore_query_fields(mock_schema)
  expect_equal(result$description, "")
})


test_that("explore_query_fields processes schema correctly", {
  mock_schema <- list(
    queryType = list(name = "Query"),
    types = list(
      list(
        name = "Query",
        fields = list(
          list(
            name = "user",
            description = "Get a user",
            args = list(list(name = "id", type = "ID")),
            type = list(kind = "OBJECT", name = "User")
          ),
          list(
            name = "events",
            description = NULL,
            args = list(),
            type = list(kind = "LIST", ofType = list(name = "Event"))
          )
        )
      ),
      list(name = "User", kind = "OBJECT")
    )
  )

  result <- explore_query_fields(mock_schema)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2)
  expect_named(
    result,
    c("field_name", "description", "args_count", "return_type")
  )
  expect_equal(result$field_name, c("events", "user"))
  expect_equal(result$description, c("", "Get a user"))
  expect_equal(result$args_count, c(0, 1))
  expect_equal(result$return_type, c("Event", "User"))
})

test_that("explore_query_fields calls meetup_introspect when schema is NULL", {
  mock_schema <- list(
    queryType = list(name = "Query"),
    types = list(
      list(name = "Query", fields = list())
    )
  )

  local_mocked_bindings(
    meetup_introspect = function() mock_schema
  )

  result <- explore_query_fields()
  expect_s3_class(result, "data.frame")
})

test_that("explore_mutations handles missing mutationType", {
  schema_no_mutations <- list(
    queryType = list(name = "Query"),
    mutationType = NULL,
    types = list()
  )

  result <- explore_mutations(schema_no_mutations)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)
  expect_equal(result$message, "No mutations available")
})

test_that("explore_mutations processes mutations correctly", {
  mock_schema <- list(
    mutationType = list(name = "Mutation"),
    types = list(
      list(
        name = "Mutation",
        fields = list(
          list(
            name = "createUser",
            description = "Create a new user",
            args = list(list(name = "input", type = "UserInput")),
            type = list(kind = "OBJECT", name = "User")
          ),
          list(
            name = "deleteUser",
            description = NULL,
            args = list(),
            type = list(kind = "SCALAR", name = "Boolean")
          )
        )
      )
    )
  )

  result <- explore_mutations(mock_schema)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2)
  expect_equal(result$field_name, c("createUser", "deleteUser"))
  expect_equal(result$description, c("Create a new user", ""))
  expect_equal(result$args_count, c(1, 0))
  expect_equal(result$return_type, c("User", "Boolean"))
})


test_that("explore_mutations handles schema without mutationType", {
  local_mocked_bindings(meetup_introspect = function(...) {
    list(mutationType = NULL)
  })
  mutations <- explore_mutations()
  expect_true(all(mutations$message == "No mutations available"))
})

test_that("explore_mutations extracts mutation fields", {
  vcr::local_cassette("introspection_explore_mutations")
  schema <- meetup_introspect()
  mutations <- explore_mutations(schema)
  expect_true(is.data.frame(mutations))
})


test_that("meetup_introspect returns schema structure", {
  mock_schema <- list(
    queryType = list(name = "Query"),
    mutationType = list(name = "Mutation"),
    types = list(
      list(name = "Query", kind = "OBJECT"),
      list(name = "Mutation", kind = "OBJECT")
    )
  )

  local_mocked_bindings(
    execute_from_template = function(template) {
      expect_equal(template, "introspection")
      list(data = list(`__schema` = mock_schema))
    }
  )

  result <- meetup_introspect()
  expect_equal(result, mock_schema)
})

test_that("meetup_introspect returns JSON when asis=TRUE", {
  mock_schema <- list(
    queryType = list(name = "Query"),
    types = list()
  )

  local_mocked_bindings(
    execute_from_template = function(template) {
      list(data = list(`__schema` = mock_schema))
    }
  )

  result <- meetup_introspect(asis = TRUE)
  expect_type(result, "character")
  expect_true(jsonlite::validate(result))

  parsed <- jsonlite::fromJSON(result)
  expect_equal(parsed$queryType$name, "Query")
})


test_that("search_types identifies matching types", {
  vcr::local_cassette("introspection_search_types")
  schema <- meetup_introspect()
  types <- search_types(schema, "user")
  expect_true(is.data.frame(types))
  expect_gt(nrow(types), 0)
})

test_that("search_types finds matching types by name", {
  mock_schema <- list(
    types = list(
      list(
        name = "User",
        kind = "OBJECT",
        description = "A user account",
        fields = list(list(name = "id"), list(name = "name"))
      ),
      list(
        name = "UserInput",
        kind = "INPUT_OBJECT",
        description = "Input for user creation",
        fields = NULL
      ),
      list(
        name = "Event",
        kind = "OBJECT",
        description = "An event",
        fields = list(list(name = "id"))
      )
    )
  )

  result <- search_types(mock_schema, "user")

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2)
  expect_true(all(grepl("user", result$type_name, ignore.case = TRUE)))
  expect_equal(result$field_count, c(2, 0))
})

test_that("search_types finds matching types by description", {
  mock_schema <- list(
    types = list(
      list(
        name = "Account",
        kind = "OBJECT",
        description = "User account information",
        fields = list()
      ),
      list(
        name = "Profile",
        kind = "OBJECT",
        description = "Event profile data",
        fields = list()
      )
    )
  )

  result <- search_types(mock_schema, "event")

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)
  expect_equal(result$type_name, "Profile")
})

test_that("search_types handles empty results", {
  mock_schema <- list(
    types = list(
      list(name = "User", kind = "OBJECT", description = "A user")
    )
  )

  result <- search_types(mock_schema, "nonexistent")

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)
})


test_that("search_types handles NULL descriptions", {
  mock_schema <- list(
    types = list(
      list(
        name = "TestType",
        kind = "OBJECT",
        description = NULL,
        fields = list()
      )
    )
  )

  result <- search_types(mock_schema, "test")
  expect_equal(result$description, "")
})

test_that("type_name handles NON_NULL types", {
  non_null_type <- list(
    kind = "NON_NULL",
    ofType = list(kind = "SCALAR", name = "String")
  )

  result <- type_name(non_null_type)
  expect_equal(result, "String")
})

test_that("type_name handles LIST types", {
  list_type <- list(
    kind = "LIST",
    ofType = list(
      kind = "NON_NULL",
      ofType = list(kind = "OBJECT", name = "User")
    )
  )

  result <- type_name(list_type)
  expect_equal(result, "User")
})

test_that("type_name handles simple types", {
  simple_type <- list(kind = "OBJECT", name = "Event")

  result <- type_name(simple_type)
  expect_equal(result, "Event")
})


test_that("get_type_fields handles missing isDeprecated field", {
  mock_schema <- list(
    types = list(
      Test = list(
        name = "Test",
        fields = list(
          list(
            name = "field1",
            description = "Test field",
            type = list(kind = "SCALAR", name = "String"),
            isDeprecated = NULL
          )
        )
      )
    )
  )

  result <- get_type_fields(mock_schema, "Test")
  expect_equal(result$deprecated, FALSE)
})


test_that("get_type_fields returns error for no matching types", {
  schema <- list(
    types = list(
      TypeB = list(name = "TypeB", kind = "Object")
    )
  )

  expect_error(
    get_type_fields(schema, "UnmatchedType"),
    "Type not found"
  )
})

test_that("get_type_fields handles multiple matching types", {
  schema <- list(
    types = list(
      Type1 = list(name = "Type1", kind = "Object"),
      Type1Sub = list(name = "Type1Sub", kind = "Object")
    )
  )

  result <- get_type_fields(schema, "Type1")

  expect_equal(nrow(result), 2)
})

test_that("get_type_fields handles type with no fields", {
  schema <- list(
    types = list(
      TypeC = list(name = "TypeC", kind = "Object", fields = NULL)
    )
  )

  result <- get_type_fields(schema, "TypeC")

  expect_equal(
    result,
    dplyr::tibble(
      message = "Type TypeC has no fields"
    )
  )
})


test_that("get_type_fields handles missing types", {
  local_mocked_bindings(meetup_introspect = function(...) list(types = list()))
  expect_error(get_type_fields(
    schema = list(types = list()),
    type_name = "InvalidType"
  ))
})

test_that("get_type_fields handles exact type match", {
  mock_schema <- list(
    types = list(
      User = list(
        name = "User",
        fields = list(
          list(
            name = "id",
            description = "Unique identifier",
            type = list(kind = "SCALAR", name = "ID"),
            isDeprecated = FALSE
          ),
          list(
            name = "email",
            description = NULL,
            type = list(kind = "SCALAR", name = "String"),
            isDeprecated = TRUE
          )
        )
      )
    )
  )

  result <- get_type_fields(mock_schema, "User")

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2)
  expect_named(result, c("field_name", "description", "type", "deprecated"))
  expect_equal(result$field_name, c("id", "email"))
  expect_equal(result$description, c("Unique identifier", ""))
  expect_equal(result$deprecated, c(FALSE, TRUE))
})
