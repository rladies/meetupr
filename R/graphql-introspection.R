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
#' \dontrun{
#' # Get the schema details as a tidy tibble
#' schema <- meetup_introspect()
#' View(schema)
#' }
#' @export
meetup_introspect <- function(asis = FALSE) {
  result <- execute_from_template("introspection")
  result <- result$data$`__schema`
  if (asis) {
    return(jsonlite::toJSON(result, auto_unbox = TRUE, pretty = TRUE))
  }
  result
}

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

type_name <- function(type) {
  if (type$kind == "NON_NULL" || type$kind == "LIST") {
    return(type_name(type$ofType))
  }
  type$name
}

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

get_type_fields <- function(schema, type_name) {
  type_info <- schema$types[[type_name]]
  if (is.null(type_info)) {
    matching <- schema$types[
      sapply(schema$types, function(x) {
        grepl(type_name, x$name, ignore.case = TRUE)
      })
    ]
    if (length(matching) == 0) {
      cli::cli_abort("Type not found: {.val { type_name}}")
    }
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
