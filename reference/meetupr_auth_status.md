# Check all authentication methods and return details

Check all authentication methods and return details

Logical checker

## Usage

``` r
meetupr_auth_status(client_name = get_client_name(), silent = FALSE)

has_auth(client_name = get_client_name())
```

## Arguments

- client_name:

  A string representing the name of the client. By default, it is set to
  `"meetupr"` and retrieved from the `MEETUPR_CLIENT_NAME` environment
  variable.

- silent:

  logical, suppress messages if TRUE

## Value

list with logicals and details for each method

## Functions

- `has_auth()`: Check if any authentication method is available

## Examples

``` r
if (FALSE) { # \dontrun{
# Check detailed authentication status with default client name
status_details <- meetupr_auth_status()

# Check detailed authentication status with a specific client name
status_details <- meetupr_auth_status(client_name = "custom_client")

# Suppress output messages
status_details <- meetupr_auth_status(silent = TRUE)
} # }
```
