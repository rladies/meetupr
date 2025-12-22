# Execute GraphQL query

This function executes a GraphQL query with the provided variables. It
validates the variables, constructs the request, and handles any errors
returned by the GraphQL API.

## Usage

``` r
meetupr_query(graphql, ..., .envir = parent.frame())
```

## Arguments

- graphql:

  GraphQL query string

- ...:

  Variables to pass to query

- .envir:

  Environment for error handling

## Value

The response from the GraphQL API as a list.

## Examples

``` r
if (FALSE) { # \dontrun{
query <- "
query GetUser($id: ID!) {
 user(id: $id) {
  id
 name
}
}"
meetupr_query(graphql = query, id = "12345")
} # }
```
