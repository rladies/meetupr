#' Convert GraphQL response list to tibble using list_flatten + bind_rows
#' @param dlist List of GraphQL response items
#' @param handle_multiples How to handle duplicate fields: "first" (keep first
#' value), "list" (combine into list columns)
#' @return tibble with flattened structure
#' @keywords internal
#' @noRd
process_graphql_list <- function(
  dlist,
  handle_multiples = c("list", "first")
) {
  if (length(dlist) == 0) {
    return(dplyr::tibble())
  }

  handle_multiples <- match.arg(
    handle_multiples,
    c("first", "list")
  )

  handle_fun <- switch(
    handle_multiples,
    list = multiples_to_listcol,
    first = multiples_keep_first
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
multiples_to_listcol <- function(df) {
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
multiples_keep_first <- function(df) {
  column_names <- names(df)
  pattern <- "\\.{3}\\d+$"
  base_names <- unique(gsub(pattern, "", column_names))

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
  names(df) <- make.names(old_names, unique = TRUE) |>
    sapply(clean_field_name)

  df
}

#' Clean a single field name
#' @param name Field name to clean
#' @return Cleaned field name
#' @keywords internal
#' @noRd
clean_field_name <- function(name) {
  gsub("([a-z])([A-Z])", "\\1_\\2", name) |>
    gsub2("\\.", "_", ) |>
    gsub2("-+", "_") |>
    gsub2("^-|-$", "") |>
    gsub2("__+", "_") |>
    tolower() |>
    gsub2("_total_count$", "_count") |>
    gsub2("_base_url$", "_url") |>
    gsub2("_metadata_", "_") |>
    gsub2("(\\w+)_\\1(?=_|$)", "\\1", perl = TRUE)
}

#' Wrapper around gsub to allow chaining
#' @param x Input string
#' @param pattern Pattern to replace
#' @param replacement Replacement string
#' @param ... Additional gsub parameters
#' @return Modified string
#' @keywords internal
#' @noRd
gsub2 <- function(x, pattern, replacement, ...) {
  gsub(pattern, replacement, x, ...)
}
