# Setting up and Getting Started with meetupr

``` r
library(meetupr)
```

meetupr is an R package that provides a client for the Meetup.com
GraphQL API. It allows you to search for groups, retrieve event
information, get member lists, and access other Meetup data directly
from R. This vignette will guide you through setup, authentication, and
common use cases.

## Quick Setup Check

Start by running
[`meetupr_sitrep()`](http://rladies.org/meetupr/reference/meetupr_sitrep.md)
to check your authentication status or set up authentication:

``` r
meetupr_sitrep()
#> 
#> ── meetupr Situation Report ────────────────────────────────────────────────────
#> 
#> ── Active Authentication Method ──
#> 
#> ✔ Authentication available
#> ℹ Active method: jwt
#> ℹ Client name: testclient
#> ✔ JWT token: Available and valid
#> ✔ JWT issuer: 1234567890
#> ✔ Client key: fake_c...
#> 
#> ── API Connectivity Test ──
#> 
#> ✔ API Connection: Working
#> ℹ Authenticated as: R-Ladies Global
```

This function shows you:

- Which authentication method is currently active  
- Whether your credentials are properly configured  
- API connectivity status  
- Setup instructions if authentication is missing

The function provides actionable feedback, telling you exactly what to
do if authentication isn’t working.

## Authentication

Authentication is required to access the Meetup API. meetupr
automatically detects whether you’re working interactively or in an
automated environment:

- **Interactive sessions** (RStudio, R console): OAuth opens a browser
  for authorization
- **Non-interactive sessions** (CI/CD, scheduled scripts): OAuth uses
  pre-cached tokens

This detection uses
[`rlang::is_interactive()`](https://rlang.r-lib.org/reference/is_interactive.html)
to determine the context and switch authentication flows accordingly.

When working interactively:

``` r
# First time: browser opens for authorization
get_group("rladies-lagos")

# Subsequent calls: uses cached token (no browser)
get_group_events("rladies-lagos")
```

When running non-interactively (GitHub Actions, cron jobs):

``` r
# Load token from environment variables (set via CI secrets)
meetupr_encrypt_load()

# All API calls use the loaded token
get_group_events("rladies-lagos")
```

The package handles the switching automatically — you don’t need to
change your code between environments.

### Interactive Authentication

For interactive use (exploring data, one-off analyses), simply
authenticate when prompted:

``` r
# Authenticate interactively (opens browser)
meetupr_auth()

# Check authentication status
meetupr_auth_status()
```

When you run
[`meetupr_auth()`](http://rladies.org/meetupr/reference/meetupr_auth.md):

1.  A browser window opens to Meetup’s authorization page  
2.  You log in with your Meetup credentials  
3.  You grant permission to the meetupr app  
4.  The OAuth token is securely cached on your system

The OAuth token is stored locally in your httr2 cache directory. Token
files follow the naming pattern: `{hash}-token.rds.enc`. These files are
encrypted and specific to your system.

You only need to authenticate once. The token will be reused in future R
sessions until it expires (typically after 90 days).

### Non-Interactive Authentication (CI/CD)

meetupr also supports secure, non-interactive authentication for
automated workflows (such as GitHub Actions, GitLab CI, and other CI/CD
systems). This allows you to run scripts and scheduled jobs without
manual login.

For details on setting up meetupr in CI/CD, including secure token
management and advanced authentication options, see the [Advanced
Authentication](http://rladies.org/meetupr/articles/advanced-auth.md)
vignette.

## Verification

After authenticating, verify the setup:

``` r
meetupr_sitrep()
#> 
#> ── meetupr Situation Report ────────────────────────────────────────────────────
#> 
#> ── Active Authentication Method ──
#> 
#> ✔ Authentication available
#> ℹ Active method: jwt
#> ℹ Client name: testclient
#> ✔ JWT token: Available and valid
#> ✔ JWT issuer: 1234567890
#> ✔ Client key: fake_c...
#> 
#> ── API Connectivity Test ──
#> 
#> ✔ API Connection: Working
#> ℹ Authenticated as: R-Ladies Global
```

The output shows:

- Whether an OAuth token exists and is valid  
- Whether you’re in CI mode (token loaded from environment variables)  
- API connectivity status

## Basic Usage Examples

Once authenticated, you can start querying the Meetup API. All functions
return tibbles (data frames) for easy manipulation with dplyr and other
tidyverse packages.

### Get Group Information

Retrieve detailed information about a specific group using its URL name
(the part after `meetup.com/` in the URL):

``` r
group_info <- get_group("rladies-lagos")
str(group_info)
#> List of 13
#>  $ id          : chr "32612004"
#>  $ name        : chr "R-Ladies Lagos"
#>  $ description : chr "R-Ladies is a world-wide organization to promote gender diversity in the R community.\nR-Ladies welcomes member"| __truncated__
#>  $ urlname     : chr "rladies-lagos"
#>  $ link        : chr "https://www.meetup.com/rladies-lagos"
#>  $ location    :List of 2
#>   ..$ city   : chr "Lagos"
#>   ..$ country: chr "ng"
#>  $ timezone    : chr "Africa/Lagos"
#>  $ created     : POSIXct[1:1], format: "2019-08-16 08:45:21"
#>  $ members     : int 893
#>  $ total_events: int 13
#>  $ organizer   :List of 2
#>   ..$ id  : chr "251470805"
#>   ..$ name: chr "R-Ladies Global"
#>  $ category    :List of 2
#>   ..$ id  : chr "546"
#>   ..$ name: chr "Technology"
#>  $ photo_url   : chr "https://secure-content.meetupstatic.com/images/classic-events/"
#>  - attr(*, "class")= chr [1:2] "meetupr_group" "list"
```

The result includes:

- Group name, description, and URL  
- Location (city, state, country)  
- Member count  
- Organizer information  
- Group creation date

### List Group Events

Get events for a specific group. By default, this returns upcoming
events:

``` r
events <- get_group_events("rladies-lagos")
head(events)
#> # A tibble: 6 × 23
#>   id        title   event_url created_time status date_time duration description
#>   <chr>     <chr>   <chr>     <chr>        <chr>  <chr>     <chr>    <chr>      
#> 1 264156061 satRda… https://… 2019-08-20T… PAST   2019-09-… PT7H     "satRday-L…
#> 2 266757265 Data M… https://… 2019-11-26T… PAST   2019-12-… PT7H     "Hi there …
#> 3 267804814 Gettin… https://… 2020-01-10T… PAST   2020-02-… PT7H     "Hi there …
#> 4 284322273 Data N… https://… 2022-02-28T… PAST   2022-03-… PT2H     "**About t…
#> 5 284612394 R Ladi… https://… 2022-03-14T… PAST   2022-05-… PT1H     "Join us f…
#> 6 292261535 Women … https://… 2023-03-15T… PAST   2023-03-… PT2H     "Join us f…
#> # ℹ 15 more variables: group_id <chr>, group_name <chr>, group_urlname <chr>,
#> #   venues_id <list>, venues_name <list>, venues_address <list>,
#> #   venues_city <list>, venues_state <list>, venues_postal_code <list>,
#> #   venues_country <list>, venues_lat <list>, venues_lon <list>,
#> #   venues_venue_type <list>, rsvps_count <int>, featured_event_photo_url <chr>
```

Each row represents an event with:

- Event ID, title, and description  
- Date and time (as POSIXct objects)  
- Duration  
- RSVP counts (yes, waitlist, total)  
- Venue information (if available)

### Get Past Events

To retrieve historical events, use the `status` parameter:

``` r
past_events <- get_group_events(
  "rladies-lagos",
  status = "past",
  max_results = 10
)
head(past_events)
#> # A tibble: 6 × 23
#>   id        title   event_url created_time status date_time duration description
#>   <chr>     <chr>   <chr>     <chr>        <chr>  <chr>     <chr>    <chr>      
#> 1 264156061 satRda… https://… 2019-08-20T… PAST   2019-09-… PT7H     "satRday-L…
#> 2 266757265 Data M… https://… 2019-11-26T… PAST   2019-12-… PT7H     "Hi there …
#> 3 267804814 Gettin… https://… 2020-01-10T… PAST   2020-02-… PT7H     "Hi there …
#> 4 284322273 Data N… https://… 2022-02-28T… PAST   2022-03-… PT2H     "**About t…
#> 5 284612394 R Ladi… https://… 2022-03-14T… PAST   2022-05-… PT1H     "Join us f…
#> 6 292261535 Women … https://… 2023-03-15T… PAST   2023-03-… PT2H     "Join us f…
#> # ℹ 15 more variables: group_id <chr>, group_name <chr>, group_urlname <chr>,
#> #   venues_id <chr>, venues_name <chr>, venues_address <chr>,
#> #   venues_city <chr>, venues_state <chr>, venues_postal_code <chr>,
#> #   venues_country <chr>, venues_lat <dbl>, venues_lon <dbl>,
#> #   venues_venue_type <chr>, rsvps_count <int>, featured_event_photo_url <chr>
```

### Filter Events by Date

You can filter events within a specific date range:

``` r
# Events from 2024 onwards
recent_events <- get_group_events(
  "rladies-lagos",
  status = "past",
  date_after = "2024-01-01T00:00:00Z"
)
head(recent_events)
#> # A tibble: 3 × 23
#>   id        title   event_url created_time status date_time duration description
#>   <chr>     <chr>   <chr>     <chr>        <chr>  <chr>     <chr>    <chr>      
#> 1 300026594 Build … https://… 2024-03-26T… PAST   2024-04-… PT3H     "**🚀 Build…
#> 2 300356000 Intern… https://… 2024-04-11T… PAST   2024-04-… PT5H     "**Celebra…
#> 3 300027094 Intern… https://… 2024-03-26T… PAST   2024-04-… PT3H     "About thi…
#> # ℹ 15 more variables: group_id <chr>, group_name <chr>, group_urlname <chr>,
#> #   venues_id <list>, venues_name <list>, venues_address <list>,
#> #   venues_city <list>, venues_state <list>, venues_postal_code <list>,
#> #   venues_country <list>, venues_lat <list>, venues_lon <list>,
#> #   venues_venue_type <list>, rsvps_count <int>, featured_event_photo_url <chr>
```

Dates must be in ISO 8601 format with timezone (typically UTC:
`YYYY-MM-DDTHH:MM:SSZ`).

### Get Event Details

Retrieve detailed information about a specific event using its ID:

``` r
event <- get_event(id = "103349942")
event
#> 
#> ── Meetup Event ──
#> 
#> • ID: "103349942"
#> • Title: Ecosystem GIS & Community Building
#> • Status: "PAST"
#> • Date/Time: 2013-02-18T18:30:00-05:00
#> • Duration: PT2H
#> • RSVPs: 97
#> 
#> ── Group:
#> • Data Visualization DC ("data-visualization-dc")
#> 
#> ── Venue:
#> • Name: Browsermedia/NClud
#> • Location: Washington, DC, us
#> 
#> <https://www.meetup.com/data-visualization-dc/events/103349942/>
```

The [`print()`](https://rdrr.io/r/base/print.html) method displays a
formatted summary. Access individual fields with `$` notation:

``` r
event$title
event$dateTime
event$going
```

### Get Event RSVPs

See who has RSVP’d to an event:

``` r
rsvps <- get_event_rsvps(id = "103349942")
head(rsvps)
#> # A tibble: 6 × 9
#>   id        member_id member_name         member_bio member_url member_photo_url
#>   <chr>     <chr>     <chr>               <chr>      <chr>      <chr>           
#> 1 683104152 12251810  Sean Moore Gonzalez "Backgrou… https://w… https://secure-…
#> 2 683108312 482161    Harlan Harris       ""         https://w… https://secure-…
#> 3 683109202 6382386   Harnam Rai          ""         https://w… https://secure-…
#> 4 683114012 70383262  Dario Rivera        ""         https://w… https://secure-…
#> 5 683114892 8783792   Aaron M             ""         https://w… https://secure-…
#> 6 683118132 10948775  Sam                 ""         https://w… https://secure-…
#> # ℹ 3 more variables: member_organized_group_count <int>, guests_count <int>,
#> #   status <chr>
```

Each row represents one RSVP with:

- Member ID and name  
- RSVP response (yes, no, waitlist)  
- Number of guests  
- RSVP creation time

This is useful for analyzing attendance patterns or contacting attendees
(with appropriate permissions).

### Get Group Members

List members of a group:

``` r
members <- get_group_members("rladies-lagos", max_results = 10)
head(members)
#> # A tibble: 6 × 8
#>   id        name              member_url member_photo_url status role  join_time
#>   <chr>     <chr>             <chr>      <chr>            <chr>  <chr> <chr>    
#> 1 251470805 R-Ladies Global   https://w… https://secure-… LEADER ORGA… 2019-08-…
#> 2 225839690 EYITAYO ALIMI     https://w… https://secure-… LEADER COOR… 2019-08-…
#> 3 236466773 Adedamilola Adek… https://w… https://secure-… ACTIVE MEMB… 2019-08-…
#> 4 255806325 Helen             https://w… https://secure-… ACTIVE MEMB… 2019-08-…
#> 5 287781170 Alvin             https://w… https://secure-… ACTIVE MEMB… 2019-08-…
#> 6 266271010 ijeoma benson     https://w… NA               ACTIVE MEMB… 2019-08-…
#> # ℹ 1 more variable: last_access_time <chr>
```

Member data includes:

- Member ID and name  
- Join date  
- Member status (active, organizer, etc.)  
- Bio and profile URL

Note: Due to privacy settings, some member information may be limited.

### Search for Groups

Find groups matching a search term:

``` r
r_groups <- find_groups("R programming")
head(r_groups)
#> # A tibble: 6 × 14
#>   id       name       urlname city  state country   lat    lon memberships_count
#>   <chr>    <chr>      <chr>   <chr> <chr> <chr>   <dbl>  <dbl>             <int>
#> 1 38267718 R User Gr… r-nvsu  Mani… ""    ph       14.6 121.                   3
#> 2 24890872 Warwick R… warwic… Cove… "43"  gb       52.4  -1.56               918
#> 3 18574545 Johannesb… joburg… Joha… ""    za      -26.2  28.0               1587
#> 4 2906882  Birmingha… Birmin… Birm… "43"  gb       52.5  -1.9                810
#> 5 2727002  Vienna<-R  ViennaR Vien… ""    at       48.2  16.4                812
#> 6 38263588 R 程式交流組 R… r-prog… Hong… ""    hk       22.3 114.                   8
#> # ℹ 5 more variables: founded_date <dttm>, timezone <chr>, join_mode <chr>,
#> #   is_private <lgl>, membership_status <chr>
```

Search results include:

- Group name and URL name  
- Location  
- Member count  
- Description snippet

This is useful for discovering groups in your area or analyzing group
networks.

### Pagination and Rate Limits

The Meetup API limits how many results can be returned in a single
request. The `max_results` parameter controls pagination:

``` r
# Get up to 50 events (may require multiple API calls)
many_events <- get_group_events(
  "rladies-san-francisco",
  status = "past",
  max_results = 50
)

cli::cli_alert_info("Retrieved {nrow(many_events)} events")
#> ℹ Retrieved 50 events
```

meetupr automatically handles pagination behind the scenes. It makes
multiple API requests if needed and combines the results into a single
tibble.

The Meetup API rate limit is 500 requests per 60 seconds. meetupr
automatically throttles requests to stay under this limit. For large
batch operations, consider adding explicit delays:

``` r
# Process multiple groups with delays
groups <- c("rladies-nyc", "rladies-sf", "rladies-london")

events <- purrr::map_dfr(groups, \(x) {
  result <- get_group_events(x, max_results = 20)
  Sys.sleep(0.5)  # 500ms delay between requests
  result
})
```

## Pro Account Features

If you have a Meetup Pro account, you can access network-wide data using
the Pro functions. These functions require appropriate permissions and
will error if you don’t have Pro access.

### List All Pro Groups

``` r
# Get all groups in the R-Ladies network
pro_groups <- get_pro_groups("rladies")
head(pro_groups)
```

### Network-Wide Events

``` r
# Get upcoming events across all groups in network
upcoming <- get_pro_events("rladies", status = "upcoming")
head(upcoming)

# Get cancelled events
cancelled <- get_pro_events("rladies", status = "cancelled")
head(cancelled)
```

Pro functions return data for all groups in your network with a single
API call, which is more efficient than querying each group individually.

## Debug Mode

Sometimes issues arise due to misconfiguration or unexpected API
behavior. Enabling debug mode shows the exact GraphQL queries being sent
to the API.

``` r
local_meetupr_debug(1)
meetupr_sitrep()
#> 
#> ── meetupr Situation Report ────────────────────────────────────────────────────
#> 
#> ── Active Authentication Method ──
#> 
#> ✔ Authentication available
#> ℹ Active method: jwt
#> ℹ Client name: testclient
#> ✔ JWT token: Available and valid
#> ✔ JWT issuer: 1234567890
#> ✔ Client key: fake_c...
#> 
#> ── API Connectivity Test ──
#> 
#> ℹ Using GraphQL template: /home/runner/work/_temp/Library/meetupr/graphql/get_self.graphql
#> ℹ Using jwt token authentication
#> ✔ API Connection: Working
#> ℹ Authenticated as: R-Ladies Global
find_groups("R programming")
#> ℹ Using GraphQL template: /home/runner/work/_temp/Library/meetupr/graphql/find_groups.graphql
#> ℹ Using jwt token authentication
#> # A tibble: 200 × 14
#>    id       name     urlname city  state country   lat     lon memberships_count
#>    <chr>    <chr>    <chr>   <chr> <chr> <chr>   <dbl>   <dbl>             <int>
#>  1 38267718 R User … r-nvsu  Mani… ""    ph       14.6  121.                   3
#>  2 24890872 Warwick… warwic… Cove… "43"  gb       52.4   -1.56               918
#>  3 18574545 Johanne… joburg… Joha… ""    za      -26.2   28.0               1587
#>  4 2906882  Birming… Birmin… Birm… "43"  gb       52.5   -1.9                810
#>  5 2727002  Vienna<… ViennaR Vien… ""    at       48.2   16.4                812
#>  6 38263588 R 程式交流組… r-prog… Hong… ""    hk       22.3  114.                   8
#>  7 29568404 adminR:… adminR  Bern  ""    ch       47.0    7.44               581
#>  8 1696476  Denver … Denver… Denv… "CO"  us       39.8 -105.                1476
#>  9 21760043 R-Ladie… rladie… Buen… ""    ar      -34.6  -58.4               1966
#> 10 37281989 Cape To… cape-t… Cape… ""    za      -33.9   18.5                112
#> # ℹ 190 more rows
#> # ℹ 5 more variables: founded_date <dttm>, timezone <chr>, join_mode <chr>,
#> #   is_private <lgl>, membership_status <chr>
```

Debug output includes:

- The complete GraphQL query sent to the API  
- Variable values being passed  
- The raw JSON response

This is invaluable when queries fail unexpectedly or you’re unsure what
data is being returned.

To turn it off again, set it to `0`:

``` r
local_meetupr_debug(0)
meetupr_sitrep()
#> 
#> ── meetupr Situation Report ────────────────────────────────────────────────────
#> 
#> ── Active Authentication Method ──
#> 
#> ✔ Authentication available
#> ℹ Active method: jwt
#> ℹ Client name: testclient
#> ✔ JWT token: Available and valid
#> ✔ JWT issuer: 1234567890
#> ✔ Client key: fake_c...
#> 
#> ── API Connectivity Test ──
#> 
#> ✔ API Connection: Working
#> ℹ Authenticated as: R-Ladies Global
find_groups("R programming")
#> # A tibble: 200 × 14
#>    id       name     urlname city  state country   lat     lon memberships_count
#>    <chr>    <chr>    <chr>   <chr> <chr> <chr>   <dbl>   <dbl>             <int>
#>  1 38267718 R User … r-nvsu  Mani… ""    ph       14.6  121.                   3
#>  2 24890872 Warwick… warwic… Cove… "43"  gb       52.4   -1.56               918
#>  3 18574545 Johanne… joburg… Joha… ""    za      -26.2   28.0               1587
#>  4 2906882  Birming… Birmin… Birm… "43"  gb       52.5   -1.9                810
#>  5 2727002  Vienna<… ViennaR Vien… ""    at       48.2   16.4                812
#>  6 38263588 R 程式交流組… r-prog… Hong… ""    hk       22.3  114.                   8
#>  7 29568404 adminR:… adminR  Bern  ""    ch       47.0    7.44               581
#>  8 1696476  Denver … Denver… Denv… "CO"  us       39.8 -105.                1476
#>  9 21760043 R-Ladie… rladie… Buen… ""    ar      -34.6  -58.4               1966
#> 10 37281989 Cape To… cape-t… Cape… ""    za      -33.9   18.5                112
#> # ℹ 190 more rows
#> # ℹ 5 more variables: founded_date <dttm>, timezone <chr>, join_mode <chr>,
#> #   is_private <lgl>, membership_status <chr>
```

For persistent debugging across R sessions, set the environment variable
in your `.Renviron` file:

    MEETUPR_DEBUG=1

## Common Issues

### Authentication Errors

    Error: Authentication required

**Solution**: Run
[`meetupr_sitrep()`](http://rladies.org/meetupr/reference/meetupr_sitrep.md)
to diagnose the issue. Common causes include:

- No OAuth token cached (run
  [`meetupr_auth()`](http://rladies.org/meetupr/reference/meetupr_auth.md))  
- Expired token (re-authenticate with
  [`meetupr_auth()`](http://rladies.org/meetupr/reference/meetupr_auth.md))  
- Missing CI environment variables (check `meetupr_token` and
  `meetupr_token_file`)

### Multiple Token Warning

    Warning: Multiple tokens found in cache

**Solution**: Clear old tokens and re-authenticate:

``` r
meetupr_deauth()
meetupr_auth()
```

This happens when tokens from different OAuth applications accumulate in
your cache directory.

### Rate Limiting

    Error: Rate limit exceeded

**Solution**: The Meetup API limits you to 500 requests per 60 seconds.
If you hit this limit:

1.  Add delays between requests (`Sys.sleep(0.5)`)  
2.  Reduce `max_results` to minimize pagination  
3.  Cache results locally to avoid repeated queries

meetupr automatically throttles requests, but aggressive batch
operations may still hit limits.

### Group Not Found

    Error: Group not found

**Solution**: Verify the group URL name. The URL name is the part after
`meetup.com/` in the group’s URL. For example, for
`https://www.meetup.com/rladies-san-francisco/`, the URL name is
`rladies-san-francisco`.

## Next Steps

Now that you’re set up, explore more advanced features:

- **Custom GraphQL Queries**: See the [GraphQL
  vignette](http://rladies.org/meetupr/articles/graphql.md) to write
  custom queries and access fields not available through wrapper
  functions  
- **Custom OAuth Application**: See the [Advanced Authentication
  vignette](http://rladies.org/meetupr/articles/advanced-auth.md) for
  setting up your own OAuth app for higher rate limits  
- **API Schema Exploration**: See the [Inspecting the API
  vignette](http://rladies.org/meetupr/articles/introspection.md) for
  exploring the Meetup GraphQL schema
- **Data Analysis**: Combine meetupr with dplyr, ggplot2, and other
  tidyverse packages for analysis and visualization

For package updates and issues, visit the [GitHub
repository](https://github.com/rladies/meetupr).

## Getting Help

If you encounter issues:

1.  **Check
    [`meetupr_sitrep()`](http://rladies.org/meetupr/reference/meetupr_sitrep.md)**
    for authentication diagnostics  
2.  **Enable debug mode** (`local_meetupr_debug(1)`) to see API
    queries  
3.  **Search existing issues** on GitHub  
4.  **File a bug report** with a reproducible example (use
    `reprex::reprex()`)

When reporting issues, include:

- Output from
  [`meetupr_sitrep()`](http://rladies.org/meetupr/reference/meetupr_sitrep.md)  
- Debug output (if relevant)  
- A minimal reproducible example  
- Your R and package versions
  ([`sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html))

This helps maintainers diagnose and fix problems quickly.
