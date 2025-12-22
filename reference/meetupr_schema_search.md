# Search for types in the Meetup GraphQL API schema

This function searches across all types in the schema by name or
description. Useful for discovering what data structures are available
(e.g., Event, Group, Venue, Member).

## Usage

``` r
meetupr_schema_search(pattern, schema = meetupr_schema())
```

## Arguments

- pattern:

  A string pattern to search for in type names and descriptions. The
  search is case-insensitive.

- schema:

  The schema object obtained from
  [`meetupr_schema()`](http://rladies.org/meetupr/reference/meetupr_schema.md).

## Value

A tibble with details about matching types:

- type_name:

  Name of the type

- kind:

  GraphQL kind (OBJECT, ENUM, INTERFACE, etc.)

- description:

  Human-readable description

- field_count:

  Number of fields in the type

## Examples

``` r
if (FALSE) { # \dontrun{
# Find all event-related types
meetupr_schema_search("event")

# Find location-related types
meetupr_schema_search("location")
} # }
```
