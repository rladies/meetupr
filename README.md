
<!-- README.md is generated from README.Rmd. Please edit the Rmd file -->

# meetupr

[![Build
Status](https://travis-ci.org/rladies/meetupr.svg?branch=master)](https://travis-ci.org/rladies/meetupr)

R interface to the Meetup API (v3)

**Authors:** [Gabriela de Queiroz](http://gdequeiroz.github.io/), [Erin
LeDell](http://www.stat.berkeley.edu/~ledell/), [Olga
Mierzwa-Sulima](https://github.com/olgamie), [Lucy D’Agostino
McGowan](http://www.lucymcgowan.com), [Claudia
Vitolo](https://github.com/cvitolo)<br/>

**License:**
[MIT](https://opensource.org/licenses/MIT)

## Installation

To install the development version from GitHub:

``` r
# install.packages("devtools")
devtools::install_github("rladies/meetupr")
```

A released version will be on CRAN soon.

## Usage

To use this package, you will first need to get your meetup API key. To
do so, go to this link: <https://secure.meetup.com/meetup_api/key/>

Once you have your key, save it as an environment variable for the
current session by running the following:

``` r
Sys.setenv(MEETUP_KEY = "PASTE YOUR MEETUP KEY HERE")
```

Alternatively, you can set it permanently with the help of
`usethis::edit_r_environ()` by adding the line to your `.Renviron`:

    MEETUP_KEY=PASTE YOUR MEETUP KEY HERE

If you don’t want to save it here, you can input it in each function
using the `api_key` parameter (just be sure not to send any documents
with your key to GitHub 🙊).

We currently have the following functions:

  - `get_members()`
  - `get_boards()`
  - `get_events()`  
  - `get_event_attendees()`  
  - `get_event_comments()`
  - `get_event_rsvps()`
  - `find_groups()`

Each will output a tibble with information extracted into from the API
as well as a `list-col` named `*_resource` with all API output. For
example, the following code will get all upcoming events for the
[R-Ladies San Francisco](https://meetup.com/rladies-san-francisco)
meetup.

``` r
library(meetupr)

urlname <- "rladies-san-francisco"
events <- get_events(urlname, "past")
#> Downloading 47 record(s)...
dplyr::arrange(events, desc(created))
#> # A tibble: 47 x 21
#>    id    name  created             status time                local_date
#>    <chr> <chr> <dttm>              <chr>  <dttm>              <date>    
#>  1 2543… ggpl… 2018-09-04 19:45:15 past   2018-09-20 03:00:00 2018-09-19
#>  2 2533… Rsam… 2018-08-01 01:10:28 past   2018-08-16 03:00:00 2018-08-15
#>  3 2522… Crea… 2018-06-29 20:06:16 past   2018-07-06 03:00:00 2018-07-05
#>  4 2520… R Pr… 2018-06-23 00:00:20 past   2018-07-12 03:00:00 2018-07-11
#>  5 2510… Auto… 2018-05-24 01:34:47 past   2018-06-14 03:00:00 2018-06-13
#>  6 2500… R-La… 2018-04-22 05:14:13 past   2018-05-12 03:00:00 2018-05-11
#>  7 2494… Intr… 2018-04-05 03:16:19 past   2018-04-26 03:00:00 2018-04-25
#>  8 2473… Beyo… 2018-01-30 23:40:46 past   2018-02-11 23:00:00 2018-02-11
#>  9 2431… R Vi… 2017-09-05 20:18:08 past   2017-09-24 23:00:00 2017-09-24
#> 10 2413… RShi… 2017-07-06 19:47:58 past   2017-07-30 23:00:00 2017-07-30
#> # ... with 37 more rows, and 15 more variables: local_time <chr>,
#> #   waitlist_count <int>, yes_rsvp_count <int>, venue_id <int>,
#> #   venue_name <chr>, venue_lat <dbl>, venue_lon <dbl>,
#> #   venue_address_1 <chr>, venue_city <chr>, venue_state <chr>,
#> #   venue_zip <chr>, venue_country <chr>, description <chr>, link <chr>,
#> #   resource <list>
```

## How can you contribute?

Take a look at some resources:

  - <https://www.meetup.com/meetup_api/>
  - <https://www.meetup.com/meetup_api/clients/>

In order to run our tests, you will have to set the `urlname` for meetup
you belong to as an environment variable using the following code:

``` r
Sys.setenv(MEETUP_NAME = "YOUR MEETUP NAME")
```

### TODO:

  - add tests

–

Please note that the ‘meetupr’ project is released with a [Contributor
Code of Conduct](CODE_OF_CONDUCT.md). By contributing to this project,
you agree to abide by its terms.
