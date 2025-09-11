---
output: github_document
---

<!-- README.md is generated from README.Rmd. Please edit the Rmd file -->



# meetupr <img src="man/figures/logo.png" align="right" alt="Zane Dax @StarTrek_Lt" width="138.5" />

<small>Logo by Zane Dax [@StarTrek_Lt](https://mobile.twitter.com/startrek_lt)</small>

<!-- badges: start -->
[![R-CMD-check](https://github.com/rladies/meetupr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/rladies/meetupr/actions)
[![Codecov test coverage](https://codecov.io/gh/rladies/meetupr/branch/master/graph/badge.svg)](https://codecov.io/gh/rladies/meetupr?branch=master)
<!-- badges: end -->

R interface to the Meetup GraphQL API

## Installation

To install the development version from GitHub:

```r
# install.packages("remotes")
remotes::install_github("rladies/meetupr")
```

## Authentication

meetupr uses OAuth 2.0 for authentication with the Meetup API. 
The first time you run a meetupr function, you'll be prompted to authorize the application in your browser. 
Your token will be cached for future sessions.

## Usage

### Get group events


``` r
library(meetupr)

events <- get_events("rladies-san-francisco", "past")
#> Fetching data ⠙ Page 1, 65 items
```

### Get group members


``` r
members <- get_members("rladies-san-francisco")
head(members)
#> # A tibble: 6 × 8
#>   id       name   member_url photo_link
#>   <chr>    <chr>  <chr>      <chr>     
#> 1 14534094 Gabri… https://w… https://s…
#> 2 64513952 T. Li… https://w… https://s…
#> 3 25902562 Maggi… https://w… https://s…
#> 4 2412055  Marse… https://w… https://s…
#> 5 11509157 Jessi… https://w… https://s…
#> 6 2920822  Benay… https://w… https://s…
#> # ℹ 4 more variables: status <chr>,
#> #   role <chr>, joined <dttm>,
#> #   most_recent_visit <dttm>
```

### Search for groups


``` r
groups <- find_groups("R-Ladies")
#> Fetching data ⠙ Page 1, 200 items
dplyr::arrange(groups, desc(founded_date))
#> # A tibble: 200 × 17
#>    id       name    urlname city  state
#>    <chr>    <chr>   <chr>   <chr> <chr>
#>  1 38175678 Ladies… ladies… Harr… "17" 
#>  2 38170580 F.R.I.… jackso… Jack… "FL" 
#>  3 38168499 Partie… partie… Detr… "MI" 
#>  4 38157654 【🌞MELL… mellow… Osaka ""   
#>  5 38152954 All th… all-th… Ista… ""   
#>  6 38147539 Reel L… reel-l… Berl… ""   
#>  7 38141791 50+ Fo… 50-for… New … "NY" 
#>  8 38140422 Love, … love-l… Mani… ""   
#>  9 38139448 MFR Fe… le-pre… Paris ""   
#> 10 38130794 LesBIa… lesbia… Tarr… ""   
#> # ℹ 190 more rows
#> # ℹ 12 more variables: country <chr>,
#> #   latitude <dbl>, longitude <dbl>,
#> #   membership_count <int>,
#> #   founded_date <dttm>,
#> #   timezone <chr>, join_mode <chr>,
#> #   who <chr>, is_private <lgl>, …
```

### Pro network access

For Meetup Pro networks:


``` r
# Get all groups in a pro network
pro_groups <- get_pro_groups("rladies")
#> Fetching data ⠙ Page 1, 247 items

# Get events from a pro network
pro_events <- get_pro_events("rladies", status = "upcoming")
```

## Available Functions

- `get_events()` - Get events for a group
- `get_members()` - Get members of a group  
- `get_event_attendees()` - Get attendees for an event
- `get_event_rsvps()` - Get RSVPs for an event
- `find_groups()` - Search for groups by text
- `get_pro_groups()` - Get groups in a Pro network
- `get_pro_events()` - Get events from a Pro network
- `get_self()` - Get information about the authenticated user

## Contributing

We welcome contributions! 
Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Code of Conduct

Please note that this project is released with a [Contributor Code of Conduct](https://github.com/rladies/.github/blob/master/CODE_OF_CONDUCT.md).
By contributing to this project, you agree to abide by its terms.
