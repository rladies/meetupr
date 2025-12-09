#' Introspect the Meetup GraphQL API schema
#'
#' This function performs an introspection query on the Meetup GraphQL API to
#' retrieve the full schema details, including available query types, mutation
#' types, and type definitions.
#'
#' @param asis Logical; if TRUE, returns the raw response from the API as JSON.
#'   If FALSE (default), returns the parsed schema object.
#'
#' @return If `asis` is FALSE (default), the parsed schema object with nested
#'   lists containing query types, mutation types, and type definitions. If
#'   `asis` is TRUE, a JSON string representation of the schema.
#'
#' @examples
#' \dontshow{
#' vcr::insert_example_cassette("meetupr_schema", package = "meetupr")
#' meetupr:::mock_if_no_auth()
#' }
#' # Get the full schema
#' schema <- meetupr_schema()
#'
#' # Explore what's available
#' names(schema)
#'
#' # Get as JSON for external tools
#' schema_json <- meetupr_schema(asis = TRUE)
#' \dontshow{
#' vcr::eject_cassette()
#' }
#'
#' @export
meetupr_schema <- function(asis = FALSE) {
  result <- template_path("introspection") |>
    execute_from_template()
  result <- result$data$`__schema`

  if (asis) {
    return(jsonlite::toJSON(
      result,
      auto_unbox = TRUE,
      pretty = TRUE
    ))
  }

  result
}

#' Explore available query fields in the Meetup GraphQL API
#'
#' This function retrieves the root-level query fields available in the Meetup
#' GraphQL API. These are the entry points for data fetching (e.g.,
#' `groupByUrlname`, `event`, etc.).
#'
#' @template schema
#' @return A tibble with details about each query field, including:
#'   \describe{
#'     \item{field_name}{Name of the query field}
#'     \item{description}{Human-readable description of the field}
#'     \item{args_count}{Number of arguments the field accepts}
#'     \item{return_type}{The GraphQL type returned by this field}
#'   }
#'
#' @examples
#' \dontrun{
#' # List all available queries
#' queries <- meetupr_schema_queries()
#'
#' # Find group-related queries
#' queries |>
#'   dplyr::filter(grepl("group", field_name, ignore.case = TRUE))
#' }
#'
#' @export
meetupr_schema_queries <- function(schema = meetupr_schema()) {
  query_type_name <- schema$queryType$name

  query_type <- schema$types[sapply(schema$types, function(x) {
    x$name == query_type_name
  })][[1]]

  dplyr::tibble(
    field_name = sapply(query_type$fields, function(x) x$name),
    description = sapply(query_type$fields, function(x) x$description %||% ""),
    args_count = sapply(query_type$fields, function(x) length(x$args)),
    return_type = sapply(query_type$fields, function(x) {
      type_name(x$type)
    })
  ) |>
    dplyr::arrange(field_name)
}

#' Explore available mutations in the Meetup GraphQL API
#'
#' This function retrieves the mutation operations available in the Meetup
#' GraphQL API. Mutations are operations that modify data on the server (create,
#' update, delete).
#'
#' @template schema
#' @return A tibble with details about each mutation, including:
#'   \describe{
#'     \item{field_name}{Name of the mutation}
#'     \item{description}{Human-readable description}
#'     \item{args_count}{Number of arguments the mutation accepts}
#'     \item{return_type}{The GraphQL type returned after mutation}
#'   }
#'   If no mutations are available, returns a tibble with a message.
#'
#' @examples
#' \dontrun{
#' # List all available mutations
#' mutations <- meetupr_schema_mutations()
#'
#' # Check if mutations are supported
#' if (nrow(mutations) > 0 && !"message" %in% names(mutations)) {
#'   print(mutations$field_name)
#' }
#' }
#'
#' @export
meetupr_schema_mutations <- function(schema = meetupr_schema()) {
  if (is.null(schema$mutationType)) {
    return(dplyr::tibble(message = "No mutations available"))
  }

  mutation_type_name <- schema$mutationType$name
  mutation_type <- schema$types[sapply(schema$types, function(x) {
    x$name == mutation_type_name
  })][[1]]

  dplyr::tibble(
    field_name = sapply(mutation_type$fields, function(x) x$name),
    description = sapply(mutation_type$fields, function(x) {
      x$description %||% ""
    }),
    args_count = sapply(mutation_type$fields, function(x) length(x$args)),
    return_type = sapply(mutation_type$fields, function(x) type_name(x$type))
  ) |>
    dplyr::arrange(field_name)
}

