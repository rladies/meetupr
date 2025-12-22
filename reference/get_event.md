# Get information for a specified event

Get information for a specified event

## Usage

``` r
get_event(id, extra_graphql = NULL, asis = FALSE, ...)
```

## Arguments

- id:

  Required event ID

- extra_graphql:

  A graphql object. Extra objects to return

- asis:

  Return the raw API response as-is without processing

- ...:

  Should be empty. Used for parameter expansion

## Value

A meetupr_event object with information about the specified event

## Examples

``` r
event <- get_event(id = "103349942")
```
