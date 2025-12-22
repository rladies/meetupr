# meetupr Package - AI Coding Agent Instructions

## Architecture Overview

**meetupr** is an R package providing a GraphQL client for the Meetup.com API. The architecture uses a template-based query system with S7 OOP for pagination and OAuth2 authentication via httr2.

### Core Components

- **GraphQL Layer** (`R/graphql-*.R`): Template-based query execution with S7 classes for pagination
- **Authentication** (`R/auth.R`, `R/credentials.R`): OAuth2 flow with credential storage
- **API Interface** (`R/api.R`): Request building and error handling
- **User Functions** (`R/get-*.R`, `R/find.R`): High-level wrappers for common queries

### Data Flow

1. User calls wrapper function (e.g., `get_group_events()`)
2. Function creates `meetupr_template` S7 object with query file path and extraction paths
3. `execute()` generic reads `.graphql` template from `inst/graphql/`
4. Template interpolation handles `extra_graphql` parameter and cursor-based pagination
5. `meetupr_query()` builds request → `meetupr_req()` adds OAuth → `httr2::req_perform()`
6. Response extraction via dot-path plucking (e.g., `"data.event.rsvps.edges"`)
7. `process_graphql_list()` flattens nested structures to tibbles

## Critical Developer Workflows

### Testing with vcr

Tests use **vcr** package to record/replay HTTP interactions. Always follow this pattern:

```r
describe("function()", {
  it("does something", {
    mock_if_no_auth()  # Sets fake env vars when not authenticated
    vcr::local_cassette("cassette_name")  # Loads YAML from inst/_vcr/
    result <- get_something()
    # assertions
  })
})
```

Cassettes in `inst/_vcr/` are committed. To re-record, delete YAML and run tests authenticated.

### Testing with Mock Authentication

The `mock_if_no_auth()` function provides mock authentication for
testing using `withr` for automatic cleanup. 


Use `local_mocked_bindings()` from testthat to mock functions, using the `.package` argument to specify which package the functions to mock are from (this is not necessary for functions from the current package).
Do no mock base R functions.

# Coverage Testing

Run `covr::package_coverage()` to see line-level coverage. Focus areas with <100%:


### Building and Documenting

```r
devtools::document()     # Generates man/*.Rd from roxygen2 comments
devtools::load_all()     # Simulates package installation
devtools::test()         # Runs testthat suite
devtools::check()        # R CMD check (required before CRAN submission)
```

Roxygen templates in `man-roxygen/` (e.g., `@template client_name`) reduce duplication.

## Code Style Guidelines

### Line Length

**Keep all lines to 80 characters maximum.** This follows lintr standards and ensures readability in split-screen editors and code review tools.

```r
# ❌ BAD: Line exceeds 80 characters
very_long_function_name <- function(parameter_one, parameter_two, parameter_three, parameter_four) {
  result <- some_other_long_function(parameter_one, parameter_two, parameter_three)
  return(result)
}

# ✅ GOOD: Break long lines
very_long_function_name <- function(
  parameter_one,
  parameter_two,
  parameter_three,
  parameter_four
) {
  result <- some_other_long_function(
    parameter_one,
    parameter_two,
    parameter_three
  )
  result
}

# ✅ GOOD: Use pipe for long chains
result <- data |>
  filter(status == "active") |>
  group_by(category) |>
  summarise(total = sum(count))

# ❌ BAD: Long pipe chain on one line
result <- data |> filter(status == "active") |> group_by(category) |> summarise(total = sum(count))
```

**Breaking function calls:**
- One argument per line when exceeding 80 characters
- Closing parenthesis on its own line, aligned with function name
- For short argument lists that fit, keep on one line

**Breaking pipes:**
- One operation per line
- Pipe operator `|>` at end of line, not start of next line

**Breaking strings:**
- Use `paste0()` or `glue::glue()` for multi-line strings, use `sprintf()` for formatted strings.

**Breaking conditionals:**
```r
# ✅ GOOD: Break long conditions
if (
  condition_one &&
  condition_two &&
  condition_three
) {
  do_something()
}

# ✅ GOOD: Extract to variable
has_valid_state <- condition_one &&
  condition_two &&
  condition_three

if (has_valid_state) {
  do_something()
}
```

