#' Convert GraphQL response list to tibble using list_flatten + bind_rows
#' @param dlist List of GraphQL response items
#' @param handle_multiples How to handle duplicate fields: "first" (keep first
#' value), "list" (combine into list columns)
#' @return tibble with flattened structure
#' @keywords internal
#' @noRd
process_graphql_list <- function(
  dlist,
  handle_multiples = "list"
) {
  if (length(dlist) == 0) {
    return(dplyr::tibble())
  }

  handle_fun <- switch(
    handle_multiples,
    list = combine_duplicate_columns,
    first = keep_first_duplicate_columns,
    stop(
      "Invalid handle_multiples option. Use 'first' or 'list'.",
      call. = FALSE
    )
  )

  # Flatten each item completely
  lapply(dlist, function(x) {
    rlist::list.flatten(x)
  }) |>
    silent_bind_rows() |>
    handle_fun() |>
    clean_field_names()
}

silent_bind_rows <- function(...) {
  suppressMessages(dplyr::bind_rows(...))
}

#' Combine duplicate columns (those with ..1, ..2 suffixes) into list columns
#' @param df tibble with potential duplicate columns
#' @return tibble with list columns for duplicates
#' @keywords internal
#' @noRd
combine_duplicate_columns <- function(df) {
  column_names <- names(df)
  pattern <- "\\.{3}\\d+$"
  base_names <- unique(gsub(pattern, "", column_names))

  new_data <- list()

  for (base_name in base_names) {
    matching_cols <- column_names[startsWith(column_names, base_name)]

    if (length(matching_cols) == 1 && matching_cols == base_name) {
      new_data[[base_name]] <- df[[base_name]]
    } else {
      suffix_pattern <- sprintf(
        "%s(%s)?$",
        escape_regex(base_name),
        pattern
      )
      matching_cols <- matching_cols[grepl(suffix_pattern, matching_cols)]

      ordered_cols <- sort(matching_cols)
      if (base_name %in% matching_cols) {
        ordered_cols <- c(
          base_name,
          sort(matching_cols[matching_cols != base_name])
        )
      }

      list_values <- purrr::pmap(df[ordered_cols], function(...) {
        values <- unname(list(...))
        # Remove NA values
        non_na_values <- values[!is.na(values)]
        if (length(non_na_values) == 0) {
          return(list())
        } else if (length(non_na_values) == 1) {
          return(non_na_values[[1]])
        }
        non_na_values
      })

      new_data[[base_name]] <- list_values
    }
  }

  dplyr::as_tibble(new_data)
}

#' Keep only the first value for duplicate columns
#' @param df tibble with potential duplicate columns
#' @return tibble with only first values
#' @keywords internal
#' @noRd
keep_first_duplicate_columns <- function(df) {
  column_names <- names(df)
  browser()
  # Find base names (without ..1, ..2 suffixes)
  base_names <- unique(gsub("\\.\\.\\d+$", "", column_names))

  new_data <- list()

  for (base_name in base_names) {
    # Find all columns that match this base name
    matching_cols <- column_names[startsWith(column_names, base_name)]

    if (base_name %in% matching_cols) {
      # Keep the base name (no suffix)
      new_data[[base_name]] <- df[[base_name]]
    } else {
      # Take the first numbered one
      first_col <- sort(matching_cols)[1]
      new_data[[base_name]] <- df[[first_col]]
    }
  }

  dplyr::as_tibble(new_data)
}

#' Escape special regex characters
#' @param string String to escape
#' @return Escaped string
#' @keywords internal
#' @noRd
escape_regex <- function(string) {
  gsub("([.|()\\^{}+$*?]|\\[|\\])", "\\\\\\1", string)
}

#' Clean up field names from GraphQL format to R conventions
#' @param df tibble with GraphQL field names
#' @return tibble with cleaned names
#' @keywords internal
#' @noRd
clean_field_names <- function(df) {
  old_names <- names(df)
  new_names <- purrr::map_chr(old_names, clean_single_field_name)

  # Handle duplicates
  new_names <- make.names(new_names, unique = TRUE)

  # Fix make.names artifacts
  new_names <- gsub("\\.", "_", new_names)
  new_names <- gsub("_+", "_", new_names)
  new_names <- gsub("^_|_$", "", new_names)

  names(df) <- new_names
  df
}

#' Clean a single field name
#' @param name Field name to clean
#' @return Cleaned field name
#' @keywords internal
#' @noRd
clean_single_field_name <- function(name) {
  # Convert camelCase to snake_case
  name <- gsub("([a-z])([A-Z])", "\\1_\\2", name)

  # Handle common GraphQL patterns
  name <- gsub("_total_count$", "_count", name)
  name <- gsub("_base_url$", "_url", name)
  name <- gsub("member_member_", "member_", name)
  name <- gsub("group_group_", "group_", name)

  # Convert to lowercase
  tolower(name)
}
