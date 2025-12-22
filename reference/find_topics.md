# Find topics on Meetup

Search for topics on Meetup using a query string. This function allows
you to find topics that match your search criteria.

## Usage

``` r
find_topics(
  query,
  max_results = 200,
  handle_multiples = "list",
  extra_graphql = NULL,
  asis = FALSE,
  ...
)
```

## Arguments

- query:

  A string query to search for topics.

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

  Used for parameter expansion, must be empty.

## Value

A data frame of topics matching the search query.

## Examples

``` r
find_topics("R", max_results = 10)
#> # A tibble: 10 × 4
#>    id     name                         urlkey                       description 
#>    <chr>  <chr>                        <chr>                        <chr>       
#>  1 109937 Board Games                  board-games                  NA          
#>  2 24384  Consciousness                consciousness                Meet other …
#>  3 21137  Recreational Sports          recreational-sports          Meet other …
#>  4 35073  Business Referral Networking business-referral-networking Meet other …
#>  5 35170  Hiking                       hiking                       Meet other …
#>  6 43699  Reading                      reading                      NA          
#>  7 19285  Real Estate Investors        real-estate-investors        NA          
#>  8 73492  Real Estate Investing        real-estate-investing        NA          
#>  9 87372  Real Estate                  real-estate                  NA          
#> 10 584902 Machine Learning             machine-learning             NA          
find_topics("Data Science", max_results = 5)
#> # A tibble: 5 × 3
#>   id      name               urlkey            
#>   <chr>   <chr>              <chr>             
#> 1 1515085 Data Analytics     data-analytics    
#> 2 37381   Data Visualization data-visualization
#> 3 480642  Data               data              
#> 4 102811  Data Science       data-science      
#> 5 55324   Data Mining        data-mining       
```
