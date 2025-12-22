# Create and Configure a Meetup API Request

This function prepares and configures an HTTP request for interacting
with the Meetup API. It handles both interactive and non-interactive
OAuth flows. In interactive mode, it uses OAuth authorization code flow.
In non-interactive mode (CI/CD), it loads cached tokens.

## Usage

``` r
meetupr_req(rate_limit = 500/60, cache = TRUE, ...)
```

## Arguments

- rate_limit:

  A numeric value specifying the maximum number of requests per second.
  Defaults to `500 / 60` (500 requests per 60 seconds).

- cache:

  A logical value indicating whether to cache the OAuth token on disk.
  Defaults to `TRUE`.

- ...:

  Additional arguments passed to
  [`meetupr_client()`](http://rladies.org/meetupr/reference/meetupr_client.md)
  for setting up the OAuth client.

## Value

A `httr2` request object pre-configured to interact with the Meetup API.

## Details

This function constructs an HTTP POST request directed to the Meetup API
and applies appropriate OAuth authentication. The function automatically
detects whether it's running in an interactive or non-interactive
context:

- **Interactive**: Uses OAuth authorization code flow with browser
  redirect

- **Non-interactive**: Loads pre-cached token from CI environment or
  disk

## Examples

``` r
if (FALSE) { # \dontrun{
req <- meetupr_req(cache = TRUE)

req <- meetupr_req(
  cache = FALSE,
  client_key = "your_client_key",
  client_secret = "your_client_secret"
)
} # }
```
