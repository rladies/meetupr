
<!-- README.md is generated from README.Rmd. Please edit that file -->
meetupr
=======

[![Build Status](https://travis-ci.org/rladies/meetupr.svg?branch=master)](https://travis-ci.org/rladies/meetupr)

R interface to the Meetup API (v3)

**Authors:** [Gabriela de Queiroz](http://gdequeiroz.github.io/), [Erin LeDell](http://www.stat.berkeley.edu/~ledell/), [Olga Mierzwa-Sulima](https://github.com/olgamie), [Lucy D'Agostino McGowan](http://www.lucymcgowan.com)<br/> **License:** [MIT](https://opensource.org/licenses/MIT)

Installation
------------

You can install meetupr from github with:

``` r
# install.packages("devtools")
devtools::install_github("rladies/meetupr")
```

Usage
-----

To use this package, you will first need to get your meetup API key. To do so, go to this link: <https://secure.meetup.com/meetup_api/key/>

Once you have your key, save it as an environment variable by running the following:

``` r
Sys.setenv(MEETUP_KEY = "PASTE YOUR MEETUP KEY HERE")
```

If you don't want to save it here, you can input it in each function using the `api_key` parameter (just be sure not to send any documents with your key to GitHub 🙊).

We currently have four functions:

-   `get_events()`
-   `get_members()`
-   `get_attendees()`
-   `get_comments()`

Each will output a tibble with information extracted into from the API as well as a `list-col` named `*_resource` with all API output. For example, the following code will get all upcoming events for the [RLadies Nashville](https://meetup.com/rladies-nashville) meetup.

``` r
library(meetupr)

urlname <- "rladies-nashville"
(events <- get_events(urlname))
#> # A tibble: 1 x 5
#>          id                                  name n_rsvp
#>       <chr>                                 <chr>  <int>
#> 1 242098493 Working with Pipes %>% + GIS Tutorial     16
#> # ... with 2 more variables: time <dttm>, event_resource <list>
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

### DONE:

-   pull meetup events
-   pull event comments
-   pull event attendance
-   pull meetup members

### TODO:

-   add tests
