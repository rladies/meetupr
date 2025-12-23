$ # meetupr NEWS

## meetupr 0.3.1

- Added JWT authentication support for the Meetup API.
- Added experimental support for encrypting stored tokens for CI/CD
- Fixed bug that made only "node" response format work,
  more data is now available from the API.
- Updated vignettes to reflect new authentication methods.
- adds the option to return data from the API "asis", without any processing by the package.

## meetupr 0.3.0

- Updated to use new Meetup schema from February 2025
- Switched to using the `httr2` package for making API requests instead of `httr`.
- Uses s7 classes for internal query objects instead of lists.
- Added functions:
  - `meetupr_query()` - Run custom queries against the Meetup API.
  - `meetupr_sitrep()` - Get information about your API connection status.
  - `meetupr_schema()` - Get information about the Meetup API query options.
- added deprecation warnings for `get_meetupr_comments()`.
- Added new vignettes
- Expanded test suite
- Uses vcr in examples and vignettes in addition to tests


## meetupr 0.2.0

### Breaking changes

* All mentions of and arguments related to API keys have been removed as the Meetup API no longer supports authentication with an API key.

### New features

* Added automatic rate limiting based on the response headers.
* Added support for non-interactive use.
* Added functions for getting pro events and groups.

### Internals

* Renamed `api_method` to `api_path` in internal function, `.fetch_results()`, as it's less confusing.

## meetupr 0.2.99.9000 (development)

- Development snapshot: GraphQL groundwork and CI updates.
- Added initial GraphQL queries and plumbing to support flattening
  nested lists into tibbles; set up `gh`-backed GraphQL helpers and
  cleaned up developer warnings. (commit: 2021-12-28)

## meetupr 0.2.3

- Documentation and packaging housekeeping:
  - Updated `DESCRIPTION` and README.
  - Added/updated pkgdown configuration and vignette metadata.
  - Added Ben as contributor. (commit: 2020-10-16)

## meetupr 0.2.1

- Bug fixes and internal improvements to event/member handling:
  - Improve handling of attendee/member fields (bio, rsvp_response).
  - Fix membership/joined date acquisition.
  - Improve HTTP 400 error messages so failing request URLs are
    easier to inspect. (commit: 2020-06-30)

## meetupr 0.0.2

- Small fixes and contributor updates; bumped version. Rick Pack was
  added as a contributor and the package improved messaging for
  invalid API calls. (commit: 2020-06-30)

## meetupr 0.1.1
* Added `get_event_rsvps()` function.  Contribution by Michael Beigelmacher: https://github.com/rladies/meetupr/pull/19

## meetupr 0.1.0

* Added `NEWS.md` file.

### BREAKING CHANGE

Updated `get_events()`, `get_boards()`, and `get_group_members()` to output a tibble with summarised information. The raw content previously output by these functions can be found in the `resource` column of each output tibble.  

### BREAKING CHANGES
Changed the name of `get_meetupr_attendees()` and `get_meetupr_comments()` to `get_comments()` and `get_attendees()` for distinction (all other `get_*` functions get something about a group, not a specific event from that group).  Also updated the output of these functions from lists to tibbles. The raw content previously output by these functions can be found in the `resource` column of each output tibble. 

* Officially deprecated the `get_meetupr_attendees()` and `get_meetupr_comments()` functions.
* Added a bunch of fields to the `get_events()` output.
* Added ability to pass in a vector of statuses for `event_status` in addition to a single string.
* Added `find_groups()` function to get list of groups using text-based search.
* Added short vignette to demonstrate the use of the new `find_groups()` function.
* Added `...` option to `.quick_fetch()` and `.fetch_results()` (in `internals.R`) to use any parameter in the `GET` request. 
* Removed `LazyData = TRUE` from DESCRIPTION file (this is not needed because there is no dataset shipped within the package).
* Added `.get_api_key()` internal function which is used inside `.fetch_results()` so now if `api_key = NULL` it will automatically populate that variable with the `MEETUP_KEY` environment variable, if available.
* Added a printout of how many results are returned for a query so users will understand why it's taking a while for the function to finish executing.
* Renamed `api_params` to `api_method` in internal function, `.fetch_results()`, since that's the official name for what that argument represents.
* Added several new columns to the `get_group_members()` result tibble (e.g. bio, city, country, lat, lon, etc)
* Added a References section in the R docs for each function which includes a link to the official Meetup API documentation for each endpoint.


## meetupr 0.0.1

* Initial release.
