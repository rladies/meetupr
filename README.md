
<!-- README.md is generated from README.Rmd. Please edit the Rmd file -->
meetupr
=======

[![Build Status](https://travis-ci.org/rladies/meetupr.svg?branch=master)](https://travis-ci.org/rladies/meetupr)

R interface to the Meetup API (v3)

**Authors:** [Gabriela de Queiroz](http://gdequeiroz.github.io/), [Erin LeDell](http://www.stat.berkeley.edu/~ledell/), [Olga Mierzwa-Sulima](https://github.com/olgamie), [Lucy D'Agostino McGowan](http://www.lucymcgowan.com), [Claudia Vitolo](https://github.com/cvitolo)<br/> [MIT](https://opensource.org/licenses/MIT) **License:** [MIT](https://opensource.org/licenses/MIT)

Installation
------------

To install the development version from GitHub:

``` r
# install.packages("devtools")
devtools::install_github("rladies/meetupr")
```

A released version will be on CRAN soon.

Usage
-----

To use this package, you will first need to get your meetup API key. To do so, go to this link: <https://secure.meetup.com/meetup_api/key/>

Once you have your key, save it as an environment variable by running the following:

``` r
Sys.setenv(MEETUP_KEY = "PASTE YOUR MEETUP KEY HERE")
```

If you don't want to save it here, you can input it in each function using the `api_key` parameter (just be sure not to send any documents with your key to GitHub 🙊).

We currently have the following functions:

-   `get_members()`
-   `get_boards()`
-   `get_events()`
-   `get_event_attendees()`
-   `get_event_comments()`
-   `get_event_rsvps()` \*Note: Must be a Meetup group administrator to use because of API restriction.
-   `find_groups()`

Each will output a tibble with information extracted into from the API as well as a `list-col` named `*_resource` with all API output. For example, the following code will get all upcoming events for the [RLadies Nashville](https://meetup.com/rladies-nashville) meetup.

``` r
library(meetupr)

urlname <- "rladies-nashville"
(events <- get_events(urlname, event_status = "past"))
#> Downloading 9 record(s)...
#> # A tibble: 9 x 21
#>   id     name    created             status time                local_date
#>   <chr>  <chr>   <dttm>              <chr>  <dttm>              <date>    
#> 1 23496~ R-Ladi~ 2016-10-19 11:52:17 past   2016-11-07 18:30:00 2016-11-07
#> 2 23565~ Decemb~ 2016-11-17 14:11:58 past   2016-12-06 13:15:00 2016-12-06
#> 3 23575~ Januar~ 2016-11-22 11:27:58 past   2017-01-10 19:00:00 2017-01-10
#> 4 23705~ Februa~ 2017-01-19 17:29:02 past   2017-02-10 13:15:00 2017-02-10
#> 5 23705~ March ~ 2017-01-19 17:36:31 past   2017-03-21 19:00:00 2017-03-21
#> 6 23993~ An R +~ 2017-05-12 12:21:43 past   2017-05-30 13:00:00 2017-05-30
#> 7 24209~ Workin~ 2017-07-28 15:29:41 past   2017-09-12 19:00:00 2017-09-12
#> 8 24333~ Introd~ 2017-09-13 10:42:01 past   2017-11-13 19:00:00 2017-11-13
#> 9 24333~ Play i~ 2017-09-13 10:42:51 past   2017-12-01 13:00:00 2017-12-01
#> # ... with 15 more variables: local_time <chr>, waitlist_count <int>,
#> #   yes_rsvp_count <int>, venue_id <int>, venue_name <chr>,
#> #   venue_lat <dbl>, venue_lon <dbl>, venue_address_1 <chr>,
#> #   venue_city <chr>, venue_state <chr>, venue_zip <chr>,
#> #   venue_country <chr>, description <chr>, link <chr>, resource <list>
```

How can you contribute?
-----------------------

Take a look at some resources:

-   <https://www.meetup.com/meetup_api/>
-   <https://www.meetup.com/meetup_api/clients/>

In order to run our tests, you will have to set the `urlname` for meetup you belong to as an environment variable using the following code:

``` r
Sys.setenv(MEETUP_NAME = "YOUR MEETUP NAME")
```

### TODO:

-   add tests
