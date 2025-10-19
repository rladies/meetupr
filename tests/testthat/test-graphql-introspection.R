test_that("introspection functions work correctly", {
  # Use a single cassette for all introspection tests
  vcr::local_cassette("introspection")
  mock_if_no_auth()

  # Test meetup_schema returns expected schema format
  schema <- meetup_schema()
  expect_true(is.list(schema))

  # Test raw response
  raw_schema <- meetup_schema(asis = TRUE)
  expect_true(jsonlite::validate(raw_schema))

  # Test meetup_schema_queries extracts query fields
  query_fields <- meetup_schema_queries(schema = schema)
  expect_true(is.data.frame(query_fields))

  # Test meetup_schema_mutations extracts mutation fields
  mutations <- meetup_schema_mutations(schema = schema)
  expect_true(is.data.frame(mutations))

  # Test meetup_schema_search identifies matching types
  types <- meetup_schema_search("user", schema = schema)
  expect_true(is.data.frame(types))
  expect_gt(nrow(types), 0)
})

test_that("meetup_schema_queries handles NULL descriptions", {
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

  result <- meetup_schema_queries(schema = mock_schema)
  expect_equal(result$description, "")
})


test_that("meetup_schema_queries processes schema correctly", {
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

  result <- meetup_schema_queries(schema = mock_schema)

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

test_that("meetup_schema_queries calls meetup_schema when schema is NULL", {
  mock_schema <- list(
    queryType = list(name = "Query"),
    types = list(
      list(name = "Query", fields = list())
    )
  )

  local_mocked_bindings(
    meetup_schema = function() mock_schema
  )

  result <- meetup_schema_queries()
  expect_s3_class(result, "data.frame")
})

test_that("meetup_schema_mutations handles missing mutationType", {
  schema_no_mutations <- list(
    queryType = list(name = "Query"),
    mutationType = NULL,
    types = list()
  )

  result <- meetup_schema_mutations(schema = schema_no_mutations)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)
  expect_equal(result$message, "No mutations available")
})

test_that("meetup_schema_mutations processes mutations correctly", {
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

  result <- meetup_schema_mutations(schema = mock_schema)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2)
  expect_equal(result$field_name, c("createUser", "deleteUser"))
  expect_equal(result$description, c("Create a new user", ""))
  expect_equal(result$args_count, c(1, 0))
  expect_equal(result$return_type, c("User", "Boolean"))
})


test_that("meetup_schema_mutations handles schema without mutationType", {
  local_mocked_bindings(meetup_schema = function(...) {
    list(mutationType = NULL)
  })
  mutations <- meetup_schema_mutations()
  expect_true(all(mutations$message == "No mutations available"))
})

test_that("meetup_schema returns schema structure", {
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
      list(data = list(`__schema` = mock_schema))
    }
  )

  result <- meetup_schema()
  expect_equal(result, mock_schema)
})

test_that("meetup_schema returns JSON when asis=TRUE", {
  mock_schema <- list(
    queryType = list(name = "Query"),
    types = list()
  )

  local_mocked_bindings(
    execute_from_template = function(template) {
      list(data = list(`__schema` = mock_schema))
    }
  )

  result <- meetup_schema(asis = TRUE)
  expect_type(result, "character")
  expect_true(jsonlite::validate(result))

  parsed <- jsonlite::fromJSON(result)
  expect_equal(parsed$queryType$name, "Query")
})

test_that("meetup_schema_search finds matching types by name", {
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

  result <- meetup_schema_search("user", schema = mock_schema)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2)
  expect_true(all(grepl("user", result$type_name, ignore.case = TRUE)))
  expect_equal(result$field_count, c(2, 0))
})

test_that("meetup_schema_search finds matching types by description", {
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

  result <- meetup_schema_search("event", schema = mock_schema)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)
  expect_equal(result$type_name, "Profile")
})

test_that("meetup_schema_search handles empty results", {
  mock_schema <- list(
    types = list(
      list(
        name = "User",
        kind = "OBJECT",
        description = "A user"
      )
    )
  )

  result <- meetup_schema_search("nonexistent", schema = mock_schema)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)
})


test_that("meetup_schema_search handles NULL descriptions", {
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

  result <- meetup_schema_search("test", schema = mock_schema)
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


test_that("meetup_schema_type handles missing isDeprecated field", {
  mock_schema <- list(
    types = list(
      list(
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

  result <- meetup_schema_type("Test", schema = mock_schema)
  expect_equal(result$deprecated, FALSE)
})


test_that("meetup_schema_type returns error for no matching types", {
  schema <- list(
    types = list(
      list(name = "TypeB", kind = "Object")
    )
  )

  expect_error(
    meetup_schema_type("UnmatchedType", schema = schema),
    "Type not found"
  )
})

test_that("meetup_schema_type handles multiple matching types", {
  schema <- list(
    types = list(
      list(name = "Type1", kind = "Object"),
      list(name = "Type1Sub", kind = "Object")
    )
  )

  result <- meetup_schema_type("Type1", schema = schema)

  expect_equal(nrow(result), 2)
})

test_that("meetup_schema_type handles type with no fields", {
  schema <- list(
    types = list(
      list(name = "TypeC", kind = "Object", fields = NULL)
    )
  )

  result <- meetup_schema_type("TypeC", schema = schema)

  expect_equal(
    result,
    dplyr::tibble(
      message = "Type TypeC has no fields"
    )
  )
})


test_that("meetup_schema_type handles missing types", {
  local_mocked_bindings(meetup_schema = function(...) list(types = list()))
  expect_error(meetup_schema_type(
    type_name = "InvalidType",
    schema = list(types = list())
  ))
})

test_that("meetup_schema_type handles exact type match", {
  mock_schema <- list(
    types = list(
      list(
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

  result <- meetup_schema_type("User", schema = mock_schema)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2)
  expect_named(result, c("field_name", "description", "type", "deprecated"))
  expect_equal(result$field_name, c("id", "email"))
  expect_equal(result$description, c("Unique identifier", ""))
  expect_equal(result$deprecated, c(FALSE, TRUE))
})
