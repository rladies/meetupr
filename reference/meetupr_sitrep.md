# Show meetupr authentication status

This function checks the authentication status for the Meetup API. It
provides feedback on whether credentials are configured correctly, tests
API connectivity, and shows available authentication methods.

## Usage

``` r
meetupr_sitrep()
```

## Value

Invisibly returns a list with authentication status details.

## Examples

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
#> ! API Connection: Unexpected response
```
