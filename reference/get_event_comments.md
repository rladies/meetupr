# Get the comments for a specified event

Get the comments for a specified event

## Usage

``` r
get_event_comments(id, ..., extra_graphql = NULL)
```

## Arguments

- id:

  Required event ID

- ...:

  Should be empty. Used for parameter expansion

- extra_graphql:

  A graphql object. Extra objects to return

## Value

A tibble

## Examples

``` r
if (FALSE) { # \dontrun{
comments <- get_event_comments(id = "103349942")
} # }
```
