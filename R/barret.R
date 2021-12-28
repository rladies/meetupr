# Get events
# Find groups

if (FALSE) {
  urlname <- "rladies-san-francisco"
  events <- get_events(urlname, "past")
  dplyr::arrange(events, desc(created))

  groups <- find_groups(topic_id = 1513883)
  dplyr::arrange(groups, desc(created))


  events
  c("upcoming", "cancelled", "draft", "past", "proposed", "suggested")
  # cancelled: events have to be prost processed. There is a `cancelled` field in the Event object
  # upcoming: upcomingEvents field
  # draft: draftEvents field
  # past: pastEvents field
  # proposed: unknown
  # suggested: unknown

  # anything that returns a pageInfo object needs an `input` object to help with pagination.
  # To get around this, maybe we do a prep query to get the counts and then loop through the requests 20 items at a time

  # extra fields:
  # `fields = list(host = list("email", "name"))`
  # graphql code = "host { email, name }"
  # produces column names generated from nested names: host_email, host_name, top_level_sub_level_name_fieldValue

  # Things to implement:
  # * return a list of events; If pagination exists, find all events



  # proposed: does not exist

}

gql_api_prefix <- function() {
  Sys.getenv("MEETUP_API_URL", "https://api.meetup.com/gql")
}

get_events2 <- "
query ($eventId: ID) {
  event(id: $eventId) {
    title
    description
    dateTime
  }
}
"
get_events_gql <- '
query {
  groupByUrlname(urlname: "Data-Visualization-DC") {
    id
    unifiedEvents {
      pageInfo {
        hasNextPage
        hasPreviousPage
        startCursor
        endCursor
      }
      count
      edges {
        cursor
        node {
          id
          title
          eventUrl
          dateTime
        }
      }
    }
    upcomingEvents(input: {last:10}) {
      pageInfo {
        hasNextPage
        hasPreviousPage
        startCursor
        endCursor
      }
      count
      edges {
        cursor
        node {
          id
          title
          eventUrl
          dateTime
        }
      }
    }
    pastEvents(input: {last:120}) {
      pageInfo {
        hasNextPage
        hasPreviousPage
        startCursor
        endCursor
      }
      count
      edges {
        cursor
        node {
          id
          title
          eventUrl
          dateTime
        }
      }
    }
  }
}
'

single_event_gql <- '
query {
  groupByUrlname(urlname: "Data-Visualization-DC") {
    id
    unifiedEvents {
      pageInfo {
        hasNextPage
        hasPreviousPage
        startCursor
        endCursor
      }
      count
      edges {
        cursor
        node {
          id
          title
          eventUrl
          dateTime
        }
      }
    }
    upcomingEvents(input: {last:10}) {
      pageInfo {
        hasNextPage
        hasPreviousPage
        startCursor
        endCursor
      }
      count
      edges {
        cursor
        node {
          id
          title
          eventUrl
          dateTime
        }
      }
    }
    pastEvents(input: {last:120}) {
      pageInfo {
        hasNextPage
        hasPreviousPage
        startCursor
        endCursor
      }
      count
      edges {
        cursor
        node {
          id
          title
          eventUrl
          dateTime
        }
      }
    }
  }
}
'

get_single_event_gql_info <- '
query {
  groupByUrlname(urlname: "Data-Visualization-DC") {
    id
    pastEvents(input: {last:10}) {
      pageInfo {
        hasNextPage
        hasPreviousPage
        startCursor
        endCursor
      }
      count
      edges {
        cursor
        node {
          id
          title
          eventUrl
          dateTime
          createdAt
          going
          waiting
          venue {
            name
            address
            city
            state
            postalCode
            country
          }
          description
          eventUrl
          $ExtraFields
        }
      }
    }
  }
}
'

    # pastEvents {
    #   pageInfo {
    #     hasNextPage
    #     hasPreviousPage
    #     startCursor
    #     endCursor
    #   }
    #   count
    #   edges {
    #     cursor
    #     node {
    #       id
    #       title
    #       eventUrl
    #     }
    #   }
    # }
# parameters = list(urlname = "rladies-san-francisco")
# Event col names
    # id
    # name
    # created
    # status
    # time
    # local_date
    # duration
    # local_time
    # waitlist_count
    # yes_rsvp_count
    # venue_id
    # venue_name
    # venue_lat
    # venue_lon
    # venue_address_1
    # venue_city
    # venue_state
    # venue_zip
    # venue_country
    # description
    # link
    # resource

# Group col names
    # id
    # name
    # urlname
    # status
    # lat
    # lon
    # city
    # state
    # country
    # created
    # members
    # timezone
    # join_mode
    # visibility
    # who
    # location
    # organizer_id
    # organizer_name
    # category_id
    # category_name
    # resource

gql_call <- function(
  gql_txt,
  event_status = NULL,
  offset = 0,
  verbose = NULL,
  ...
) {
  api_path <- "gql"
  # list of parameters
  parameters <- list(
    status = event_status, # you need to add the status
    # otherwise it will get only the upcoming event
    offset = offset,
    ...                    # other parameters
  )

  req <- httr::POST(
    url = gql_api_prefix(),          # the host
    path = api_path,                  # path to append
    body = list(
      query = gql_txt,
      variables = parameters
    ),
    encode = "json",
    config = meetup_token()
  )

  if (req$status_code == 400) {
    utils::str(req)
    utils::str(httr::content(req, "parsed"))
    browser()
    stop("Status code is 400")
    # stop("HTTP 400 Bad Request error encountered for: ",
    #      api_path,".\n As of June 30, 2020, this may be ",
    #             "because a presumed bug with the Meetup API ",
    #             "causes this error for a future event. Please ",
    #             "confirm the event has ended.",
    #      call. = FALSE)
  }

  httr::stop_for_status(req)

  headers <- httr::headers(req)

  assign(
    "meetupr_rate",
    c(headers$`x-ratelimit-limit`, headers$`x-ratelimit-reset`),
    envir = .meetupr_env
    )

  reslist <- httr::content(req, "parsed")

  if (length(reslist) == 0) {
    if(verbose) {
      cat("Zero records match your filter. Nothing to return.\n")
    }
    return(NULL)
  }

  return(list(result = reslist, headers = req$headers))
}




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
