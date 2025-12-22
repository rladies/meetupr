# Explore available query fields in the Meetup GraphQL API

This function retrieves the root-level query fields available in the
Meetup GraphQL API. These are the entry points for data fetching (e.g.,
`groupByUrlname`, `event`, etc.).

## Usage

``` r
meetupr_schema_queries(schema = meetupr_schema())
```

## Arguments

- schema:

  The schema object obtained from
  [`meetupr_schema()`](http://rladies.org/meetupr/reference/meetupr_schema.md).

## Value

A tibble with details about each query field, including:

- field_name:

  Name of the query field

- description:

  Human-readable description of the field

- args_count:

  Number of arguments the field accepts

- return_type:

  The GraphQL type returned by this field

## Examples

``` r
if (FALSE) { # \dontrun{
# List all available queries
queries <- meetupr_schema_queries()

# Find group-related queries
queries |>
  dplyr::filter(grepl("group", field_name, ignore.case = TRUE))
} # }
```
