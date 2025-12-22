# Introspect the Meetup GraphQL API schema

This function performs an introspection query on the Meetup GraphQL API
to retrieve the full schema details, including available query types,
mutation types, and type definitions.

## Usage

``` r
meetupr_schema(asis = FALSE)
```

## Arguments

- asis:

  Logical; if TRUE, returns the raw response from the API as JSON. If
  FALSE (default), returns the parsed schema object.

## Value

If `asis` is FALSE (default), the parsed schema object with nested lists
containing query types, mutation types, and type definitions. If `asis`
is TRUE, a JSON string representation of the schema.

## Examples

``` r
# Get the full schema
schema <- meetupr_schema()

# Explore what's available
names(schema)
#> [1] "queryType"        "mutationType"     "subscriptionType" "types"           

# Get as JSON for external tools
schema_json <- meetupr_schema(asis = TRUE)
```
