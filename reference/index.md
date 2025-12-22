# Package index

## Authentication

Functions for authenticating and verification

- [`meetupr_sitrep()`](http://rladies.org/meetupr/reference/meetupr_sitrep.md)
  : Show meetupr authentication status
- [`meetupr_auth()`](http://rladies.org/meetupr/reference/meetupr_auth.md)
  : Authenticate and return the current user
- [`meetupr_auth_status()`](http://rladies.org/meetupr/reference/meetupr_auth_status.md)
  [`has_auth()`](http://rladies.org/meetupr/reference/meetupr_auth_status.md)
  : Check all authentication methods and return details
- [`meetupr_deauth()`](http://rladies.org/meetupr/reference/meetupr_deauth.md)
  : Deauthorize and remove cached authentication
- [`meetupr_client()`](http://rladies.org/meetupr/reference/meetupr_client.md)
  : Create a Meetup OAuth client
- [`meetupr_key_set()`](http://rladies.org/meetupr/reference/meetupr_credentials.md)
  [`meetupr_key_get()`](http://rladies.org/meetupr/reference/meetupr_credentials.md)
  [`meetupr_key_delete()`](http://rladies.org/meetupr/reference/meetupr_credentials.md)
  : Manage API Keys via Environment Variables
- [`use_gha_jwt_token()`](http://rladies.org/meetupr/reference/use_gha.md)
  [`use_gha_encrypted_token()`](http://rladies.org/meetupr/reference/use_gha.md)
  : GitHub Actions workflow helpers

## Retrieving data and working with data

Functions for retrieving data

- [`get_client_name()`](http://rladies.org/meetupr/reference/get_client_name.md)
  : Get Meetup OAuth Client Name
- [`get_event()`](http://rladies.org/meetupr/reference/get_event.md) :
  Get information for a specified event
- [`get_event_comments()`](http://rladies.org/meetupr/reference/get_event_comments.md)
  : Get the comments for a specified event
- [`get_event_rsvps()`](http://rladies.org/meetupr/reference/get_event_rsvps.md)
  : Get the RSVPs for a specified event
- [`get_group()`](http://rladies.org/meetupr/reference/get_group.md) :
  Get detailed information about a Meetup group
- [`get_group_events()`](http://rladies.org/meetupr/reference/get_group_events.md)
  : Get the events from a meetup group
- [`get_group_members()`](http://rladies.org/meetupr/reference/get_group_members.md)
  : Get the members from a meetup group
- [`get_pro_groups()`](http://rladies.org/meetupr/reference/get_pro.md)
  [`get_pro_events()`](http://rladies.org/meetupr/reference/get_pro.md)
  : Retrieve information about Meetup Pro networks, including groups and
  events.
- [`get_self()`](http://rladies.org/meetupr/reference/get_self.md) : Get
  information about the authenticated user
- [`meetupr_encrypt_setup()`](http://rladies.org/meetupr/reference/meetupr_encrypt.md)
  [`meetupr_encrypt_load()`](http://rladies.org/meetupr/reference/meetupr_encrypt.md)
  [`get_encrypted_path()`](http://rladies.org/meetupr/reference/meetupr_encrypt.md)
  : CI Authentication with Encrypted Token Rotation
- [`find_groups()`](http://rladies.org/meetupr/reference/find_groups.md)
  : Find groups using text-based search
- [`find_topics()`](http://rladies.org/meetupr/reference/find_topics.md)
  : Find topics on Meetup

## Query functions

Functions enabling querying of data

- [`meetupr_req()`](http://rladies.org/meetupr/reference/meetupr_req.md)
  : Create and Configure a Meetup API Request
- [`meetupr_query()`](http://rladies.org/meetupr/reference/meetupr_query.md)
  : Execute GraphQL query

## Introspection

Functions for introspection

- [`meetupr_schema()`](http://rladies.org/meetupr/reference/meetupr_schema.md)
  : Introspect the Meetup GraphQL API schema
- [`meetupr_schema_mutations()`](http://rladies.org/meetupr/reference/meetupr_schema_mutations.md)
  : Explore available mutations in the Meetup GraphQL API
- [`meetupr_schema_queries()`](http://rladies.org/meetupr/reference/meetupr_schema_queries.md)
  : Explore available query fields in the Meetup GraphQL API
- [`meetupr_schema_search()`](http://rladies.org/meetupr/reference/meetupr_schema_search.md)
  : Search for types in the Meetup GraphQL API schema
- [`meetupr_schema_type()`](http://rladies.org/meetupr/reference/meetupr_schema_type.md)
  : Get fields for a specific type in the Meetup GraphQL API schema
- [`local_meetupr_debug()`](http://rladies.org/meetupr/reference/local_meetupr_debug.md)
  : Temporarily enable debug mode
