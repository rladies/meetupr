# Retrieve information about Meetup Pro networks, including groups and events.

Meetup Pro is a premium service for organizations managing multiple
Meetup groups. This functionality allows you to access details about the
groups within a Pro network and the events they host.

## Usage

``` r
get_pro_groups(
  urlname,
  max_results = NULL,
  handle_multiples = "list",
  extra_graphql = NULL,
  asis = FALSE,
  ...
)

get_pro_events(
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

- status:

  Which status the events should have.

- date_before:

  Datetime string in "YYYY-MM-DDTHH:MM:SSZ" (ISO8601) format. Events
  occurring before this date/time will be returned.

- date_after:

  Datetime string in "YYYY-MM-DDTHH:MM:SSZ" (ISO8601) format. Events
  occurring after this date/time will be returned.

## Value

tibble with pro network information

A tibble with meetup pro information

## Functions

- `get_pro_groups()`: retrieve groups in a pro network

- `get_pro_events()`: retrieve events from a pro network

## Examples

``` r
urlname <- "rladies"
members <- get_pro_groups(urlname)

upcoming_events <- get_pro_events(urlname, "upcoming", max_results = 5)
```
