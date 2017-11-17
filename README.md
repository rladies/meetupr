meetupr: R interface to the meetup.com API
--------------------

[![Build Status](https://travis-ci.org/rladies/meetupr.svg?branch=master)](https://travis-ci.org/rladies/meetupr)

**Authors:** [Gabriela de Queiroz](http://gdequeiroz.github.io/), [Erin LeDell](http://www.stat.berkeley.edu/~ledell/), [Olga Mierzwa-Sulima](https://github.com/olgamie), [Lucy D'Agostino McGowan](http://www.lucymcgowan.com)<br/>
**License:** [MIT](https://opensource.org/licenses/MIT)


## Installation

```{r}
# install.packages("devtools")
library(devtools)
devtools::install_github("rladies/meetupr")
```
🚧 **WARNING**: The package is undergoing a big re-org and we'd recommend that you install the "deprecated_etc" branch.  Many of the functions in the master branch will be deprecated and functions return tibbles now instead of lists.  To install that branch, do the following:

```{r}
# install.packages("devtools")
library(devtools)
devtools::install_github("rladies/meetupr", ref = "deprecated_etc")
```
The new version will be on CRAN soon.

## Usage

To use this package, you will first need to get your meetup API key. To do so, go to this link: [https://secure.meetup.com/meetup_api/key/](https://secure.meetup.com/meetup_api/key/)

```{r}
library(meetupr)

api_key <- "INSERT_KEY_HERE"
group_name <- "INSERT THE NAME OF THE GROUP"

events <- get_events(group_name, api_key)
```

When you have your Meetup API key, you can set up an environment variable, by adding the following to your `.Rprofile`:

```{r}
Sys.setenv(meetup_api_key = "INSERT_KEY_HERE")
```

## How can you contribute?

First, take a look at some resources:

- [https://www.meetup.com/meetup_api/](https://www.meetup.com/meetup_api/)
- [https://www.meetup.com/meetup_api/clients/](https://www.meetup.com/meetup_api/clients/)

We are going to support v3 first.

### DONE:
- pull meetup events
- pull event comments
- pull event attendance
- pull meetup members
- pull meetup boards

### TODO:
- add tests

