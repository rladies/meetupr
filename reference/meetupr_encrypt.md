# CI Authentication with Encrypted Token Rotation

Manage Meetup API authentication in CI environments using encrypted
tokens that auto-refresh when expired.

## Usage

``` r
meetupr_encrypt_setup(
  path = ".meetupr.rds",
  password = NULL,
  client_name = get_client_name(),
  ...
)

meetupr_encrypt_load(
  path = get_encrypted_path(),
  client_name = get_client_name(),
  password = meetupr_key_get("encrypt_pwd", client_name = client_name),
  ...
)

get_encrypted_path(client_name = get_client_name())
```

## Arguments

- path:

  Path to encrypted token file. Default `".meetupr.rds"`.

- password:

  Encryption password. If NULL, generates random password.

- client_name:

  A string representing the name of the client. By default, it is set to
  `"meetupr"` and retrieved from the `MEETUPR_CLIENT_NAME` environment
  variable.

- ...:

  Additional arguments to
  [`meetupr_client()`](http://rladies.org/meetupr/reference/meetupr_client.md).

## Value

- `meetupr_encrypt_setup()`: Encryption password (invisibly)

- `meetupr_encrypt_load()`: httr2_token object

## Details

Setup: Run
[`meetupr_auth()`](http://rladies.org/meetupr/reference/meetupr_auth.md),
then `meetupr_encrypt_setup()`. Commit the encrypted file and add
password to CI secrets as `meetupr_encrypt_pwd`.

`meetupr_encrypt_load()` checks token expiration and refreshes only when
needed, saving the rotated token back to the encrypted file.

## Functions

- `meetupr_encrypt_setup()`: Setup encrypted token for CI

- `meetupr_encrypt_load()`: Load and refresh encrypted token

- `get_encrypted_path()`: Get encrypted token path

## Examples

``` r
if (FALSE) { # \dontrun{
meetupr_auth()
password <- meetupr_encrypt_setup()

# In CI
token <- meetupr_encrypt_load()
} # }
```
