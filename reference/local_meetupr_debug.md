# Temporarily enable debug mode

Sets the level of verbosity for
[`httr2::local_verbosity()`](https://httr2.r-lib.org/reference/with_verbosity.html),
and the MEETUPR_DEBUG environment variable. Can help debug issues with
API requests.

## Usage

``` r
local_meetupr_debug(verbosity = 0, env = rlang::caller_env())
```

## Arguments

- verbosity:

  How much debug information to show. 0 = off, 1 = basic, 2 = verbose, 3
  = very verbose

- env:

  The environment in which to set the variable.

## Value

The old debug value (invisibly)

## Examples

``` r
if (FALSE) { # \dontrun{
local_meetupr_debug(2)

# Turn off debug mode
local_meetupr_debug(0)
} # }
```
