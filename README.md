
<!-- README.md is generated from README.Rmd. Please edit the Rmd file -->

# meetupr <img src="man/figures/logo.png" align="right" alt="Zane Dax @StarTrek_Lt" width="138.5" />

<small>Logo by Zane Dax
[@StarTrek_Lt](https://mobile.twitter.com/startrek_lt)</small>

## ⚠️ ALERT TO USERS:

Meetup has deprecated the REST API that’s used in this package. We are
working to [add support](https://github.com/rladies/meetupr/issues/118)
for their new API but unfortnately that means that the package is not
currently functional. If you’d like to help with this transition in any
way (we could use help with testing and documentation in particular),
please comment on the this
[issue](https://github.com/rladies/meetupr/issues/118).

<!-- badges: start -->

[![R-CMD-check](https://github.com/rladies/meetupr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/rladies/meetupr/actions)
[![Codecov test
coverage](https://codecov.io/gh/rladies/meetupr/branch/master/graph/badge.svg)](https://codecov.io/gh/rladies/meetupr?branch=master)
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
events <- get_events(urlname)
dplyr::arrange(events, desc(time))
#> # A tibble: 63 × 18
#>    id        title    link  status durat…¹ going waiting descr…² venue…³ venue…⁴
#>    <chr>     <chr>    <chr> <chr>  <chr>   <int>   <int> <chr>   <chr>     <dbl>
#>  1 280404371 Data St… http… PAST   PT1H30M    61       0 "=====… 269060…   -8.52
#>  2 277757076 Buildin… http… PAST   PT2H       70       0 "Build… 269060…   -8.52
#>  3 273036282 A conve… http… PAST   PT2H       30       0 "Fires… 269060…   -8.52
#>  4 272407729 Tangibl… http… PAST   PT1H30M    45       0 "Tangi… 269060…   -8.52
#>  5 267967077 R-Ladie… http… PAST   PT2H       95       0 "Just … 260586…   37.8 
#>  6 266395328 Decembe… http… PAST   PT2H30M    98       0 "Join … 261907…   37.8 
#>  7 265100301 Worksho… http… PAST   PT2H       40       0 "\"Tra… 266458…   37.8 
#>  8 263230714 August … http… PAST   PT2H       58       0 "1. Bu… 265200…   37.6 
#>  9 262717409 R-Ladie… http… PAST   PT3H       18       0 "Come … 260979…   37.8 
#> 10 262662040 Bayesia… http… PAST   PT2H       57       0 "MAIN … 260597…   37.8 
#> # … with 53 more rows, 8 more variables: venue_lon <dbl>, venue_name <chr>,
#> #   venue_address <chr>, venue_city <chr>, venue_state <chr>, venue_zip <chr>,
#> #   venue_country <chr>, time <dttm>, and abbreviated variable names ¹​duration,
#> #   ²​description, ³​venue_id, ⁴​venue_lat
#> # ℹ Use `print(n = ...)` to see more rows, and `colnames()` to see all variable names
```

We can also search for groups with free text.

``` r
groups <- find_groups("R-Ladies")
dplyr::arrange(groups, desc(created))
#> # A tibble: 189 × 17
#>    id       name             urlname latit…¹ longi…² city  state membe…³ members
#>    <chr>    <chr>            <chr>     <dbl>   <dbl> <chr> <chr> <chr>     <int>
#>  1 36221103 R-Ladies Honolu… rladie…    21.3 -158.   Hono… "HI"  LEADER       11
#>  2 36221061 R-Ladies Rabat   rladie…    34.0   -6.83 Rabat ""    LEADER      145
#>  3 36155475 R-Ladies Morelia rladie…    19.7 -101.   More… ""    LEADER       97
#>  4 36155463 R-Ladies Ciudad… rladie…    27.5 -110.   Ciud… ""    LEADER        2
#>  5 36128420 R-Ladies Rome    rladie…    41.9   12.5  Roma  "RM"  LEADER       25
#>  6 36128390 R-Ladies Oxford… rladie…    34.4  -89.5  Oxfo… "MS"  LEADER        3
#>  7 35897820 R-Ladies Gaboro… rladie…   -24.6   25.9  Gabo… ""    LEADER      490
#>  8 35897809 R-Ladies Cologne rladie…    50.9    6.96 Colo… ""    LEADER      178
#>  9 35897790 R-Ladies West L… rladie…    40.5  -87.0  West… "IN"  LEADER        9
#> 10 35897779 R-Ladies Villah… rladie…    18.0  -92.9  Vill… ""    LEADER      116
#> # … with 179 more rows, 8 more variables: created <dttm>, timezone <chr>,
#> #   join_mode <chr>, who <chr>, isPrivate <lgl>, category_id <chr>,
#> #   category_name <chr>, country <chr>, and abbreviated variable names
#> #   ¹​latitude, ²​longitude, ³​membershipMetadata.status
#> # ℹ Use `print(n = ...)` to see more rows, and `colnames()` to see all variable names
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