Run `lintr::lint_package()` to check compliance. The package uses:
- `line_length_linter(80)` to enforce this limit
- `object_length_linter(30)` for variable names
- `cyclocomp_linter(15)` for function complexity

### Comments

**Minimize code comments.** Write self-documenting code with clear variable and function names. Only add comments to explain **why** something is done, not **what** it does.

```r
# ❌ BAD: Explaining what the code does
# Loop through each event and extract the ID
event_ids <- lapply(events, function(e) e$id)

# ✅ GOOD: Self-documenting code, no comment needed
event_ids <- lapply(events, function(e) e$id)

# ✅ GOOD: Comment explains why, not what
# Meetup API returns duplicates when events span multiple groups
# See: https://github.com/meetup/api/issues/123
event_ids <- unique(lapply(events, function(e) e$id))
```

Appropriate use cases for comments:
- **API quirks**: Unexpected behavior from external services
- **Workarounds**: Temporary fixes for upstream bugs
- **Non-obvious design decisions**: Why this approach vs. alternatives
- **Performance optimizations**: Why code is structured for speed

Do not comment:
- Variable assignments
- Control flow (if/else, loops)
- Function calls
- Data transformations that are clear from the code

Rely on **roxygen2 documentation** for function-level explanations. Code comments are for maintainers, roxygen is for users.

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
meetupr_template <- S7::new_class(
  properties = list(
    template = S7::class_character,       # Query filename
    edges_path = S7::class_character,     # "data.group.events.edges"
    page_info_path = S7::class_character, # "data.group.events.pageInfo"
    process_data = S7::class_function     # Flattening function
  )
)

execute <- S7::new_generic("execute", "object")
S7::method(execute, meetupr_template) <- function(object, ...) { ... }
```

### Authentication Patterns

- **Interactive**: User calls any function → OAuth prompt → token cached in `httr2::oauth_cache_path()/meetupr/`
- **CI Mode**: `meetupr_encrypt_setup()` base64-encodes token → store in secrets → `meetupr_encrypt_load()` decodes in workflow


### Error Handling

GraphQL errors are structured responses (not HTTP errors). Pattern in `meetupr_query()`:

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
- **vcr**: Test fixture management for HTTP interactions
- **cli**: Styled console output (use `cli::cli_alert_*` not `message()`)

### Meetup GraphQL API

Base URL: `https://api.meetup.com/gql-ext` (override with `MEETUP_API_URL` env var)

Key quirks:
- Pagination uses cursor-based system (not offset/limit)
- Some fields Pro-only (e.g., `UPCOMING` status for events)
- Comments endpoint removed from schema (see `get_event_comments()` for deprecation pattern)
- Introspection available via `meetupr_schema()` to explore schema

### Debug Mode

Set `MEETUPR_DEBUG=TRUE` to log GraphQL requests. Check with `check_debug_mode()`.

## File Patterns to Know

- `R/zzz.R`: Package startup message and `.onLoad()` hooks
- `data-raw/built-ins.R`: Generates `R/sysdata.rda` with fallback OAuth credentials
- `inst/WORDLIST`: Spell-check exceptions for R CMD check
- `tests/testthat/helper.R`: Defines `event_id` constant and vcr configuration

## Testing Patterns for 100% Coverage

1. **Mock external system interactions**: clipboard, httr2 OAuth cache paths
2. **Test error branches**: missing keys, multiple tokens, network failures
3. **Cover CLI output paths**: silent vs. verbose modes, different alert types
4. **Deprecated functions**: Ensure warnings are tested even if functionality is a no-op

When writing new tests:
- Use `withr::local_*` for temporary state changes (envvars, tempdir, mocked bindings)
- Verify CLI messages with `expect_message()` / `expect_warning()`
- Test both success and failure paths for any external call
- do not mock base R functions
- Use `vcr::use_cassette()` to record HTTP interactions for reproducible tests
- do not add testthat:: namespacing, as testthat is loaded automatically in tests
