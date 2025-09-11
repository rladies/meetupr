validate_extra_graphql <- function(.extra_graphql) {
  .extra_graphql <- .extra_graphql %||% ""

  if (
    !is.null(.extra_graphql) &&
      (length(.extra_graphql) != 1 || !is.character(.extra_graphql))
  ) {
    cli::cli_abort("{.code .extra_graphql} must be a single string")
  }

  .extra_graphql
}

get_execute_from_template_path <- function(.file) {
  file_path <- system.file(
    file.path("graphql", paste0(.file, ".graphql")),
    package = "meetupr"
  )

  if (!file.exists(file_path)) {
    cli::cli_abort("GraphQL file not found: {.path {file_path}}")
  }

  file_path
}

read_execute_from_template <- function(file_path) {
  tryCatch(
    {
      readChar(file_path, file.info(file_path)$size)
    },
    error = function(e) {
      cli::cli_abort("Failed to read GraphQL file: {e$message}")
    }
  )
}

insert_extra_graphql <- function(query, .extra_graphql) {
  if (nzchar(.extra_graphql)) {
    glue::glue_data(
      list(extra_graphql = .extra_graphql),
      query,
      .open = "<<",
      .close = ">>",
      trim = FALSE
    )
  } else {
    gsub("<< extra_graphql >>", "", query)
  }
}