#' Search for types in the Meetup GraphQL API schema
#'
#' This function searches across all types in the schema by name or description.
#' Useful for discovering what data structures are
#' available (e.g., Event, Group, Venue, Member).
#'
#' @param pattern A string pattern to search for in type names and descriptions.
#'   The search is case-insensitive.
#' @template schema
#' @return A tibble with details about matching types:
#'   \describe{
#'     \item{type_name}{Name of the type}
#'     \item{kind}{GraphQL kind (OBJECT, ENUM, INTERFACE, etc.)}
#'     \item{description}{Human-readable description}
#'     \item{field_count}{Number of fields in the type}
#'   }
#'
#' @examples
#' \dontrun{
#' # Find all event-related types
#' meetupr_schema_search("event")
#'
#' # Find location-related types
#' meetupr_schema_search("location")
#' }
#'
#' @export
meetupr_schema_search <- function(pattern, schema = meetupr_schema()) {
  matching_types <- schema$types[
    sapply(schema$types, function(x) {
      grepl(pattern, x$name, ignore.case = TRUE) ||
        grepl(pattern, x$description %||% "", ignore.case = TRUE)
    })
  ]

  dplyr::tibble(
    type_name = sapply(matching_types, function(x) x$name),
    kind = sapply(matching_types, function(x) x$kind),
    description = sapply(matching_types, function(x) x$description %||% ""),
    field_count = sapply(matching_types, function(x) {
      length(x$fields %||% list())
    })
  )
}

#' Get fields for a specific type in the Meetup GraphQL API schema
#'
#' This function retrieves detailed information about
#' all fields available on a
#' specific GraphQL type. Use this to discover what
#' data you can query from types
#' like Event, Group, or Member.
#'
#' @param type_name The name of the type for which to retrieve fields (e.g.,
#'   "Event", "Group", "Member").
#' @template schema
#' @param ... Additional arguments passed to `grepl()` for type name matching
#'   (e.g., `ignore.case = TRUE`).
#' @return A tibble with details about the fields:
#'   \describe{
#'     \item{field_name}{Name of the field}
#'     \item{description}{Human-readable description}
#'     \item{type}{GraphQL type of the field}
#'     \item{deprecated}{Logical indicating if field is deprecated}
#'   }
#'   If the type is not found, throws an error. If multiple types match, returns
#'   a tibble of matching type names. If the type has no fields, returns a
#'   message.
#'
#' @examples
#' \dontrun{
#' # Get all fields on the Event type
#' event_fields <- meetupr_schema_type("Event")
#'
#' # Find deprecated fields
#' event_fields |>
#'   dplyr::filter(deprecated)
#'
#' # Pass cached schema to avoid repeated introspection
#' schema <- meetupr_schema()
#' group_fields <- meetupr_schema_type("Group", schema = schema)
#' venue_fields <- meetupr_schema_type("Venue", schema = schema)
#' }
#'
#' @export
meetupr_schema_type <- function(type_name, schema = meetupr_schema(), ...) {
  matching <- schema$types[
    sapply(schema$types, function(x) {
      grepl(type_name, x$name, ...)
    })
  ]

  if (length(matching) == 0) {
    cli::cli_abort("Type not found: {.val {type_name}}")
  }

  if (length(matching) > 1) {
    cli::cli_alert_info(
      "Multiple types match {.val {type_name}}. Showing matches:"
    )
    return(
      dplyr::tibble(
        type_name = sapply(matching, function(x) x$name),
        kind = sapply(matching, function(x) x$kind)
      )
    )
  }

  matching <- matching[[1]]

  if (is.null(matching$fields)) {
    return(
      dplyr::tibble(
        message = paste("Type", type_name, "has no fields")
      )
    )
  }

  dplyr::tibble(
    field_name = sapply(matching$fields, function(x) x$name),
    description = sapply(matching$fields, function(x) x$description %||% ""),
    type = sapply(matching$fields, function(x) type_name(x$type)),
    deprecated = sapply(matching$fields, function(x) x$isDeprecated %||% FALSE)
  )
}

#' Get the name of a GraphQL type, handling nested types
#' @param type A GraphQL type object
#' @return The name of the type as a string
#' @keywords internal
#' @noRd
type_name <- function(type) {
  if (is.null(type$kind)) {
    return(type$name)
  }
  if (type$kind == "NON_NULL" || type$kind == "LIST") {
    return(type_name(type$ofType))
  }
  type$name
}
