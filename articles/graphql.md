# Custom Meetup Queries

``` r

library(meetupr)
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
library(purrr)
```

## Overview

This vignette is for advanced users who want to go beyond the standard
wrapper functions provided by meetupr. The Meetup API uses GraphQL, a
query language that lets you specify exactly what data you need. While
meetupr provides convenient wrapper functions like
[`get_group_events()`](http://rladies.org/meetupr/reference/get_group_events.md)
and [`get_event()`](http://rladies.org/meetupr/reference/get_event.md),
there are times when you need more control over your queries.

GraphQL gives you three main advantages:

1.  **Precise field selection**: Request only the data you need,
    reducing response size and network traffic  
2.  **Nested data fetching**: Get related data in a single request
    instead of making multiple API calls  
3.  **Access to new features**: Use API capabilities before they’re
    wrapped in convenience functions

## When to Use Custom Queries

You should consider writing custom GraphQL queries when:

- The wrapper functions don’t provide fields you need (e.g.,
  high-resolution event photos, detailed host information)  
- You need complex filtering or field combinations not supported by
  function parameters  
- You’re working with new API features that haven’t been wrapped yet  
- You need to optimize performance by fetching exactly the fields
  required for your analysis

For most common tasks, the wrapper functions in the main vignette are
sufficient and easier to use. This vignette assumes you’re comfortable
with R and want to leverage GraphQL’s full flexibility.

## Using extra_graphql in Wrapper Functions

The simplest way to customize queries is through the `extra_graphql`
parameter available in most wrapper functions. This parameter lets you
inject additional GraphQL fields into the query template without writing
the entire query from scratch.

The `extra_graphql` parameter accepts a string containing GraphQL field
specifications. These fields are inserted at a predefined location in
the query template (marked by `<< extra_graphql >>` in the `.graphql`
template files).

Here’s an example fetching high-resolution event photos, which aren’t
included in the default
[`get_group_events()`](http://rladies.org/meetupr/reference/get_group_events.md)
response:

``` r

# Define additional fields to fetch
extra_fields <- "
    featuredEventPhoto {
      highResUrl
      id
    }
  "

# Add them to the standard query
events <- get_group_events(
  "rladies-lagos",
  extra_graphql = extra_fields,
  max_results = 5
)

# Now we have photo URLs in the result
events |>
  select(title, date_time, featured_event_photo_high_res_url) |>
  head()
#> # A tibble: 5 × 3
#>   title                                         date_time featured_event_photo…¹
#>   <chr>                                         <chr>     <chr>                 
#> 1 satRday Lagos +  The Launch of RLadies Lagos. 2019-09-… NA                    
#> 2 Data Mining using  R                          2019-12-… NA                    
#> 3 Getting started with animated data in R       2020-02-… https://secure.meetup…
#> 4 Data Network Analysis : What to know.         2022-03-… https://secure.meetup…
#> 5 R Ladies Panel                                2022-05-… https://secure.meetup…
#> # ℹ abbreviated name: ¹​featured_event_photo_high_res_url
```

Notice how the nested `featuredEventPhoto` fields are automatically
flattened into columns with underscores
(`featured_event_photo_high_res_url`). This is meetupr’s convention for
handling nested GraphQL structures.

### Working with Nested Data

GraphQL responses often contain nested objects. The `extra_graphql`
parameter works particularly well when you need to fetch related data
like venues or host information:

``` r

# Fetch detailed venue information
venue_fields <- "
    venues {
      id
      name
      address
      city
      lat
      lon
    }
    group {
      name
      urlname
    }
  "

events_with_venues <- get_group_events(
  "rladies-lagos",
  extra_graphql = venue_fields,
  max_results = 5
)

# Nested columns are prefixed automatically
names(events_with_venues)
#>  [1] "id"                       "title"                   
#>  [3] "event_url"                "created_time"            
#>  [5] "status"                   "date_time"               
#>  [7] "duration"                 "description"             
#>  [9] "group_id"                 "group_name"              
#> [11] "group_urlname"            "venues_id"               
#> [13] "venues_name"              "venues_address"          
#> [15] "venues_city"              "venues_state"            
#> [17] "venues_postal_code"       "venues_country"          
#> [19] "venues_lat"               "venues_lon"              
#> [21] "venues_venue_type"        "rsvps_count"             
#> [23] "featured_event_photo_url"

# Access venue data alongside event data
events_with_venues |>
  select(title, venues_name, venues_city, group_name) |>
  head()
#> # A tibble: 5 × 4
#>   title                                       venues_name venues_city group_name
#>   <chr>                                       <chr>       <chr>       <chr>     
#> 1 satRday Lagos +  The Launch of RLadies Lag… Civil Engi… "Lagos"     R-Ladies …
#> 2 Data Mining using  R                        Sweets And… "Lagos"     R-Ladies …
#> 3 Getting started with animated data in R     Sweets And… "Lagos"     R-Ladies …
#> 4 Data Network Analysis : What to know.       Online eve… ""          R-Ladies …
#> 5 R Ladies Panel                              Online eve… ""          R-Ladies …
```

The naming convention follows a consistent pattern: nested fields are
joined with underscores, making them easy to select and filter in your
data analysis pipelines.

### Handling One-to-Many Relationships

When a field can have multiple values (like an event with venues), you
can control how meetupr handles this using the `handle_multiples`
parameter:

``` r

events_list <- get_group_events(
  "rladies-lagos",
  extra_graphql = "
    featuredEventPhoto {
      highResUrl
    }
  ",
  handle_multiples = "list",
  max_results = 3
)
events_list
#> # A tibble: 3 × 24
#>   id        title   event_url created_time status date_time duration description
#>   <chr>     <chr>   <chr>     <chr>        <chr>  <chr>     <chr>    <chr>      
#> 1 264156061 satRda… https://… 2019-08-20T… PAST   2019-09-… PT7H     "satRday-L…
#> 2 266757265 Data M… https://… 2019-11-26T… PAST   2019-12-… PT7H     "Hi there …
#> 3 267804814 Gettin… https://… 2020-01-10T… PAST   2020-02-… PT7H     "Hi there …
#> # ℹ 16 more variables: group_id <chr>, group_name <chr>, group_urlname <chr>,
#> #   venues_id <chr>, venues_name <chr>, venues_address <chr>,
#> #   venues_city <chr>, venues_state <chr>, venues_postal_code <chr>,
#> #   venues_country <chr>, venues_lat <dbl>, venues_lon <dbl>,
#> #   venues_venue_type <chr>, rsvps_count <int>, featured_event_photo_url <chr>,
#> #   featured_event_photo_high_res_url <chr>
```

This approach preserves the one-to-many relationship structure.
Alternatively, setting `handle_multiples = "first"` would keep only the
first of the lists.

## Custom Queries from Scratch

For complete control, you can write full GraphQL queries using
[`meetupr_query()`](http://rladies.org/meetupr/reference/meetupr_query.md).
This is useful when wrapper functions don’t exist for the data you need,
or when you’re constructing complex queries with multiple nested levels.

GraphQL queries follow a structured syntax. At the top level, you define
a query operation with a name and any variables it accepts. Variables
are prefixed with `$` and must have type annotations (like `String!` for
a required string).

Here’s a custom query fetching detailed group information:

``` r

custom_query <- "
  query GetGroupWithDetails($urlname: String!) {
    groupByUrlname(urlname: $urlname) {
      id
      name
      description
      city
      country
      timezone

      memberships {
        totalCount
      }
    }
  }"
```

This query demonstrates several GraphQL concepts:

- `query GetGroupWithDetails`: Names the query operation (useful for
  debugging)  
- `($urlname: String!)`: Declares a required string variable  
- `groupByUrlname(urlname: $urlname)`: Passes the variable to the API
  field  
- Nested fields like `memberships { totalCount }`: Fetch related data in
  one request

### Executing Custom Queries

The
[`meetupr_query()`](http://rladies.org/meetupr/reference/meetupr_query.md)
function executes your custom GraphQL and handles variable substitution.
You pass variables as additional named arguments:

``` r

# Execute for different groups using the same query
lagos <- meetupr_query(
  custom_query,
  urlname = "rladies-lagos"
)

ottawa <- meetupr_query(
  custom_query,
  urlname = "rladies-ottawa"
)

# Access nested data using $ notation
lagos$data$groupByUrlname$name
#> [1] "R-Ladies Lagos"
ottawa$data$groupByUrlname$memberships$totalCount
#> [1] 1107
```

The response structure mirrors the query structure. Data is nested under
`data`, then under each field name you queried. This differs from
wrapper functions that return flat tibbles, giving you more control but
requiring you to navigate the nested structure yourself.

## Understanding Pagination

The Meetup API uses cursor-based pagination for large result sets.
meetupr handles this automatically in wrapper functions, but
understanding pagination helps when writing custom queries.

### Automatic Pagination in Wrapper Functions

When you request more results than fit in one API response, meetupr
makes multiple requests for you:

``` r

# Request 50 events - may require multiple API calls
many_events <- get_group_events(
  "rladies-san-francisco",
  max_results = 50
)

cli::cli_alert_info("Fetched {nrow(many_events)} events")
#> ℹ Fetched 50 events
```

Behind the scenes, meetupr checks the `pageInfo` object in each
response. If `hasNextPage` is true, it makes another request using the
`endCursor` value, continuing until it has fetched the requested number
of results or there are no more pages.

## Understanding the Template System

meetupr’s wrapper functions use a template-based system that combines
reusable GraphQL query files with R function logic. Understanding this
system helps when deciding whether to use a wrapper function or write a
custom query.

Query templates live in the `inst/graphql/` directory of the package.
Each template is a `.graphql` file containing a parameterized query. For
example, `group_events.graphql` might look like:

``` graphql
query GetGroupEvents($urlname: String!, $status: EventStatus, $first: Int, $after: String) {
  groupByUrlname(urlname: $urlname) {
    pastEvents(input: {first: $first, after: $after}) {
      pageInfo { hasNextPage endCursor }
      edges {
        node {
          id
          title
          dateTime
          << extra_graphql >>
        }
      }
    }
  }
}
```

The `<< extra_graphql >>` marker is where content from the
`extra_graphql` parameter gets injected. When you call
`get_group_events("rladies-lagos", extra_graphql = "going")`, meetupr:

1.  Loads the template file from `inst/graphql/group_events.graphql`  
2.  Uses
    [`glue::glue_data()`](https://glue.tidyverse.org/reference/glue.html)
    to replace `<< extra_graphql >>` with `"going"`  
3.  Interpolates other variables like `$urlname` and `$first`  
4.  Executes the resulting query  
5.  Extracts data from the configured response path (e.g.,
    `data.groupByUrlname.pastEvents.edges`)  
6.  Flattens nested structures into a tibble

### Creating Custom Extractors

For advanced use cases, you can create your own `meetupr_template`
objects that define how to process responses:

``` r

# Define a custom template with extraction logic
template <- meetupr_template(
  template = "my_custom_query.graphql",
  edges_path = "data.group.customField.edges",
  page_info_path = "data.group.customField.pageInfo",
  process_data = function(data) {
    # Custom processing for your specific data structure
    dplyr::tibble(
      id = purrr::map_chr(data, "node.id"),
      name = purrr::map_chr(data, "node.name"),
      custom_field = purrr::map_dbl(data, "node.customField")
    )
  }
)

# Execute the template
result <- execute(template, urlname = "rladies-lagos")
```

This pattern is used internally by all wrapper functions. The
`process_data` function determines how the raw GraphQL response gets
transformed into the tibble structure users see. You can customize this
to handle complex nested structures or perform computations during
extraction.

For more details on API exploration, see the [API Introspection
vignette](http://rladies.org/meetupr/articles/introspection.md).

## Error Handling

When a query fails, enable debug mode to see the exact GraphQL being
sent:

``` r

# Enable debug mode
Sys.setenv(MEETUPR_DEBUG = "1")

# Run a query - you'll see the full request/response
result <- meetupr_query(
  "
  query {
    groupByUrlname(urlname: \"rladies-san-francisco\") {
      id
      name
    }
  }"
)
#> ℹ Using jwt token authentication

# Disable debug mode
Sys.setenv(MEETUPR_DEBUG = "0")
```

Debug output shows:

- The complete GraphQL query after variable interpolation  
- Variable values being passed  
- The raw JSON response from the API

This is invaluable when queries fail in unexpected ways or you’re unsure
why you’re not getting expected data.

## Performance Best Practices

GraphQL’s flexibility comes with responsibility. Following these
practices ensures your queries are efficient and respect API rate
limits.

### Request Only Needed Fields

GraphQL’s main advantage is precise field selection. Use it:

``` r

# Avoid: Fetches everything including large nested objects
heavy_query <- "
  query {
    groupByUrlname(urlname: \"rladies-sf\") {
      pastEvents(input: {first: 100}) {
        edges {
          node {
            id
            title
            description
            featuredEventPhoto {
              baseUrl
              highResUrl
            }
            venue { ... }
          }
        }
      }
    }
  }"

# Better: Only fields you'll actually use
optimized_query <- "
  query {
    groupByUrlname(urlname: \"rladies-sf\") {
      pastEvents(input: {first: 100}) {
        edges {
          node {
            id
            title
            dateTime
            going
          }
        }
      }
    }
  }"
```

The heavy query might return megabytes of data when you only need a few
fields. This wastes bandwidth, slows down processing, and counts against
rate limits. Always start with minimal fields and add more only when
needed.

### Batch Queries Efficiently

When you need data from multiple groups, consider whether you can get it
in fewer API calls:

``` r

groups <- c("rladies-nyc", "rladies-sf", "rladies-london")

# Inefficient: One API call per group
results <- purrr::map(
  groups,
  ~ {
    get_group(.x)
  }
) # 3 API calls

# More efficient: Use Pro endpoint if you have access
# Gets all groups in a network with one call
results <- get_pro_groups("rladies") # 1 API call
```

meetupr automatically throttles requests to stay under the Meetup API’s
rate limit (500 requests per 60 seconds). However, reducing the number
of requests is still beneficial for performance and being a good API
citizen.

### Monitor Rate Limits

For large batch operations, add explicit delays to stay well under rate
limits:

``` r

# Process many groups with deliberate pacing
many_groups <- c("group1", "group2", "group3", "...")

results <- purrr::map(
  many_groups,
  ~ {
    result <- get_group_events(.x)
    Sys.sleep(0.5) # 500ms between calls = max 120 requests/minute
    result
  }
)
```

While meetupr’s automatic throttling prevents you from exceeding limits,
being conservative helps if you’re running multiple scripts
simultaneously or sharing API credentials across processes.

### Use Pagination Wisely

Don’t request more data than you need:

``` r

# If you only need recent events, limit the request
recent_events <- get_group_events(
  "rladies-sf",
  max_results = 10 # Not 1000
)

# For large datasets, consider filtering on the API side
# (when wrapper functions support it)
past_year <- get_group_events(
  "rladies-sf",
  date_after = "2024-01-01T00:00:00Z"
)
```

Fetching fewer results means fewer API calls (for paginated data) and
faster processing. GraphQL supports filtering arguments on many fields;
check the schema introspection to discover what’s available for your use
case.

## Additional Resources

### Official Documentation

- **GraphQL General Guide**: <https://www.meetup.com/graphql/>  
- **GraphQL Learning**: <https://graphql.org/learn/>

### Related Vignettes

- **Getting Started**: See
  [`vignette("meetupr")`](http://rladies.org/meetupr/articles/meetupr.md)
  for basic usage  
- **API Introspection**: See
  [`vignette("introspection")`](http://rladies.org/meetupr/articles/introspection.md)
  for exploring the schema  
- **Authentication**: See
  [`vignette("meetupr")`](http://rladies.org/meetupr/articles/meetupr.md)
  for OAuth and CI setup

### Getting Help

When asking for help with custom queries:

1.  **Include the GraphQL query** you’re trying to execute  
2.  **Enable debug mode** (`Sys.setenv(MEETUPR_DEBUG = "1")`) and
    include output  
3.  **Show the error message** or unexpected result  
4.  **Describe what data you’re trying to get** and why wrapper
    functions don’t work

This context helps maintainers and community members provide targeted
assistance.
