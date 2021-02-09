
<!-- README.md is generated from README.Rmd. Please edit the Rmd file -->

# meetupr

<!-- badges: start -->

[![R-CMD-check](https://github.com/rladies/meetupr/workflows/R-CMD-check/badge.svg)](https://github.com/rladies/meetupr/actions)
<!-- badges: end -->

R interface to the [Meetup API](https://www.meetup.com/meetup_api/) (v3)

## Installation

To install the development version from GitHub:

``` r
# install.packages("remotes")
remotes::install_github("rladies/meetupr")
```

A released version will be on CRAN
[soon](https://github.com/rladies/meetupr/issues/24).

## Usage

### Authentication

#### API key? No

As of August 15, 2019, Meetup.com switched from an API key based
authentication system to OAuth 2.0, so we added support for OAuth.

#### OAuth? Yes

Meetup API and this package recommend using OAuth for authentication.
We’ve abstracted part of the difficulty but it’s still a bit more
complex than storing a simple API key as secret.

With OAuth you need

-   an OAuth app. There’s one shipped in with the package! If you prefer
    you can bring your own app by setting the `meetupr.consumer_key` and
    `meetupr.consumer_secret` options.

-   an access token. It’s an httr object and it can be saved to disk. It
    expires but can be refreshed. It contains secrets so it’s a
    sensitive file! For creating one you will be prompted to log into
    your meetup.com account in the browser. But then if you cache the
    token to disk, you won’t need to do that again. This means you can
    create a token on your computer locally and use it on a server (if
    the server is public, encrypting the token).

Let’s go through workflows and ways to control how your token is created
and cached.

If you don’t tweak anything, the first time you run a meetupr function,
you’ll be prompted to go into your browser and a token will be created.
It will be saved to disk in an app directory as determined by
`rappdirs::user_data_dir("meetupr", "meetupr")`

And all the times you use meetupr again, this token will be used, and
refreshed and re-saved as needed.

This is, we hope, a sensible default.

Now if you want to have a different behavior you either tweak options
(in your .Rprofile so for all sessions in the future, or just in the
current session), or call the `meetup_auth()` function directly.

-   Don’t want to cache the token to disk? Use the `cache` argument, to
    be set to `FALSE`.
-   Don’t want to use an app dir? Use the `use_appdir` argument, to be
    set to `FALSE`. If it is false, the token will be cached to
    `.httr-oauth` (unless `cache` is FALSE too, of course)
-   Want to save the token to somewhere you choose? No way to use an
    option. Use the `token_path` argument of `meetup_auth()`.
-   Want to use a token that was created elsewhere? Save it to disk,
    keep it secret, and refer to it via the `token` argument of
    `meetup_auth()` that can be either a token or the path to a token.

### Functions

See the [pkgdown
reference](https://rladies.github.io/meetupr/reference/index.html).

For example, the following code will get all upcoming events for the
[R-Ladies San Francisco](https://meetup.com/rladies-san-francisco)
meetup.

``` r
library(meetupr)

urlname <- "rladies-san-francisco"
events <- get_events(urlname, "past")
dplyr::arrange(events, desc(created))
#> # A tibble: 60 x 22
#>    id    name  created             status time                local_date
#>    <chr> <chr> <dttm>              <chr>  <dttm>              <date>    
#>  1 2730… A co… 2020-09-04 20:04:50 past   2020-09-11 00:30:00 2020-09-10
#>  2 2724… Tang… 2020-08-06 21:24:51 past   2020-08-28 02:30:00 2020-08-27
#>  3 2679… R-La… 2020-01-16 19:08:03 past   2020-01-31 02:00:00 2020-01-30
#>  4 2663… Dece… 2019-11-11 23:10:10 past   2019-12-11 03:00:00 2019-12-10
#>  5 2651… Work… 2019-09-23 21:28:24 past   2019-10-17 03:00:00 2019-10-16
#>  6 2632… Augu… 2019-07-17 19:29:10 past   2019-08-08 03:00:00 2019-08-07
#>  7 2627… R-La… 2019-06-29 00:24:12 past   2019-07-21 20:00:00 2019-07-21
#>  8 2626… Baye… 2019-06-27 05:11:16 past   2019-07-18 03:00:00 2019-07-17
#>  9 2610… Mini… 2019-05-01 02:49:52 past   2019-05-18 22:30:00 2019-05-18
#> 10 2590… NLP … 2019-02-15 23:36:58 past   2019-03-13 02:00:00 2019-03-12
#> # … with 50 more rows, and 16 more variables: duration <int>, local_time <chr>,
#> #   waitlist_count <int>, yes_rsvp_count <int>, venue_id <int>,
#> #   venue_name <chr>, venue_lat <dbl>, venue_lon <dbl>, venue_address_1 <chr>,
#> #   venue_city <chr>, venue_state <chr>, venue_zip <chr>, venue_country <chr>,
#> #   description <chr>, link <chr>, resource <list>
```

Next we can look up all R-Ladies groups by “topic id”. You can find
topic ids for associated tags by querying
[here](https://secure.meetup.com/meetup_api/console/?path=/find/topics).
The `topic_id` for topic, “R-Ladies”, is `1513883`.

``` r
groups <- find_groups(topic_id = 1513883)
dplyr::arrange(groups, desc(created))
#> # A tibble: 137 x 20
#>        id name  urlname status   lat     lon city  state country
#>     <int> <chr> <chr>   <chr>  <dbl>   <dbl> <chr> <chr> <chr>  
#>  1 3.38e7 R-La… rladie… active -1.29   36.8  Nair… ""    KE     
#>  2 3.34e7 R-La… rladie… active 52.4    -1.5  Cove… "43"  GB     
#>  3 3.34e7 R-La… rladie… active 43.3    21.9  Niš   ""    RS     
#>  4 3.32e7 R-La… rladie… active 25.7  -100.   Mont… ""    MX     
#>  5 3.32e7 R-La… rladie… active 51.8    -1.26 Oxfo… "K2"  GB     
#>  6 3.31e7 R-La… rladie… active 38.9   -92.2  Colu… "MO"  US     
#>  7 3.31e7 R-La… rladie… active  6.93   79.8  Colo… ""    LK     
#>  8 3.31e7 R-La… rladie… active 30.0   -90.1  New … "LA"  US     
#>  9 3.31e7 R-La… rladie… active 43.0   -76.2  Syra… "NY"  US     
#> 10 3.30e7 R-La… rladie… active 19.0    72.8  Mumb… ""    IN     
#> # … with 127 more rows, and 11 more variables: created <dttm>, members <int>,
#> #   timezone <chr>, join_mode <chr>, visibility <chr>, who <chr>,
#> #   organizer_id <int>, organizer_name <chr>, category_id <int>,
#> #   category_name <chr>, resource <list>
```

## How can you contribute?

We are looking for new people to join the list of contributors! Please
take a look at the open
[issues](https://github.com/rladies/meetupr/issues), file a new issue,
contribute tests, or improve the documentation. We are also looking to
expand the set of functions to include more endpoints from the [Meetup
API](https://www.meetup.com/meetup_api/). Lastly, we’d also love to
[hear about](https://github.com/rladies/meetupr/issues/74) any
applications of the **meetupr** package, so we can compile a list of
demos!

Please note that the this project is released with a [Contributor Code
of
Conduct](https://github.com/rladies/.github/blob/master/CODE_OF_CONDUCT.md).
By contributing to this project, you agree to abide by its terms.
