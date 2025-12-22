# Get the RSVPs for a specified event

Get the RSVPs for a specified event

## Usage

``` r
get_event_rsvps(
  id,
  max_results = NULL,
  handle_multiples = "list",
  extra_graphql = NULL,
  asis = FALSE,
  ...
)
```

## Arguments

- id:

  Required event ID

- max_results:

  Maximum number of results to return. If set to NULL, will return all
  available results (may take a long time).

- handle_multiples:

  Character. How to handle multiple matches. One of "list" or "first",
  or "error". If "list", return a list-column with all matches. If
  "first", return only the first match.

- extra_graphql:

  A graphql object. Extra objects to return

- asis:

  Return the raw API response as-is without processing

- ...:

  Should be empty. Used for parameter expansion

## Value

A tibble with the RSVPs for the specified event

## Examples

``` r
rsvps <- get_event_rsvps(id = "103349942")
```
