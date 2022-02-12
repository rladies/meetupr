# # TODO, once v3 api is no longer supported
# * Remove most / all of `internals.R`
# * Remove duplicated method names
# * Make method names consistent: Ex `find_groups()` -> `get_groups()`
# * Bump version to `0.3.0`
# -----------------------------------
# # Query size matters?!?
# There is funniness in how many items are queried.
# If single event has query size 80, Data Viz DC gets 121.
# If query size is 100, the total size is 119
# The result size is consistent, but it is not an off-by-one error.
# IDK. Punting for now, but it should be addressed
# ```r
# x <- gql_events(urlname = "Data-Visualization-DC", firstPast =  80, queryUnified = FALSE, queryUpcoming = FALSE)
# y <- gql_events(urlname = "Data-Visualization-DC", firstPast = 100, queryUnified = FALSE, queryUpcoming = FALSE)
# testthat::expect_equal(x$id %in% y$id, rep(TRUE, nrow(x))) # NOT TRUE!!!
# testthat::expect_equal(y$id %in% x$id, rep(TRUE, nrow(y))) # TRUE
# ```
# -----------------------------------
# # Adding a new graphql method
# 0. Add a new `graphql` file to query the `meetup.com` graphql API
#   * Links
#     * Learn about graphql: https://graphql.org/learn/
#     * `meetup.com`'s schema: https://www.meetup.com/api/schema
#     * `meetup.com`'s playground: https://www.meetup.com/api/playground
#   * Suggestions:
#     * For any queries that involve a cursor, add a `cursor` and `first` argument
#     * Just because the query shape is the same, does not mean you can use a fragment on two different types of objects
#     * Only query what you need. Use `<< extra_graphql >>` where appropriate to allow extra fields to be queried
# 1. Create a function using `graphql_query_generator()`
#   * See `gql_find_groups()` for a concise example
#   * See help docs for `graphql_query_generator()` below for more details
#   * Keep the data in a simple "list of items" structure as much as possible
# 2. Add a wrapper function to call your generated function. Ex: `find_groups2()`
#   * Here, transform the data from a "list of items" to a data.frame (or appropriate structure)
# -----------------------------------







# Capture all output of `str()` and return it as a single string
capture_str <- function(x) {
  paste0(
    utils::capture.output(utils::str(x)),
    collapse = "\n"
  )
}

# Turns a list of consistently shaped lists into a single tibble
# This also turns nested lists like `ITEM$venue$address` into a single value of `venue.address`
data_to_tbl <- function(data) {
  dplyr::bind_rows(
    lapply(data, function(data_item) {
      rlist::list.flatten(data_item)
    })
  )
}





#' Query the Meetup GraphQL API given a file and variables
#'
#' Constructs a single text string and passes the string and `...` variables to [`graphql_query`]
#' @param .file File name (without extension) in `./inst/graphql`
#' @param ... Variables to pass to the query
#' @param .extra_graphql Extra GraphQL code to insert into the query. The location is different within each GraphQL file.
#' @param .token See [`meetup_token()`] for details.
#' @noRd
graphql_file <- function(.file, ..., .extra_graphql = NULL, .token = meetup_token()) {
  # inspiration: https://github.com/tidyverse/tidyversedashboard/blob/2c6cf9ebe8da938c35f6e9fc184c3b30265f1082/R/utils.R#L2
  file <- system.file(file.path("graphql", paste0(.file, ".graphql")), package = "meetupr")
  query <- readChar(file, file.info(file)$size)
  .extra_graphql <- .extra_graphql %||% ""
  if (!is.null(.extra_graphql)) {
    if (length(.extra_graphql) != 1 && is.character(.extra_graphql)) {
      stop("`.extra_graphql` must be a single string")
    }
  }
  glued_query <- glue::glue_data(list(extra_graphql = .extra_graphql), query, .open = "<<", .close = ">>", trim = FALSE)

  graphql_query(.query = glued_query, ..., .token = .token)
}

