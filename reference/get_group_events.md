# Get the events from a meetup group

Get the events from a meetup group

## Usage

``` r
get_group_events(
  urlname,
  status = NULL,
  date_before = NULL,
  date_after = NULL,
  max_results = NULL,
  handle_multiples = "list",
  extra_graphql = NULL,
  asis = FALSE,
  ...
)
```

## Arguments

- urlname:

  Character. The name of the group as indicated in the
  <https://www.meetup.com/> url.

- status:

  Character vector of event statuses to retrieve.

- date_before:

  Datetime string in "YYYY-MM-DDTHH:MM:SSZ" (ISO8601) format. Events
  occurring before this date/time will be returned.

- date_after:

  Datetime string in "YYYY-MM-DDTHH:MM:SSZ" (ISO8601) format. Events
  occurring after this date/time will be returned.

- max_results:

  Maximum number of results to return. If set to NULL, will return all
  available results (may take a long time).

- handle_multiples:

  Character. How to handle multiple matches. One of "list" or "first",
  or "error". If "list", return a list-column with all matches. If
  "first", return only the first match.

- extra_graphql:

  A graphql object. Extra objects to return

- asis:

  Return the raw API response as-is without processing

- ...:

  Should be empty. Used for parameter expansion

## Value

A tibble with the events for the specified group

## Examples

``` r
get_group_events("rladies-lagos", "past")
#> # A tibble: 13 × 23
#>    id        title  event_url created_time status date_time duration description
#>    <chr>     <chr>  <chr>     <chr>        <chr>  <chr>     <chr>    <chr>      
#>  1 264156061 satRd… https://… 2019-08-20T… PAST   2019-09-… PT7H     "satRday-L…
#>  2 266757265 Data … https://… 2019-11-26T… PAST   2019-12-… PT7H     "Hi there …
#>  3 267804814 Getti… https://… 2020-01-10T… PAST   2020-02-… PT7H     "Hi there …
#>  4 284322273 Data … https://… 2022-02-28T… PAST   2022-03-… PT2H     "**About t…
#>  5 284612394 R Lad… https://… 2022-03-14T… PAST   2022-05-… PT1H     "Join us f…
#>  6 292261535 Women… https://… 2023-03-15T… PAST   2023-03-… PT2H     "Join us f…
#>  7 293181201 R Pac… https://… 2023-04-27T… PAST   2023-05-… PT2H     "Are you i…
#>  8 294750659 Unloc… https://… 2023-07-11T… PAST   2023-07-… PT2H     "In today'…
#>  9 295011502 Hackn… https://… 2023-07-24T… PAST   2023-08-… PT30H    "# The Cha…
#> 10 293909113 Gener… https://… 2023-06-01T… PAST   2023-09-… PT2H     "Discover …
#> 11 300026594 Build… https://… 2024-03-26T… PAST   2024-04-… PT3H     "**🚀 Build…
#> 12 300356000 Inter… https://… 2024-04-11T… PAST   2024-04-… PT5H     "**Celebra…
#> 13 300027094 Inter… https://… 2024-03-26T… PAST   2024-04-… PT3H     "About thi…
#> # ℹ 15 more variables: group_id <chr>, group_name <chr>, group_urlname <chr>,
#> #   venues_id <list>, venues_name <list>, venues_address <list>,
#> #   venues_city <list>, venues_state <list>, venues_postal_code <list>,
#> #   venues_country <list>, venues_lat <list>, venues_lon <list>,
#> #   venues_venue_type <list>, rsvps_count <int>, featured_event_photo_url <chr>
get_group_events(
  "rladies-lagos",
  status = "past",
  date_before = "2023-01-01T12:00:00Z"
)
#> # A tibble: 5 × 23
#>   id        title   event_url created_time status date_time duration description
#>   <chr>     <chr>   <chr>     <chr>        <chr>  <chr>     <chr>    <chr>      
#> 1 264156061 satRda… https://… 2019-08-20T… PAST   2019-09-… PT7H     "satRday-L…
#> 2 266757265 Data M… https://… 2019-11-26T… PAST   2019-12-… PT7H     "Hi there …
#> 3 267804814 Gettin… https://… 2020-01-10T… PAST   2020-02-… PT7H     "Hi there …
#> 4 284322273 Data N… https://… 2022-02-28T… PAST   2022-03-… PT2H     "**About t…
#> 5 284612394 R Ladi… https://… 2022-03-14T… PAST   2022-05-… PT1H     "Join us f…
#> # ℹ 15 more variables: group_id <chr>, group_name <chr>, group_urlname <chr>,
#> #   venues_id <chr>, venues_name <chr>, venues_address <chr>,
#> #   venues_city <chr>, venues_state <chr>, venues_postal_code <chr>,
#> #   venues_country <chr>, venues_lat <dbl>, venues_lon <dbl>,
#> #   venues_venue_type <chr>, rsvps_count <int>, featured_event_photo_url <chr>
```
