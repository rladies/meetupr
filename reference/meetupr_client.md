# Create a Meetup OAuth client

This function creates an httr2 OAuth client for the Meetup API. It uses
environment variables or built-in credentials as fallback.

## Usage

``` r
meetupr_client(
  client_key = NULL,
  client_secret = NULL,
  client_name = get_client_name(),
  ...
)
```

## Arguments

- client_key:

  Optional. The OAuth client ID.

- client_secret:

  Optional. The OAuth client secret.

- client_name:

  A string representing the name of the client. By default, it is set to
  `"meetupr"` and retrieved from the `MEETUPR_CLIENT_NAME` environment
  variable.

- ...:

  Additional arguments passed to
  [`httr2::oauth_client()`](https://httr2.r-lib.org/reference/oauth_client.html).

## Value

An httr2 OAuth client object.
