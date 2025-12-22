# Get fields for a specific type in the Meetup GraphQL API schema

This function retrieves detailed information about all fields available
on a specific GraphQL type. Use this to discover what data you can query
from types like Event, Group, or Member.

## Usage

``` r
meetupr_schema_type(type_name, schema = meetupr_schema(), ...)
```

## Arguments

- type_name:

  The name of the type for which to retrieve fields (e.g., "Event",
  "Group", "Member").

- schema:

  The schema object obtained from
  [`meetupr_schema()`](http://rladies.org/meetupr/reference/meetupr_schema.md).

- ...:

  Additional arguments passed to
  [`grepl()`](https://rdrr.io/r/base/grep.html) for type name matching
  (e.g., `ignore.case = TRUE`).

## Value

A tibble with details about the fields:

- field_name:

  Name of the field

- description:

  Human-readable description

- type:

  GraphQL type of the field

- deprecated:

  Logical indicating if field is deprecated

If the type is not found, throws an error. If multiple types match,
returns a tibble of matching type names. If the type has no fields,
returns a message.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get all fields on the Event type
event_fields <- meetupr_schema_type("Event")

# Find deprecated fields
event_fields |>
  dplyr::filter(deprecated)

# Pass cached schema to avoid repeated introspection
schema <- meetupr_schema()
group_fields <- meetupr_schema_type("Group", schema = schema)
venue_fields <- meetupr_schema_type("Venue", schema = schema)
} # }
```
