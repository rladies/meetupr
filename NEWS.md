# meetupr 0.1.0

* Updated `get_events()`, `get_boards()`, and `get_members()` to output a tibble with summarised information. The raw content previously output by these functions can be found in the `resource` column of each output tibble.  
* Changed the name of `get_meetup_attendees()` and `get_meetup_comments()` to `get_comments()` and `get_attendees()`, also updated the output of these functions to tibbles.
* Added short vignette to demonstrate the use of the new `get_groups()`. function.
* Added function get_groups to get list of groups using text-based search
* Added ... option to `.quick_fetch()` and `.fetch_results()` (internals.R) to use any parameter in the GET request 
* Removed `LazyData = TRUE` from DESCRIPTION file (this is not needed becasue there is no dataset shipped within the package)
* Added `NEWS.md` file

# meetupr 0.0.1

* Initial release.
