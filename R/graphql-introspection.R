#' Introspect the Meetup GraphQL API
#'
#' This function performs an introspection query on the Meetup GraphQL API to
#' retrieve the schema details, including available query types, mutation types,
#' and type definitions.
#' @param asis Logical; if TRUE, returns the raw response from the API. If FALSE
#' (default), returns a tidy tibble with schema details.
#' @return If `asis` is FALSE (default), a tibble with schema details including
#' query types, mutation types, and type definitions. If `asis` is TRUE, the raw
#' response from the API.
#' @examples
#' \dontshow{
#' vcr::insert_example_cassette("meetup_introspect", package = "meetupr")
#' meetupr:::mock_if_no_auth()
#' }
#' meetup_introspect()
#' \dontshow{
#' vcr::eject_cassette()
#' }
#' @export
meetup_introspect <- function(asis = FALSE) {
  result <- execute_from_template("introspection")
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
#' This function retrieves and displays the available query fields in the Meetup
#' GraphQL API schema.
#' @param schema The schema object obtained from `meetup_introspect()`. If NULL,
#' the function will call `meetup_introspect()` to get the schema.
#' @return A tibble with details about each query field, including field name,
#' description, argument count, and return type.
#' @examples
#' \dontrun{
#' explore_query_fields()
#' }
#' @export
explore_query_fields <- function(schema = meetup_introspect()) {
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
#' This function retrieves and displays the available mutations in the Meetup
#' GraphQL API schema.
#' @param schema The schema object obtained from `meetup_introspect()`. If NULL,
#' the function will call `meetup_introspect()` to get the schema.
#' @return A tibble with details about each mutation, including mutation name,
#' description, argument count, and return type. If no mutations are
#' available,
#' @examples
#' \dontrun{
#' explore_mutations()
#' }
#' @export
explore_mutations <- function(schema = meetup_introspect()) {
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
#' This function allows you to search for types in the Meetup GraphQL API schema
#' by name or description.
#' @param schema The schema object obtained from `meetup_introspect()`. If NULL,
#' the function will call `meetup_introspect()` to get the schema.
#' @param pattern A string pattern to search for in type names and descriptions.
#' The search is case-insensitive.
#' @return A tibble with details about matching types, including type name, kind,
#' description, and field count.
#' @examples
#' \dontrun{
#' search_types(pattern = "event")
#' }
#' @export
search_types <- function(schema = meetup_introspect(), pattern) {
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
#' This function retrieves the fields of a specified type from the Meetup GraphQL
#' API schema.
#' @param schema The schema object obtained from `meetup_introspect()`. If NULL,
#' the function will call `meetup_introspect()` to get the schema.
#' @param type_name The name of the type for which to retrieve fields.
#' @return A tibble with details about the fields of the specified type, including
#' field name, description, type, and deprecation status. If the type is not found
#' or has no fields, an appropriate message is returned.
#' @examples
#' \dontrun{
#' get_type_fields(type_name = "Event")
#' }
#' @export
get_type_fields <- function(schema, type_name) {
  type_info <- schema$types[[type_name]]

  matching <- schema$types[
    sapply(schema$types, function(x) {
      grepl(type_name, x$name, ignore.case = TRUE)
    })
  ]

  if (length(matching) == 0) {
    cli::cli_abort("Type not found: {.val { type_name}}")
  }

  if (length(matching) > 1) {
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
