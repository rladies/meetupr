# Manage API Keys via Environment Variables

Store and retrieve credentials using environment variables.

## Usage

``` r
meetupr_key_set(key, value, client_name = get_client_name())

meetupr_key_get(key, client_name = get_client_name(), error = TRUE)

meetupr_key_delete(key, client_name = get_client_name())
```

## Arguments

- key:

  Key name: `"client_key"`, `"client_secret"`, `"encrypt_path"`,
  `"encrypt_pwd"`, `"jwt_token"` or `"jwt_issuer"`.

- value:

  Value to be stored.

- client_name:

  A string representing the name of the client. By default, it is set to
  `"meetupr"` and retrieved from the `MEETUPR_CLIENT_NAME` environment
  variable.

- error:

  Throw error if key not found. Default TRUE.

## Value

`meetupr_key_set()` and `meetupr_key_delete()` return NULL (invisibly),
and `meetupr_key_get()` returns a character string or NA.

## Details

This is an alias of `meetupr_credentials` with hyphenated envvar names.
Credentials are stored as environment variables with the pattern
`{client_name}-{key}` (e.g., `meetupr-client_key`).

- `client_key`: OAuth client ID

- `client_secret`: OAuth client secret

- `encrypt_path`: Path to encrypted token file

- `encrypt_pwd`: Password for encrypted token

- `jwt_token`: JWT token for service account authentication

- `jwt_issuer`: JWT issuer, Meetup account number

## Functions

- `meetupr_key_set()`: Store a key in environment variables

- `meetupr_key_get()`: Retrieve a key from environment variables

- `meetupr_key_delete()`: Delete a key from environment variables