#' Query the Meetup GraphQL API
#'
#' @param .query GraphQL query string
#' @param ... Variables to pass to the query
#' @param .token See [`meetup_token()`] for details.
#' @return A list like structure directly from the API. Typically you'll want to use `$data`.
#'   If any `$errors`` are found, an error will be thrown.
#' @noRd
graphql_query <- function(.query, ..., .token = meetup_token()) {
  variables <- purrr::compact(rlang::list2(...))

  if (length(variables) > 0 && !rlang::is_named(variables)) {
    stop("Stop all GraphQL variables must be named. Variables:\n", capture_str(variables), call. = FALSE)
  }

  ## From meetup.com website example:
  # query='query { self { id name } }'

  # curl -X POST https://api.meetup.com/gql \
  #   -H 'Authorization: Bearer {YOUR_TOKEN}' \
  #   -H 'Content-Type: application/json' \
  #   -d @- <<EOF
  #     {
  #       "query": "query { self { id name } }",
  #       "variables": "{\"foo\": \"bar\"}"
  #     }
  # EOF

  suppressMessages({
    # Stop printing of message: `No encoding supplied: defaulting to UTF-8.`
    # Message comes deep within gh:::gh_process_response via `content(response, as = "text")` should have `encode = "UTF-8"` param
    response <- gh::gh(
      "POST https://api.meetup.com/gql",
      query = .query,
      variables = variables,
      .accept = "application/json",
      .send_headers = c(
        # 'Authorization: Bearer {YOUR_TOKEN}'
        "Authorization" = paste0(
          .token$auth_token$credentials$token_type,
          " ",
          .token$auth_token$credentials$access_token
        )
      )
    )
  })

  if (!is.null(response$errors)) {
    stop("Meetup GraphQL API returned errors.\n", capture_str(response$errors))
  }
  response
}

#' Generic method to fetch, extract, and combine results.
#'
#' Will spawn a progress bar if many results are to be fetched. If there is only a single set of results, no progress bar will be displayed.
#'
#' @param file File to send to `graphql_file(.file=)`
#' @param cursor_fn Function that takes the result of `graphql_file(.file=)`. This method should return a list of arguments (typically cursor related) to pass to the next API request. If the `cursor_fn` returns `NULL`, no more results will be fetched.
#' @param total_fn Function that takes in a result and returns a total number of results. This number is used for the progress bar.
#' @param pb_format Format to supply to a new [`progress::progress_bar`].
#' @param extract_fn Function that takes the result of `graphql_file(.file=)` and returns a list of results to be combined via `combiner_fn`. Typically, the returned result is a list of information for each record.
#' @param combiner_fn Function to merge two results of `extract_fn` together. The initial result is set to `NULL`.
#' @param finalizer_fn Function that will run over the final result of `combiner_fn`. Typically, this is where the list of lists is turned into a tibble.
#' @return A function that wraps around `graphql_file(.file = file, ..., .extra_graphql = .extra_graphql, .token = .token)` and passes through `...`, `.extra_graphql`, and `.token`.
#' @noRd
graphql_query_generator <- function(
  file,
  cursor_fn,
  total_fn,
  extract_fn,
  combiner_fn = append,
  finalizer_fn = data_to_tbl,
  pb_format = "[:bar] :current/:total :eta"
) {
  force(file)
  force(cursor_fn)
  force(extract_fn)
  force(combiner_fn)
  force(finalizer_fn)
  force(total_fn)
  force(pb_format)

  function(
    ...,
    .extra_graphql = NULL,
    .token = meetup_token()
  ) {
    ret <- NULL
    cursors <- list()
    pb <- NULL
    while (TRUE) {
      graphql_res <- graphql_file(.file = file, ..., !!!cursors, .extra_graphql = .extra_graphql, .token = .token)
      cursors <- cursor_fn(graphql_res)
      graphql_content <- extract_fn(graphql_res)
      if (is.null(pb)) {
        pb <- progress::progress_bar$new(
          total = total_fn(graphql_res),
          format = paste0(file, " ", pb_format)
        )
        on.exit({
          # Make sure the pb is closed when exiting
          pb$terminate()
        }, add = TRUE)
      }

      ret <- combiner_fn(ret, graphql_content)
      pb$tick(length(graphql_content))

      # If there is no more data to traverse, quit
      if (length(cursors) == 0) break
    }

    finalizer_fn(ret)
  }
}


gql_health_check <- graphql_query_generator(
  "health_check",
  cursor_fn = function(response) {
    NULL
  },
  total_fn = function(x) {
    1
  },
  extract_fn = function(x) {
    x$data$healthCheck
  },
  finalizer_fn = unlist,
  pb_format = ":current/:total"
)

