# Get the members from a meetup group

Get the members from a meetup group

## Usage

``` r
get_group_members(
  urlname,
  max_results = NULL,
  handle_multiples = "list",
  extra_graphql = NULL,
  asis = FALSE,
  ...
)
```

## Arguments

- urlname:

  Character. The name of the group as indicated in the
  <https://www.meetup.com/> url.

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

A tibble with group members

## Examples

``` r
get_group_members("rladies-lagos")
#> # A tibble: 890 × 8
#>    id        name             member_url member_photo_url status role  join_time
#>    <chr>     <chr>            <chr>      <chr>            <chr>  <chr> <chr>    
#>  1 251470805 "R-Ladies Globa… https://w… https://secure-… LEADER ORGA… 2019-08-…
#>  2 225839690 "EYITAYO ALIMI"  https://w… https://secure-… LEADER COOR… 2019-08-…
#>  3 236466773 "Adedamilola Ad… https://w… https://secure-… ACTIVE MEMB… 2019-08-…
#>  4 255806325 "Helen"          https://w… https://secure-… ACTIVE MEMB… 2019-08-…
#>  5 287781170 "Alvin"          https://w… https://secure-… ACTIVE MEMB… 2019-08-…
#>  6 266271010 "ijeoma benson"  https://w… NA               ACTIVE MEMB… 2019-08-…
#>  7 284993544 "Ochuko"         https://w… https://secure-… ACTIVE MEMB… 2019-08-…
#>  8 249638660 "Folajimi Arolo… https://w… https://secure-… ACTIVE MEMB… 2019-08-…
#>  9 287607204 "Olaniyi ayomid… https://w… NA               ACTIVE MEMB… 2019-08-…
#> 10 253986501 "Ofure Ughu"     https://w… NA               ACTIVE MEMB… 2019-08-…
#> # ℹ 880 more rows
#> # ℹ 1 more variable: last_access_time <chr>
```
