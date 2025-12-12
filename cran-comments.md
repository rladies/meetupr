## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release. 
* Note explanation:
    * Possibly misspelled GraphQL (24:59): this is correct official spelling
* url https://www.meetup.com/api/oauth/list/ returns 500 when not logged into Meetup, but when logged in shows a list of all OAuth apps created by the user.
* `meetupr:::mock_if_no_auth()` is an internal function used to mock Meetup API calls when no authentication is provided.
    - it is necessary for vcr to work properly in examples and vignettes
    - in examples this is wrapped inside `\dontshow()` to avoid confusing users
    - in vignettes it is inside a setup chunk with `include = FALSE`
* Passes on github actions:
    - { os: macos-latest, r: "release" }
    - { os: windows-latest, r: "release" }
    - { os: ubuntu-latest, r: "release" }
    - { os: ubuntu-latest, r: "oldrel-1" }
