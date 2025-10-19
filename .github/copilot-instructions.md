# meetupr Package - AI Coding Agent Instructions

## Architecture Overview

**meetupr** is an R package providing a GraphQL client for the Meetup.com API. The architecture uses a template-based query system with S7 OOP for pagination and OAuth2 authentication via httr2.

### Core Components

- **GraphQL Layer** (`R/graphql-*.R`): Template-based query execution with S7 classes for pagination
- **Authentication** (`R/auth.R`, `R/credentials.R`): OAuth2 flow with keyring-based credential storage
- **API Interface** (`R/api.R`): Request building and error handling
- **User Functions** (`R/get-*.R`, `R/find.R`): High-level wrappers for common queries

### Data Flow

1. User calls wrapper function (e.g., `get_group_events()`)
2. Function creates `meetup_template` S7 object with query file path and extraction paths
3. `execute()` generic reads `.graphql` template from `inst/graphql/`
4. Template interpolation handles `extra_graphql` parameter and cursor-based pagination
5. `meetup_query()` builds request → `meetup_req()` adds OAuth → `httr2::req_perform()`
6. Response extraction via dot-path plucking (e.g., `"data.event.rsvps.edges"`)
7. `process_graphql_list()` flattens nested structures to tibbles

## Critical Developer Workflows

### Testing with vcr

Tests use **vcr** package to record/replay HTTP interactions. Always follow this pattern:

```r
test_that("description", {
  mock_if_no_auth()  # Sets fake env vars when not authenticated
  vcr::local_cassette("cassette_name")  # Loads YAML from inst/_vcr/
  result <- get_something()
  # assertions
})
```

Cassettes in `inst/_vcr/` are committed. To re-record, delete YAML and run tests authenticated.

### Coverage Testing

Run `covr::package_coverage()` to see line-level coverage. Focus areas with <100%:
- **`R/auth.R`**: Branch coverage for keyring vs env backend, clipboard availability
- **`R/get-event.R`**: Error paths in `get_event_comments()` (deprecated endpoint)

Use `local_mocked_bindings()` from withr to mock functions like `keyring::*`, `clipr::*`, `httr2::oauth_cache_path()`.

### Building and Documenting

```r
devtools::document()     # Generates man/*.Rd from roxygen2 comments
devtools::load_all()     # Simulates package installation
devtools::test()         # Runs testthat suite
devtools::check()        # R CMD check (required before CRAN submission)
```

Roxygen templates in `man-roxygen/` (e.g., `@template client_name`) reduce duplication.

## Project Conventions

### GraphQL Query Templates

Queries live in `inst/graphql/*.graphql`. Use **placeholder syntax** for dynamic fields:

```graphql
query GetEvent($id: ID!) {
  event(id: $id) {
    id
    title
    << extra_graphql >>  # Replaced by glue::glue_data()
  }
}
```

The `<< extra_graphql >>` marker allows users to inject custom fields via function parameters.

### S7 Generic System

Pagination uses S7 (not S3/S4). Key pattern in `R/graphql-builders.R`:

```r
meetup_template <- S7::new_class(
  properties = list(
    template = S7::class_character,       # Query filename
    edges_path = S7::class_character,     # "data.group.events.edges"
    page_info_path = S7::class_character, # "data.group.events.pageInfo"
    process_data = S7::class_function     # Flattening function
  )
)

execute <- S7::new_generic("execute", "object")
S7::method(execute, meetup_template) <- function(object, ...) { ... }
```

### Authentication Patterns

- **Interactive**: User calls any function → OAuth prompt → token cached in `httr2::oauth_cache_path()/meetupr/`
- **CI Mode**: `meetup_ci_setup()` base64-encodes token → store in secrets → `meetup_ci_load()` decodes in workflow
- **Credentials**: Prefer system keyring via `meetup_key_set/get()`. Falls back to env vars (`meetupr:*`) when keyring unavailable

### Error Handling

GraphQL errors are structured responses (not HTTP errors). Pattern in `meetup_query()`:

```r
resp <- httr2::req_perform(req) |> httr2::resp_body_json()
if (!is.null(resp$errors)) {
  cli::cli_abort(sapply(resp$errors, function(e) e$message))
}
```

HTTP errors caught by `httr2::req_error(body = handle_api_error)`.

### Data Transformation

GraphQL returns nested JSON. Extractors in `R/graphql-extractors.R` convert to tibbles:
- `process_graphql_list()`: Main flattening function using `rlist::list.stack()`
- Date fields processed by `process_datetime_fields()` to POSIXct
- Country codes expanded via `countrycode` package
- List columns created for one-to-many relationships (use `handle_multiples` parameter)

## Integration Points

### External Dependencies

- **httr2**: OAuth client, request building, throttling (500 req/60s default)
- **keyring**: Cross-platform credential storage (macOS Keychain, Windows Credential Manager, etc.)
- **vcr**: Test fixture management for HTTP interactions
- **cli**: Styled console output (use `cli::cli_alert_*` not `message()`)

### Meetup GraphQL API

Base URL: `https://api.meetup.com/gql-ext` (override with `MEETUP_API_URL` env var)

Key quirks:
- Pagination uses cursor-based system (not offset/limit)
- Some fields Pro-only (e.g., `UPCOMING` status for events)
- Comments endpoint removed from schema (see `get_event_comments()` for deprecation pattern)
- Introspection available via `meetup_schema()` to explore schema

### Debug Mode

Set `MEETUPR_DEBUG=1` to log GraphQL requests. Check with `check_debug_mode()`. Uses `local_meetupr_debug()` in tests.

## File Patterns to Know

- `R/zzz.R`: Package startup message and `.onLoad()` hooks
- `data-raw/built-ins.R`: Generates `R/sysdata.rda` with fallback OAuth credentials
- `inst/WORDLIST`: Spell-check exceptions for R CMD check
- `tests/testthat/helper.R`: Defines `event_id` constant and vcr configuration

## Testing Patterns for 100% Coverage

1. **Mock external system interactions**: keyring, clipboard, httr2 OAuth cache paths
2. **Test error branches**: missing keys, multiple tokens, network failures
3. **Cover CLI output paths**: silent vs. verbose modes, different alert types
4. **Deprecated functions**: Ensure warnings are tested even if functionality is a no-op

When writing new tests:
- Use `withr::local_*` for temporary state changes (envvars, tempdir, mocked bindings)
- Verify CLI messages with `expect_message()` / `expect_warning()`
- Test both success and failure paths for any external call
