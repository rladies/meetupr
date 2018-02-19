
<!-- README.md is generated from README.Rmd. Please edit the Rmd file -->
meetupr
=======

[![Build Status](https://travis-ci.org/rladies/meetupr.svg?branch=master)](https://travis-ci.org/rladies/meetupr)

R interface to the Meetup API (v3)

**Authors:** [Gabriela de Queiroz](http://gdequeiroz.github.io/), [Erin LeDell](http://www.stat.berkeley.edu/~ledell/), [Olga Mierzwa-Sulima](https://github.com/olgamie), [Lucy D'Agostino McGowan](http://www.lucymcgowan.com), [Claudia Vitolo](https://github.com/cvitolo)<br/> **License:** [MIT](https://opensource.org/licenses/MIT)

Installation
------------

To install the development version from GitHub:

```{r}
# install.packages("devtools")
library(devtools)
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
-   `get_event_rsvps()`   
-   `find_groups()`

Each will output a tibble with information extracted into from the API as well as a `list-col` named `*_resource` with all API output. For example, the following code will get all upcoming events for the [RLadies Nashville](https://meetup.com/rladies-nashville) meetup.

``` r
library(meetupr)

urlname <- "rladies-nashville"
(events <- get_events(urlname))
#> # A tibble: 2 x 5
#>          id                    name yes_rsvp_count                time
#>       <chr>                   <chr>          <int>              <dttm>
#> 1 243331077   Introduction to purrr             11 2017-11-14 00:00:00
#> 2 243331084 TBA with Laurie Samuels              5 2017-12-01 18:00:00
#> # ... with 1 more variables: resource <list>
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

### TO DO:

-   add tests