gql_events <- graphql_query_generator(
  "find_events",
  cursor_fn = function(x) {
    ret <- list()
    hasACursor <- FALSE
    groupByUrlname <- x$data$groupByUrlname
    add_cursor_info <- function(page_name, arg_name) {
      info <- groupByUrlname[[page_name]]$pageInfo

      if (!is.null(info) && info$hasNextPage) {
        hasACursor <<- TRUE
        ret[[paste0("cursor", arg_name)]] <<- info$endCursor
      } else {
        ret[[paste0("query", arg_name)]] <<- FALSE
      }
    }
    add_cursor_info("unifiedEvents", "Unified")
    add_cursor_info("upcomingEvents", "Upcoming")
    add_cursor_info("pastEvents", "Past")
    add_cursor_info("draftEvents", "Draft")

    if (hasACursor) {
      ret
    } else {
      NULL
    }
  },
  total_fn = function(x) {
    groupByUrlname <- x$data$groupByUrlname
    sum(c(
      groupByUrlname$unifiedEvents$count,
      groupByUrlname$upcomingEvents$count,
      groupByUrlname$pastEvents$count,
      groupByUrlname$draftEvents$count
    ))
  },
  extract_fn = function(x) {
    groupByUrlname <- x$data$groupByUrlname
    get_nodes <- function(edge_name, event_type) {
      edges <- groupByUrlname[[edge_name]]$edges
      lapply(edges, `[[`, "node")
    }

    events <- unlist(
      list(
        get_nodes("unifiedEvents", "unified"),
        get_nodes("upcomingEvents", "upcoming"),
        get_nodes("pastEvents", "past"),
        get_nodes("draftEvents", "draft")
      ),
      recursive = FALSE
    )

    events <- add_country_name(events, get_country = function(event) event$venue$country)
    events
  },
  pb_format = "[:bar] :current/:total :eta"
)

gql_find_groups <- graphql_query_generator(
  "find_groups",
  cursor_fn = function(x) {
    pageInfo <- x$data$keywordSearch$pageInfo
    if (pageInfo$hasNextPage) {
      list(cursor = pageInfo$endCursor)
    } else {
      NULL
    }
  },
  total_fn = function(x) {
    x$data$keywordSearch$count
    Inf
  },
  extract_fn = function(x) {
    groups <- lapply(x$data$keywordSearch$edges, function(item) {
      item$node$result
    })
    groups <- add_country_name(groups, get_country = function(group) group$country)
    groups
  },
  pb_format = "- :current/?? :elapsed :spin"
)


gql_get_event_attendees <- graphql_query_generator(
  "find_attendees",
  cursor_fn = function(x) {
    pageInfo <- x$data$event$tickets$pageInfo
    if (pageInfo$hasNextPage) {
      list(cursor = pageInfo$endCursor)
    } else {
      NULL
    }
  },
  total_fn = function(x) {
    x$data$event$tickets$count
    Inf
  },
  extract_fn = function(x) {
    attendees <- lapply(x$data$event$tickets$edges, function(item) {
      item$node$user
    })
    attendees
  },
  pb_format = "- :current/?? :elapsed :spin"
)
# Cache the country code to name conversion as the conversion is consistent
country_code_mem <- local({
  cache <- list()
  function(country) {
    val <- cache[[country]]
    if (!is.null(val)) return(val)

    val <-
      countrycode::countrycode(
        country,
        "iso2c",
        "country.name"
      )
    cache[[country]] <<- val
    val
  }
})

# Adds the `country_name` field given the two letter country value found from `get_country`
add_country_name <- function(
  groups,
  get_country = function(group) group$country
) {
  lapply(groups, function(group) {
    country <- get_country(group)
    group$country_name <-
      if (length(country) == 0 || nchar(country) == 0) {
        ""
      } else {
        country_code_mem(country)
      }
    group
  })
}




# Manual checking
if (FALSE) {
  x <- gql_health_check(); utils::str(x)

  x <- get_events2(urlname = "Data-Visualization-DC"); utils::str(x)
  x <- get_events2(urlname = "R-Users"); utils::str(x)

  x <- get_events2(urlname = "Data-Science-DC"); utils::str(x)

  x <- get_events2(urlname = "Data-Science-DC", .extra_graphql = "host { name }"); utils::str(x)

  x <- graphql_file("location", lat = 10.54, lon = -66.93); utils::str(x)

  x <- find_groups2(topic_category_id = 546, query = "R-Ladies"); utils::str(x)
}
