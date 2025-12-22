# Explore available mutations in the Meetup GraphQL API

This function retrieves the mutation operations available in the Meetup
GraphQL API. Mutations are operations that modify data on the server
(create, update, delete).

## Usage

``` r
meetupr_schema_mutations(schema = meetupr_schema())
```

## Arguments

- schema:

  The schema object obtained from
  [`meetupr_schema()`](http://rladies.org/meetupr/reference/meetupr_schema.md).

## Value

A tibble with details about each mutation, including:

- field_name:

  Name of the mutation

- description:

  Human-readable description

- args_count:

  Number of arguments the mutation accepts

- return_type:

  The GraphQL type returned after mutation

If no mutations are available, returns a tibble with a message.

## Examples

``` r
if (FALSE) { # \dontrun{
# List all available mutations
mutations <- meetupr_schema_mutations()

# Check if mutations are supported
if (nrow(mutations) > 0 && !"message" %in% names(mutations)) {
  print(mutations$field_name)
}
} # }
```
