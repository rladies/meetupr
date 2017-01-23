##meetupr

R interface to the meetup.com API


##Installation

TO DO

##Usage

To use this package, you will first need to get your meetup API key. To do so, go to this link: [https://secure.meetup.com/meetup_api/key/](https://secure.meetup.com/meetup_api/key/)

```
library(meetupr)

api_key <- "INSERT_HERE"

group_name <- "INSER THE NAME OF THE GROUP"

events <- get_events(group_name, api_key)
```



## How can you contribute?

First, take a look at some resources:

- [https://www.meetup.com/meetup_api/](https://www.meetup.com/meetup_api/)
- [https://www.meetup.com/meetup_api/clients/](https://www.meetup.com/meetup_api/clients/)

We are going to support v3 first.



##License

MIT © Gabriela de Queiroz, Erin LeDell
