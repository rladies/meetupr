# Find groups using text-based search

Search for groups on Meetup using a text query. This function allows you
to find groups that match your search criteria.

## Usage

``` r
find_groups(
  query,
  topic_id = NULL,
  category_id = NULL,
  max_results = 200,
  handle_multiples = "list",
  extra_graphql = NULL,
  asis = FALSE,
  ...
)
```

## Arguments

- query:

  Character string to search for groups

- topic_id:

  Numeric ID of a topic to filter groups by

- category_id:

  Numeric ID of a category to filter groups by

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

  other named variables for graphql query. options are:

  - lat: Float

  - lon: Float

  - radius: Float

  - categoryId: ID

  - topicCategoryId: ID

## Value

A tibble with group information

## Examples

``` r
groups <- find_groups("R-Ladies")
groups
#> # A tibble: 200 × 13
#>    id       name       urlname city  state country   lat   lon memberships_count
#>    <chr>    <chr>      <chr>   <chr> <chr> <chr>   <dbl> <dbl>             <int>
#>  1 38267718 R User Gr… r-nvsu  Mani… ""    ph       14.6 121.                  3
#>  2 24820200 R-Ladies … rladie… Méxi… ""    mx       19.4 -99.1              2942
#>  3 20378903 R-Ladies … rladie… Melb… ""    au      -37.8 145.               2708
#>  4 32767673 R-Ladies … rladie… Pach… ""    mx       20.1 -98.8                40
#>  5 33041212 R-Ladies … rladie… al-K… ""    sd       15.6  32.5               112
#>  6 35897820 R-Ladies … rladie… Gabo… ""    bw      -24.6  25.9              1131
#>  7 28706674 R-Ladies … rladie… Nite… ""    br      -22.9 -43.1              1276
#>  8 33361775 R-Ladies … rladie… Ha N… ""    vn       21.0 106.                124
#>  9 27456719 R-Ladies … rladie… São … ""    br      -23.5 -46.6              1818
#> 10 28441250 R-Ladies … rladie… San … ""    ar      -41.1 -71.3               588
#> # ℹ 190 more rows
#> # ℹ 4 more variables: founded_date <dttm>, timezone <chr>, join_mode <chr>,
#> #   is_private <lgl>
```
