# Get detailed information about a Meetup group

Get detailed information about a Meetup group

## Usage

``` r
get_group(urlname, asis = FALSE)
```

## Arguments

- urlname:

  The URL name of the Meetup group (e.g., "rladies-lagos")

- asis:

  Return the raw API response as-is without processing

## Value

A list containing detailed information about the Meetup group

## Examples

``` r
get_group("rladies-lagos")
#> 
#> ── Meetup Group: ──
#> 
#> • Name: R-Ladies Lagos
#> • URL: rladies-lagos
#> • Link: https://www.meetup.com/rladies-lagos
#> • Location: Lagos, ng
#> • Timezone: Africa/Lagos
#> • Founded: August 16, 2019
#> 
#> ── Statistics: 
#> • Members: 890
#> • Total Events: 13
#> 
#> ── Organizer: 
#> • Name: R-Ladies Global
#> • Category: Technology
#> 
#> ── Description: 
#> R-Ladies is a world-wide organization to promote gender diversity in the R
#> community. R-Ladies welcomes members of all R proficiency levels, whether
#> you're a new or aspiring R user, or an experienc...
```
