
<!-- README.md is generated from README.Rmd. Please edit the Rmd file -->
meetupr
=======

[![Build Status](https://travis-ci.org/rladies/meetupr.svg?branch=master)](https://travis-ci.org/rladies/meetupr)

R interface to the Meetup API (v3)

**Authors:** [Gabriela de Queiroz](http://gdequeiroz.github.io/), [Erin LeDell](http://github.com/ledell/), [Olga Mierzwa-Sulima](https://github.com/olgamie), [Lucy D'Agostino McGowan](http://www.lucymcgowan.com), [Claudia Vitolo](https://github.com/cvitolo)<br/> **License:** [MIT](https://opensource.org/licenses/MIT)

Installation
------------

To install the development version from GitHub:

``` r
# install.packages("remotes")
remotes::install_github("rladies/meetupr")
```

A released version will be on CRAN [soon](https://github.com/rladies/meetupr/issues/24).

Usage
-----

### Authentication

As of August 15, 2019, Meetup.com switched from an API key based authentication system to [OAuth 2.0](https://www.meetup.com/meetup_api/auth/), so we now [support OAuth authentication](https://github.com/rladies/meetupr/issues/51). The functions all have a `api_key` argument which is no longer used and will eventually be [deprecated](https://github.com/rladies/meetupr/issues/59). In order to use this package, you can use our built-in OAuth credentials (recommended), or if you prefer, you can supply your own by setting the `meetupr.consumer_key` and `meetupr.consumer_secret` variables.

Each time you use the package, you will be prompted to log in to your meetup.com account. The first time you run any of the *meetupr* functions in your session, R will open a browser window, prompting you to "Log In and Grant Access" (to the meetupr "application").

### Functions

We currently have the following functions:

-   `get_members()`
-   `get_boards()`
-   `get_events()`
-   `get_event_attendees()`
-   `get_event_comments()`
-   `get_event_rsvps()`
-   `find_groups()`

Each will output a tibble with information extracted into from the API as well as a `list-col` named `*_resource` with all API output. For example, the following code will get all upcoming events for the [R-Ladies San Francisco](https://meetup.com/rladies-san-francisco) meetup.

``` r
library(meetupr)

urlname <- "rladies-san-francisco"
events <- get_events(urlname, "past")
#> Meetup is moving to OAuth *only* as of 2019-08-15. Set
#> `meetupr.use_oauth = FALSE` in your .Rprofile, to use
#> the legacy `api_key` authorization.
#> Downloading 57 record(s)...
dplyr::arrange(events, desc(created))
#> # A tibble: 57 x 21
#>    id    name  created             status time                local_date
#>    <chr> <chr> <dttm>              <chr>  <dttm>              <date>    
#>  1 2663… Dece… 2019-11-11 14:10:10 past   2019-12-10 18:00:00 2019-12-10
#>  2 2651… Work… 2019-09-23 12:28:24 past   2019-10-16 18:00:00 2019-10-16
#>  3 2632… Augu… 2019-07-17 10:29:10 past   2019-08-07 18:00:00 2019-08-07
#>  4 2627… R-La… 2019-06-28 15:24:12 past   2019-07-21 11:00:00 2019-07-21
#>  5 2626… Baye… 2019-06-26 20:11:16 past   2019-07-17 18:00:00 2019-07-17
#>  6 2610… Mini… 2019-04-30 17:49:52 past   2019-05-18 13:30:00 2019-05-18
#>  7 2590… NLP … 2019-02-15 14:36:58 past   2019-03-12 18:00:00 2019-03-12
#>  8 2583… Work… 2019-01-23 21:18:09 past   2019-02-07 18:00:00 2019-02-07
#>  9 2574… Ligh… 2018-12-21 11:57:26 past   2019-01-22 18:00:00 2019-01-22
#> 10 2560… Work… 2018-10-31 10:34:07 past   2018-11-13 18:00:00 2018-11-13
#> # … with 47 more rows, and 15 more variables: local_time <chr>,
#> #   waitlist_count <int>, yes_rsvp_count <int>, venue_id <int>,
#> #   venue_name <chr>, venue_lat <dbl>, venue_lon <dbl>,
#> #   venue_address_1 <chr>, venue_city <chr>, venue_state <chr>,
#> #   venue_zip <chr>, venue_country <chr>, description <chr>, link <chr>,
#> #   resource <list>
```

Next we can look up all R-Ladies groups by "topic id". You can find topic ids for associated tags by querying [here](https://secure.meetup.com/meetup_api/console/?path=/find/topics). The `topic_id` for topic, "R-Ladies", is `1513883`.

``` r
groups <- find_groups(topic_id = 1513883)
#> Downloading 152 record(s)...
dplyr::arrange(groups, desc(created))
#> # A tibble: 152 x 21
#>        id name  urlname created             members status organizer    lat
#>     <int> <chr> <chr>   <dttm>                <int> <chr>  <chr>      <dbl>
#>  1 3.32e7 R-La… rladie… 2020-01-12 09:47:12      18 active R-Ladies…  25.7 
#>  2 3.32e7 R-La… rladie… 2020-01-12 09:39:04      12 active R-Ladies…  51.8 
#>  3 3.31e7 R-La… rladie… 2019-12-15 11:50:22      21 active R-Ladies…  38.9 
#>  4 3.31e7 R-La… rladie… 2019-12-15 05:30:12      26 active R-Ladies…   6.93
#>  5 3.31e7 R-La… rladie… 2019-11-30 08:55:10      14 active R-Ladies…  30.0 
#>  6 3.31e7 R-La… rladie… 2019-11-30 08:09:20       5 active R-Ladies…  43.0 
#>  7 3.30e7 R-La… rladie… 2019-11-23 11:14:43      41 active R-Ladies…  19.0 
#>  8 3.30e7 R-La… rladie… 2019-11-23 11:02:15      21 active R-Ladies…  57.7 
#>  9 3.28e7 R-La… rladie… 2019-09-29 07:26:02      14 active R-Ladies… -20.3 
#> 10 3.28e7 R-La… R-Ladi… 2019-09-11 11:38:26      21 active Themis L…  -3.12
#> # … with 142 more rows, and 13 more variables: lon <dbl>, city <chr>,
#> #   state <chr>, country <chr>, timezone <chr>, join_mode <chr>,
#> #   visibility <chr>, who <chr>, organizer_id <int>, organizer_name <chr>,
#> #   category_id <int>, category_name <chr>, resource <list>
```

How can you contribute?
-----------------------

Take a look at some resources:

-   <https://www.meetup.com/meetup_api/>
-   <https://www.meetup.com/meetup_api/clients/>

We are looking for people to help write tests and vignettes! You can also take a look at the open [issues](https://github.com/rladies/meetupr/issues).

--

Please note that the 'meetupr' project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By contributing to this project, you agree to abide by its terms.
