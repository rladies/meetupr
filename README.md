
<!-- README.md is generated from README.Rmd. Please edit the Rmd file -->

# meetupr <img src="man/figures/logo.png" align="right" alt="Zane Dax @StarTrek_Lt" width="138.5" />

<small>Logo by Zane Dax
[@StarTrek_Lt](https://mobile.twitter.com/startrek_lt)</small>

<!-- badges: start -->

[![R-CMD-check](https://github.com/rladies/meetupr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/rladies/meetupr/actions)
[![Codecov test
coverage](https://codecov.io/gh/rladies/meetupr/branch/master/graph/badge.svg)](https://codecov.io/gh/rladies/meetupr?branch=master)
[![R-CMD-check](https://github.com/drmowinckels/meetupr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/drmowinckels/meetupr/actions/workflows/R-CMD-check.yaml)
[![R-CMD-check](https://github.com/rladies/meetupr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/rladies/meetupr/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/drmowinckels/meetupr/graph/badge.svg)](https://app.codecov.io/gh/drmowinckels/meetupr)
[![Codecov test
coverage](https://codecov.io/gh/rladies/meetupr/graph/badge.svg)](https://app.codecov.io/gh/rladies/meetupr)
<!-- badges: end -->

R interface to the Meetup GraphQL API

## Installation

To install the development version from GitHub:

``` r
# install.packages("remotes")
remotes::install_github("rladies/meetupr")
```

## Authentication

meetupr uses OAuth 2.0 for authentication with the Meetup API. The first
time you run a meetupr function, you’ll be prompted to authorize the
application in your browser. Your token will be cached for future
sessions.

## Usage

### Get group events

``` r
library(meetupr)

events <- get_events("rladies-san-francisco", "past")
#> Fetching data ⠙ Page 1, 65 items
```

### Get group members

``` r
members <- get_group_members("rladies-san-francisco")
head(members)
#> # A tibble: 6 × 8
#>   id       name           member_url photo_link status role  joined             
#>   <chr>    <chr>          <chr>      <chr>      <chr>  <chr> <dttm>             
#> 1 14534094 Gabriela de Q… https://w… https://s… LEADER COOR… 2012-10-01 12:28:21
#> 2 64513952 T. Libman      https://w… https://s… ACTIVE MEMB… 2012-10-01 14:04:47
#> 3 25902562 Maggie L.      https://w… https://s… ACTIVE MEMB… 2012-10-04 02:31:20
#> 4 2412055  Marsee Henon   https://w… https://s… ACTIVE MEMB… 2012-10-04 13:09:06
#> 5 11509157 Jessica Monto… https://w… https://s… ACTIVE MEMB… 2012-10-04 13:10:53
#> 6 2920822  Benay Dara-Ab… https://w… https://s… ACTIVE MEMB… 2012-10-04 13:12:18
#> # ℹ 1 more variable: most_recent_visit <dttm>
```

### Search for groups

``` r
groups <- find_groups("R-Ladies")
#> Fetching data ⠙ Page 1, 200 items
dplyr::arrange(groups, desc(founded_date))
#> # A tibble: 200 × 17
#>    id      name  urlname city  state country latitude longitude membership_count
#>    <chr>   <chr> <chr>   <chr> <chr> <chr>      <dbl>     <dbl>            <int>
#>  1 381756… Ladi… ladies… Harr… "17"  gb          51.6     -0.33                2
#>  2 381705… F.R.… jackso… Jack… "FL"  us          30.3    -81.8                29
#>  3 381684… Part… partie… Detr… "MI"  us          42.4    -83.1                 2
#>  4 381576… 【🌞ME… mellow… Osaka ""    jp          34.7    136.                 49
#>  5 381529… All … all-th… Ista… ""    tr          41.0     29.0                 5
#>  6 381475… Reel… reel-l… Berl… ""    de          52.5     13.4                49
#>  7 381417… 50+ … 50-for… New … "NY"  us          40.8    -74.0                17
#>  8 381404… Love… love-l… Mani… ""    ph          14.6    121.                 63
#>  9 381394… MFR … le-pre… Paris ""    fr          48.9      2.34               54
#> 10 381307… LesB… lesbia… Tarr… ""    es          41.1      1.24               34
#> # ℹ 190 more rows
#> # ℹ 8 more variables: founded_date <dttm>, timezone <chr>, join_mode <chr>,
#> #   who <chr>, is_private <lgl>, category_id <chr>, category_name <chr>,
#> #   membership_status <chr>
```

### Pro network access

For Meetup Pro networks:

``` r
# Get all groups in a pro network
pro_groups <- get_pro_groups("rladies")

# Get events from a pro network
pro_events <- get_pro_events("rladies", status = "upcoming")
```

## Available Functions

- `get_events()` - Get events for a group
- `get_group_members()` - Get members of a group  
- `get_event_attendees()` - Get attendees for an event
- `get_event_rsvps()` - Get RSVPs for an event
- `find_groups()` - Search for groups by text
- `get_pro_groups()` - Get groups in a Pro network
- `get_pro_events()` - Get events from a Pro network
- `get_self()` - Get information about the authenticated user

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md)
for guidelines.

## Code of Conduct

Please note that this project is released with a [Contributor Code of
Conduct](https://github.com/rladies/.github/blob/master/CODE_OF_CONDUCT.md).
By contributing to this project, you agree to abide by its terms.
