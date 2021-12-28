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
    capture.output(str(x)),
    collapse = "\n"
  )
}


graphql_query <- function(graphql_file, ...) {
  # inspiration: https://github.com/tidyverse/tidyversedashboard/blob/2c6cf9ebe8da938c35f6e9fc184c3b30265f1082/R/utils.R#L2
  file <- system.file(file.path("graphql", paste0(graphql_file, ".graphql")), package = "meetupr")
  query <- readChar(file, file.info(file)$size)
  variables <- purrr::compact(rlang::list2(...))
  if (!rlang::is_named(variables)) {
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
  total_fn,
  combiner_fn
) {
  force(graphql_file)
  force(cursor_fn)
  force(extract_fn)
  force(total_fn)
  force(combiner_fn)

  function(
    ...
  ) {
    ret <- NULL
    cursors <- list()
    pb <- NULL
    while (TRUE) {
      # browser()
      graphql_res <- graphql_query(graphql_file, ..., !!!cursors)
      cursors <- cursor_fn(graphql_res)
      graphql_content <- extract_fn(graphql_res)
      if (is.null(pb)) {
        pb <- progress::progress_bar$new(
          total = total_fn(graphql_res),
          format = paste0(graphql_file, " [:bar] :current/:total :eta"),
          show_after = 0
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
  total_fn = function(x) {
    1
  },
  combiner_fn = append
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
  cursor_fn = function(response) {
    groupByUrlname <- response$data$groupByUrlname
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

    unifiedEvents <- lapply(unifiedEvents, `[[<-`, "type", "unified")
    upcomingEvents <- lapply(upcomingEvents, `[[<-`, "type", "upcoming")
    pastEvents <- lapply(pastEvents, `[[<-`, "type", "past")

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
  total_fn = function(x) {
    groupByUrlname <- x$data$groupByUrlname
    sum(c(
      groupByUrlname$unifiedEvents$count,
      groupByUrlname$upcomingEvents$count,
      groupByUrlname$pastEvents$count
    ))
  },
  combiner_fn = append
)




if (FALSE) {
  x <- gql_health_check()

  x <- gql_single_event(urlname = "Data-Visualization-DC")
  x <- gql_single_event(urlname = "R-Users")
  x <- gql_single_event(urlname = "Data-Science-DC")


}
