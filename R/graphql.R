# There is funnyness in how many items are queried.
# If single event has query size 80, Data Viz DC gets 121.
# If query size is 100, the total size is 119
# The result size is consistent, but it is not an off-by-one error.
# IDK. Punting for now, but it should be addressed
# ```r
# x <- gql_single_event(urlname = "Data-Visualization-DC", firstPast =  80, queryUnified = FALSE, queryUpcoming = FALSE)
# y <- gql_single_event(urlname = "Data-Visualization-DC", firstPast = 100, queryUnified = FALSE, queryUpcoming = FALSE)
# testthat::expect_equal(x %in% y, rep(TRUE, length(x))) # NOT TRUE!!!
# testthat::expect_equal(y %in% x, rep(TRUE, length(y))) # TRUE
# ```


capture_str <- function(x) {
  paste0(
    utils::capture.output(utils::str(x)),
    collapse = "\n"
  )
}

graphql_file <- function(graphql_file, ..., extra_graphql = NULL) {
  # inspiration: https://github.com/tidyverse/tidyversedashboard/blob/2c6cf9ebe8da938c35f6e9fc184c3b30265f1082/R/utils.R#L2
  file <- system.file(file.path("graphql", paste0(graphql_file, ".graphql")), package = "meetupr")
  query <- readChar(file, file.info(file)$size)
  extra_graphql <- extra_graphql %||% ""
  if (!is.null(extra_graphql)) {
    if (length(extra_graphql) != 1 && is.character(extra_graphql)) {
      stop("extra_graphql must be a single string")
    }
  }
  query <- glue::glue_data(list(extra_graphql = extra_graphql), query, .open = "<<", .close = ">>", trim = FALSE)

  graphql_query(query, ...)
}
graphql_query <- function(query, ...) {
  variables <- purrr::compact(rlang::list2(...))
  if (length(variables) > 0 && !rlang::is_named(variables)) {
    stop("Stop all GraphQL variables must be named. Variables:\n", capture_str(variables), call. = FALSE)
  }
  # str(variables)

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
      query = query,
      variables = variables,
      .accept = "application/json",
      .send_headers = c(
        "Authorization" = paste0("Bearer ", meetup_token()$auth_token$credentials$access_token)
      )
    )
  })

  if (!is.null(response$errors)) {
    stop("Meetup GraphQL API returned errors.\n",capture_str(response$errors))
  }
  response
}

graphql_query_generator <- function(
  graphql_file,
  cursor_fn,
  extract_fn,
  combiner_fn,
  total_fn,
  pb_format = "[:bar] :current/:total :eta"
) {
  force(graphql_file)
  force(cursor_fn)
  force(extract_fn)
  force(total_fn)
  force(combiner_fn)
  force(pb_format)

  function(
    ...
  ) {
    ret <- NULL
    cursors <- list()
    pb <- NULL
    while (TRUE) {
      # browser()
      graphql_res <- graphql_file(graphql_file, ..., !!!cursors)
      cursors <- cursor_fn(graphql_res)
      graphql_content <- extract_fn(graphql_res)
      if (is.null(pb)) {
        pb <- progress::progress_bar$new(
          total = total_fn(graphql_res),
          format = paste0(graphql_file, " ", pb_format)
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

    ret
  }
}


gql_health_check <- graphql_query_generator(
  "health_check",
  cursor_fn = function(response) {
    NULL
  },
  extract_fn = function(x) {
    x$data$healthCheck
  },
  combiner_fn = append,
  total_fn = function(x) {
    1
  },
  pb_format = ":current/:total"
)

# gql_single_event <- graphql_query_generator(
#   "single_event",
#   cursor_fn = function(response) {
#     # str(response, max.level = 5)
#     pageInfo <- response$data$groupByUrlname$pastEvents$pageInfo
#     # str(pageInfo)
#     if (pageInfo$hasNextPage) {
#       list(cursor = pageInfo$endCursor)
#     } else {
#       NULL
#     }
#   },
#   extract_fn = function(x) {
#     x$data$groupByUrlname$pastEvents$edges
#   },
#   total_fn = function(x) {
#     x$data$groupByUrlname$pastEvents$count
#   },
#   combiner_fn = append
# )

gql_single_event <- graphql_query_generator(
  "single_event",
  cursor_fn = function(x) {
    groupByUrlname <- x$data$groupByUrlname
    unifiedEventsInfo <- groupByUrlname$unifiedEvents$pageInfo
    upcomingEventsInfo <- groupByUrlname$upcomingEvents$pageInfo
    pastEventsInfo <- groupByUrlname$pastEvents$pageInfo

    ret <- list()
    hasACursor <- FALSE
    add_cursor_info <- function(info, name) {
      if (!is.null(info) && info$hasNextPage) {
        hasACursor <<- TRUE
        ret[[paste0("cursor", name)]] <<- info$endCursor
      } else {
        ret[[paste0("query", name)]] <<- FALSE
      }
    }
    add_cursor_info(unifiedEventsInfo, "Unified")
    add_cursor_info(upcomingEventsInfo, "Upcoming")
    add_cursor_info(pastEventsInfo, "Past")

    if (hasACursor) {
      ret
    } else {
      NULL
    }
  },
  extract_fn = function(x) {
    # browser()
    groupByUrlname <- x$data$groupByUrlname

    unifiedEvents <- groupByUrlname$unifiedEvents$edges
    upcomingEvents <- groupByUrlname$upcomingEvents$edges
    pastEvents <- groupByUrlname$pastEvents$edges

    get_nodes <- function(x, type) {
      nodes <- lapply(x, `[[`, "node")
      lapply(nodes, function(item) {
        item$type <- type
        item
      })
    }
    unifiedEvents <- get_nodes(unifiedEvents, "unified")
    upcomingEvents <- get_nodes(upcomingEvents, "upcoming")
    pastEvents <- get_nodes(pastEvents, "past")
    # str(list(
    #   unifiedLength = length(unifiedEvents),
    #   upcomingLength = length(upcomingEvents),
    #   pastLength = length(pastEvents)
    # ))

    ret <-
      append(
        append(unifiedEvents, upcomingEvents),
        pastEvents,
      )
    ret
  },
  combiner_fn = append,
  total_fn = function(x) {
    groupByUrlname <- x$data$groupByUrlname
    sum(c(
      groupByUrlname$unifiedEvents$count,
      groupByUrlname$upcomingEvents$count,
      groupByUrlname$pastEvents$count
    ))
  },
  pb_format = "[:bar] :current/:total :eta"
)

gql_find_groups <- graphql_query_generator(
  "find_groups",
  cursor_fn = function(x) {
    pageInfo <- x$data$keywordSearch$pageInfo
    str(pageInfo)
    if (pageInfo$hasNextPage) {
      list(cursor = pageInfo$endCursor)
    } else {
      NULL
    }
  },
  combiner_fn = append,
  extract_fn = function(x) {
    lapply(x$data$keywordSearch$edges, function(item) {
      item$node$result
    })
  },
  total_fn = function(x) {
    x$data$keywordSearch$count
    Inf
  },
  pb_format = "- :current/?? :elapsed :spin"
)



if (FALSE) {
  x <- gql_health_check()

  x <- gql_single_event(urlname = "Data-Visualization-DC")
  x <- gql_single_event(urlname = "R-Users")

  x <- gql_single_event(urlname = "Data-Science-DC")

  x <- gql_single_event(urlname = "Data-Science-DC", extra_graphql = "host { name }")


}
