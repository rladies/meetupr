# Get information about the authenticated user

Retrieves detailed information about the currently authenticated Meetup
user, including basic profile data, account type, subscription status,
and API access permissions.

## Usage

``` r
get_self(asis = FALSE)
```

## Arguments

- asis:

  Return the raw API response as-is without processing

## Value

A list containing user information

## Examples

``` r
user <- get_self()
cat("Hello", user$name, "!")
#> Hello R-Ladies Global !
```
