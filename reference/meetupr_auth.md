# Authenticate and return the current user

Attempts to retrieve information about the currently authenticated user.
On success a message is emitted and the user object is returned. On
failure a message is shown and `NULL` is returned.

## Usage

``` r
meetupr_auth(client_name = get_client_name())
```

## Arguments

- client_name:

  OAuth client name

## Value

A user list (invisibly) or `NULL` on failure
