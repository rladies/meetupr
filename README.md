meetupr: R interface to the meetup.com API
--------------------

[![Build Status](https://travis-ci.org/rladies/meetupr.svg?branch=master)](https://travis-ci.org/rladies/meetupr)

**Authors:** [Gabriela de Queiroz](http://gdequeiroz.github.io/), [Erin LeDell](http://www.stat.berkeley.edu/~ledell/),Olga Mierzwa-Sulima, [Lucy D'Agostino McGowan](http://www.lucymcgowan.com)<br/>
**License:** [MIT](https://opensource.org/licenses/MIT)


##Installation

TO DO

##Usage

To use this package, you will first need to get your meetup API key. To do so, go to this link: [https://secure.meetup.com/meetup_api/key/](https://secure.meetup.com/meetup_api/key/)

```
library(meetupr)

api_key <- "INSERT_HERE"

group_name <- "INSERT THE NAME OF THE GROUP"

events <- get_events(group_name, api_key)
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

### TODO:
- pull meetup members
- add tests
- update README with installation information

