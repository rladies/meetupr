# There is funnyness in how many items are queried.
# If single event has query size 80, Data Viz DC gets 121.
# If query size is 100, the total size is 119
# The result size is consistent, but it is not an off-by-one error.
# IDK. Punting for now, but it should be addressed
# ```r
# x <- gql_events(urlname = "Data-Visualization-DC", firstPast =  80, queryUnified = FALSE, queryUpcoming = FALSE)
# y <- gql_events(urlname = "Data-Visualization-DC", firstPast = 100, queryUnified = FALSE, queryUpcoming = FALSE)
# testthat::expect_equal(x %in% y, rep(TRUE, length(x))) # NOT TRUE!!!
# testthat::expect_equal(y %in% x, rep(TRUE, length(y))) # TRUE
# ```


capture_str <- function(x) {
  paste0(
    utils::capture.output(utils::str(x)),
    collapse = "\n"
  )
}

graphql_file <- function(.file, ..., .extra_graphql = NULL) {
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

  graphql_query(.query = glued_query, ...)
}
graphql_query <- function(.query, ...) {
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
        "Authorization" = paste0("Bearer ", meetup_token()$auth_token$credentials$access_token)
      )
    )
  })

  if (!is.null(response$errors)) {
    stop("Meetup GraphQL API returned errors.\n", capture_str(response$errors))
  }
  response
}

graphql_query_generator <- function(
  file,
  cursor_fn,
  extract_fn,
  combiner_fn = append,
  finalizer_fn = data_to_tbl,
  total_fn,
  pb_format = "[:bar] :current/:total :eta"
) {
  force(file)
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
      graphql_res <- graphql_file(file, ..., !!!cursors)
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
  extract_fn = function(x) {
    x$data$healthCheck
  },
  finalizer_fn = unlist,
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
#   }
# )

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

    events <- add_locations(
      events,
      get_city = function(event) event$venue$city,
      get_lat = function(event) event$venue$lat,
      get_lon = function(event) event$venue$lon
    )
    events
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
  extract_fn = function(x) {
    groups <- lapply(x$data$keywordSearch$edges, function(item) {
      item$node$result
    })
    groups <- add_locations(groups)
    groups
  },
  total_fn = function(x) {
    x$data$keywordSearch$count
    Inf
  },
  pb_format = "- :current/?? :elapsed :spin"
)

# If this function returns empty results, then it is being rate limited
# I don't know how we should approach this.
# A single query can _touch_ 500 points...
# > The API currently allows you to have 500 points in your queries every 60 seconds.

# Using a hash map of information. If the hash already exists, the query is removed
known_locations_env <- new.env(parent = emptyenv())
set_known_location <- function(hash, info) {
  if (length(info) > 1) {
    known_locations_env[[hash]] <- info
  }
}
get_known_location <- function(hash) {
  known_locations_env[[hash]]
}
has_known_location <- function(hash) {
  exists(hash, envir = known_locations_env)
}


add_locations <- function(
  groups,
  get_city = function(group) group$city,
  get_lat = function(group) group$latitude,
  get_lon = function(group) group$longitude
) {

  # Add information to calculate once...
  groups <- lapply(groups, function(group) {
    city <- get_city(group)
    lat <- get_lat(group)
    lon <- get_lon(group)
    name <- paste0(
      # `aliases` can not start with a number. ...So start with `m`!
      "m",
      rlang::hash(list(
        get_city(group),
        get_lat(group),
        get_lon(group)
      ))
    )
    group[[".hash_info"]] <- list(
      name = name,
      city = city,
      lat = lat,
      lon = lon
    )
    group
  })
  # Find the unique set of location informations
  location_txt <- unique(unlist(lapply(groups, function(group) {
    group_info <- group[[".hash_info"]]
    # Quit early if we already have this location
    if (has_known_location(group_info$name)) return(NULL)
    # Quit early if we cant look up the location
    if (is.null(group_info$lat) || is.null(group_info$lon)) {
      return(NULL)
    }
    txt <- "
    << name >>:findLocation(
      << if (nchar(city) > 0) paste0('query: \"', city, '\"') else '' >>
      lat: << lat >>
      lon: << lon >>
    ) {
      city
      localized_country_name
      name_string
    }"
    glue::glue_data(
      group_info,
      txt,
      .open = "<<", .close = ">>", .trim = FALSE
    )
  })))

  query <- paste0(
    "query { ",
    paste0(location_txt, collapse = "\n"), "\n",
    "}"
  )
  cat(query, "\n", sep = "")

  results <- graphql_query(query)$data
  # Set location information for caching
  Map(names(results), results, f = set_known_location)

  # Add the localized country name if the data exists
  # Return the the updated groups
  lapply(
    groups,
    function(group, locations) {
      hash <- group[[".hash_info"]]$name
      group_city <- group[[".hash_info"]]$city
      locations <- get_known_location(hash)
      # remove temp hash information
      group[[".hash_info"]] <- NULL

      for (location in locations) {
        if (group_city == location$city) {
          group$localized_country_name <- location$localized_country_name
          group$name_string <- location$name_string
          return(group)
        }
      }
      # No city match at this point
      if (length(locations) == 0) {
        group$localized_country_name <- NA
        group$name_string <- NA
      } else {
        # Use first match
        first_location <- locations[[1]]
        group$localized_country_name <- first_location$localized_country_name
        group$name_string <- first_location$name_string
      }
      return(group)
    }
  )
}


data_to_tbl <- function(data) {
  dplyr::bind_rows(
    lapply(data, function(data_item) {
      rlist::list.flatten(data_item)
    })
  )
}



if (FALSE) {
  x <- gql_health_check()

  x <- gql_events(urlname = "Data-Visualization-DC")
  x <- gql_events(urlname = "R-Users")

  x <- gql_events(urlname = "Data-Science-DC")

  x <- gql_events(urlname = "Data-Science-DC", .extra_graphql = "host { name }")

  x <- graphql_file("location", lat = 10.54, lon = -66.93)

  x <- find_groups2(topic_category_id = 546, query = "R-Ladies")
}
