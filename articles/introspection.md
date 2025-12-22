# Meetup API Schema Introspection

``` r
library(meetupr)
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
```

## Introduction to GraphQL Introspection

GraphQL APIs are self-documenting through a feature called
**introspection**. This means you can query the API to learn about its
own structure: what types exist, what fields are available on each type,
and what operations you can perform.

The meetupr package exposes this introspection capability through a
family of `meetupr_schema_*` functions. These functions help you
discover the full capabilities of the Meetup API beyond what the
package’s built-in wrapper functions provide.

### Why Use Introspection?

Introspection is valuable when you need to:

- **Discover new fields**: Meetup may add new data fields that aren’t
  yet wrapped in meetupr functions  
- **Build custom queries**: Access specific field combinations not
  available through standard wrappers  
- **Understand relationships**: See how types connect (e.g., how Events
  relate to Groups and Venues)  
- **Check deprecations**: Identify deprecated fields before they’re
  removed  
- **Explore Pro features**: Discover fields only available with Meetup
  Pro accounts

### How GraphQL Schema Works

A GraphQL schema defines:

1.  **Types**: Data structures like `Event`, `Group`, `Member` (think of
    these as classes or tables)  
2.  **Fields**: Properties on each type (like `title`, `dateTime`,
    `memberCount`)  
3.  **Queries**: Entry points for reading data (like
    `event(id: "123")`)  
4.  **Mutations**: Operations for modifying data (like `createEvent`,
    `updateGroup`)

The schema also specifies: - Field types (String, Int, Boolean, or
custom types)  
- Required vs. optional fields  
- Arguments each field accepts  
- Relationships between types (one-to-one, one-to-many)

## Recommended Exploration Workflow

1.  **Cache the schema**: `schema <- meetupr_schema()`  
2.  **Browse queries**: `meetupr_schema_queries(schema)` to see entry
    points  
3.  **Search for types**: `meetupr_schema_search("topic", schema)` to
    find relevant types  
4.  **Examine type fields**: `meetupr_schema_type("TypeName", schema)`
    for details  
5.  **Check related types**: Follow object-type fields to discover
    relationships  
6.  **Build query**: Combine fields based on introspection data  
7.  **Test in Playground**: Validate query at
    <https://www.meetup.com/api/playground>  
8.  **Execute in R**:
    [`meetupr_query()`](http://rladies.org/meetupr/reference/meetupr_query.md)
    with your final query  
9.  **Extract data**: Use purrr or dplyr to transform nested results

This systematic approach helps you efficiently discover and utilize the
full Meetup API schema for custom data extraction beyond the package’s
built-in functions.

## The meetupr_schema\_\* Function Family

meetupr provides five introspection functions, all starting with
`meetupr_schema_`:

``` r
meetupr_schema()           # Get the complete schema
meetupr_schema_queries()   # List available query entry points
meetupr_schema_mutations() # List available mutations
meetupr_schema_search()    # Search for types by name/description
meetupr_schema_type()      # Examine fields on a specific type
```

Type `meetupr_schema_` in your console and press Tab to see all
available functions.

### Performance Tip: Cache the Schema

The schema is large (~1-2MB) and rarely changes. Fetch it once and pass
it to subsequent functions:

``` r
# Fetch once
schema <- meetupr_schema()

# Reuse for multiple queries (no additional API calls)
queries <- meetupr_schema_queries(schema = schema)
mutations <- meetupr_schema_mutations(schema = schema)
event_fields <- meetupr_schema_type("Event", schema = schema)
#> ℹ Multiple types match "Event". Showing matches:
```

This pattern avoids repeated introspection queries and speeds up
exploration significantly.

## Step-by-Step Exploration Workflow

Here’s the recommended workflow for discovering and using new API
capabilities:

### Step 1: Identify Available Entry Points

Start by seeing what top-level queries exist:

``` r
query_fields <- meetupr_schema_queries(schema = schema)
query_fields
#> # A tibble: 11 × 4
#>    field_name        description                          args_count return_type
#>    <chr>             <chr>                                     <int> <chr>      
#>  1 event             "Returns an event according to requ…          1 Event      
#>  2 eventSearch       "Search events using keywords and a…          5 EventSearc…
#>  3 group             "Fetch a single group by its id"              1 Group      
#>  4 groupByUrlname    "Fetch a single group by its urlnam…          1 Group      
#>  5 groupSearch       "Search groups using keywords and a…          4 GroupSearc…
#>  6 proNetwork        "Query a Pro Network by either id o…          2 ProNetwork 
#>  7 recommendedEvents "Search events using only location."          5 Recommende…
#>  8 recommendedGroups ""                                            4 Recommende…
#>  9 self              "The currently authenticated member"          0 Member     
#> 10 suggestTopics     "Suggest topics given a search term"          4 TopicsConn…
#> 11 topicCategories   "List top level topic categories"             1 TopicCateg…
```

Each row represents a query you can execute:

- `field_name`: The query name (use this in your GraphQL query)  
- `description`: What the query does  
- `args_count`: How many arguments it accepts  
- `return_type`: What type of data it returns

For example, if you see `groupByUrlname` returning `Group`, you know you
can query group data using a URL name.

**Finding specific queries**:

``` r
# Find all group-related queries
query_fields |>
  filter(grepl("group", field_name, ignore.case = TRUE))
#> # A tibble: 4 × 4
#>   field_name        description                           args_count return_type
#>   <chr>             <chr>                                      <int> <chr>      
#> 1 group             "Fetch a single group by its id"               1 Group      
#> 2 groupByUrlname    "Fetch a single group by its urlname"          1 Group      
#> 3 groupSearch       "Search groups using keywords and a …          4 GroupSearc…
#> 4 recommendedGroups ""                                             4 Recommende…

# Find queries that don't require arguments
query_fields |>
  filter(args_count == 0)
#> # A tibble: 1 × 4
#>   field_name description                        args_count return_type
#>   <chr>      <chr>                                   <int> <chr>      
#> 1 self       The currently authenticated member          0 Member
```

### Step 2: Search for Relevant Types

Once you know what queries exist, search for related data types:

``` r
# Find all event-related types
event_types <- meetupr_schema_search("event", schema = schema)
event_types
#> # A tibble: 72 × 4
#>    type_name                  kind         description               field_count
#>    <chr>                      <chr>        <chr>                           <int>
#>  1 AnnounceEventInput         INPUT_OBJECT ""                                  0
#>  2 AnnounceEventPayload       OBJECT       ""                                  2
#>  3 CloseEventRsvpsInput       INPUT_OBJECT ""                                  0
#>  4 CloseEventRsvpsPayload     OBJECT       ""                                  2
#>  5 CommunicationSettingsInput INPUT_OBJECT "Event communication too…           0
#>  6 CreateEventInput           INPUT_OBJECT ""                                  0
#>  7 CreateEventPayload         OBJECT       ""                                  2
#>  8 DeleteEventInput           INPUT_OBJECT ""                                  0
#>  9 DeleteEventPayload         OBJECT       ""                                  2
#> 10 EditEventInput             INPUT_OBJECT ""                                  0
#> # ℹ 62 more rows
```

The search looks in both type names and descriptions, so you might
find: - `Event`: The main event type  
- `EventConnection`: Pagination wrapper for event lists  
- `EventEdge`: Individual event in a paginated list  
- `EventInput`: Input type for creating/updating events  
- `EventStatus`: Enum of possible event statuses

**Key fields explained**:

- `type_name`: The GraphQL type name  
- `kind`: Type category (OBJECT, ENUM, INTERFACE, INPUT_OBJECT, etc.)  
- `field_count`: How many fields the type has (0 for enums and inputs)

**Different type kinds**:

- `OBJECT`: Standard data type with fields (like Event, Group)  
- `ENUM`: Fixed set of values (like EventStatus: UPCOMING, PAST,
  CANCELLED)  
- `INPUT_OBJECT`: Type used as mutation argument (like
  CreateEventInput)  
- `INTERFACE`: Shared fields across multiple types  
- `SCALAR`: Primitive values (String, Int, Boolean, ID, DateTime)

``` r
# Find user/member related types
user_types <- meetupr_schema_search("user", schema = schema)
user_types
#> # A tibble: 2 × 4
#>   type_name          kind         description                        field_count
#>   <chr>              <chr>        <chr>                                    <int>
#> 1 MembershipDues     OBJECT       "The last known state of member's…           5
#> 2 NetworkUsersFilter INPUT_OBJECT ""                                           0

# Find location-related types
location_types <- meetupr_schema_search("location", schema = schema)
location_types
#> # A tibble: 5 × 4
#>   type_name           kind         description                       field_count
#>   <chr>               <chr>        <chr>                                   <int>
#> 1 CityLocation        INPUT_OBJECT ""                                          0
#> 2 GeoLocation         INPUT_OBJECT ""                                          0
#> 3 GroupLocation       INPUT_OBJECT "Group Location (if any is provi…           0
#> 4 PointLocation       INPUT_OBJECT ""                                          0
#> 5 __DirectiveLocation ENUM         "An enum describing valid locati…           0
```

### Step 3: Examine Type Fields

Now inspect what fields a specific type has:

``` r
event_fields <- meetupr_schema_type("Event", schema = schema)
#> ℹ Multiple types match "Event". Showing matches:
event_fields
#> # A tibble: 69 × 2
#>    type_name              kind        
#>    <chr>                  <chr>       
#>  1 AnnounceEventInput     INPUT_OBJECT
#>  2 AnnounceEventPayload   OBJECT      
#>  3 CloseEventRsvpsInput   INPUT_OBJECT
#>  4 CloseEventRsvpsPayload OBJECT      
#>  5 CreateEventInput       INPUT_OBJECT
#>  6 CreateEventPayload     OBJECT      
#>  7 DeleteEventInput       INPUT_OBJECT
#>  8 DeleteEventPayload     OBJECT      
#>  9 EditEventInput         INPUT_OBJECT
#> 10 EditEventPayload       OBJECT      
#> # ℹ 59 more rows
```

When multiple types match your search, use regex to select one:

``` r
# Use regular expression to choose one specific type
event <- meetupr_schema_type("^Event$", schema = schema)
event
#> # A tibble: 37 × 4
#>    field_name         description                               type  deprecated
#>    <chr>              <chr>                                     <chr> <lgl>     
#>  1 createdTime        "Event creating datetime"                 Date… FALSE     
#>  2 dateTime           "The scheduled time of the event"         Date… FALSE     
#>  3 description        "Description of the event. Visibility ma… Stri… FALSE     
#>  4 duration           "Duration of the event"                   Dura… FALSE     
#>  5 endTime            "Time when event ends"                    Date… FALSE     
#>  6 eventHosts         "List of event hosts"                     Even… FALSE     
#>  7 eventType          "Type of the event"                       Even… FALSE     
#>  8 eventUrl           "Name used for the event's web address o… Stri… FALSE     
#>  9 featuredEventPhoto ""                                        Phot… FALSE     
#> 10 feeSettings        "Optional organizer-defined fee payment … Even… FALSE     
#> # ℹ 27 more rows
```

This shows every field available on the `Event` type:

- `field_name`: Field to request in your query  
- `description`: What the field represents  
- `type`: GraphQL type (String, Int, or another object type)  
- `deprecated`: Whether the field is being phased out

**Understanding field types**:

``` r
# Look at specific field types
event |>
  select(field_name, type) |>
  head(10)
#> # A tibble: 10 × 2
#>    field_name         type            
#>    <chr>              <chr>           
#>  1 createdTime        DateTime        
#>  2 dateTime           DateTime        
#>  3 description        String          
#>  4 duration           Duration        
#>  5 endTime            DateTime        
#>  6 eventHosts         EventHost       
#>  7 eventType          EventType       
#>  8 eventUrl           String          
#>  9 featuredEventPhoto PhotoInfo       
#> 10 feeSettings        EventFeeSettings
```

Field types tell you: - Simple types (`String`, `Int`, `Boolean`):
Return scalar values  
- Object types (`Group`, `Venue`): Return nested objects (you can query
their fields too)  
- `ID`: Unique identifier (usually a string)

**Find deprecated fields** (avoid using these):

``` r
event |>
  filter(deprecated == TRUE)
#> # A tibble: 0 × 4
#> # ℹ 4 variables: field_name <chr>, description <chr>, type <chr>,
#> #   deprecated <lgl>
```

**Explore complex types**:

``` r
# See what fields are on Group objects
group_fields <- meetupr_schema_type("^Group$", schema = schema)
group_fields
#> # A tibble: 44 × 4
#>    field_name              description                          type  deprecated
#>    <chr>                   <chr>                                <chr> <lgl>     
#>  1 activeTopics            A list of group active topics.       Topic FALSE     
#>  2 allowMemberPhotoUploads Indicates if members are allowed to… Bool… FALSE     
#>  3 canAddPhotos            Shows current user's permission to … Bool… FALSE     
#>  4 city                    A city where a group is located.     Stri… FALSE     
#>  5 country                 A country where a group is located.  Stri… FALSE     
#>  6 customMemberLabel       What this group calls its members    Stri… FALSE     
#>  7 description             Description of a group.              Stri… FALSE     
#>  8 duesSettings            Active group membership dues settin… Dues… FALSE     
#>  9 emailAnnounceAddress    an email address, representing an O… Stri… FALSE     
#> 10 eventSearch             Search for events in this group      Grou… TRUE      
#> # ℹ 34 more rows
```

If an Event has a `group` field of type `Group`, you can query Group
fields nested under Event:

``` graphql
query {
  event(id: "123") {
    title
    group {
      name
      urlname
      memberCount
    }
  }
}
```

### Step 4: Build Your Custom Query

Armed with introspection data, construct a GraphQL query:

``` r
custom_query <- "
query GetEventDetails($eventId: ID!) {
  event(id: $eventId) {
    id
    title
    description
    dateTime
    duration

    # Nested group information
    group {
      name
      urlname
      city
    }

    venues {
      name
      address
      city
      state
      postalCode
      country
      lat
      lon
      venueType
    }
  }
}
"
```

**Query anatomy**:

- **Operation type**: `query` (or `mutation`)  
- **Operation name**: `GetEventDetails` (optional but helpful for
  debugging)  
- **Variables**: `$eventId: ID!` (the `!` means required)  
- **Field selection**: Choose which fields to retrieve  
- **Nested selections**: Query fields on related objects (group)

**How to choose fields**:

1.  Use
    [`meetupr_schema_type()`](http://rladies.org/meetupr/reference/meetupr_schema_type.md)
    to see available fields  
2.  Include scalar fields (String, Int, etc.) directly  
3.  For object fields (Group, Venue), nest another selection set  
4.  Test in the [Meetup API
    Playground](https://www.meetup.com/api/playground) first

### Step 5: Execute Your Query

Run the query with
[`meetupr_query()`](http://rladies.org/meetupr/reference/meetupr_query.md):

``` r
result <- meetupr_query(custom_query, eventId = "103349942")
result
#> $data
#> $data$event
#> $data$event$id
#> [1] "103349942"
#> 
#> $data$event$title
#> [1] "Ecosystem GIS & Community Building"
#> 
#> $data$event$description
#> [1] "Hello New DVDC Members!\n\nIs Data Visualization a science or an art? Our goal is to create great events where everyones' experiences reflect that sentiment, and we are beginning a great speaker in Joseph Sexton (http://www.terpconnect.umd.edu/~jsexton/). Joe will give us a glimpse of his department's unique global ecological datasets, with stunning visuals, and what goes into unparalleled GIS data. Joe's datasets include DISCO (Dynamic Impervious Surface Cover Observations) and global 30-m resolution continuous fields of tree cover from 2000 - 2005. Elizabeth Lyon will show us the next evolution of Wikipedia with interactive map visualization by MapStory.\n\nWe are excited to have NClud host the event, they have a great aesthetic downtown space that facilitates networking as well as presentations, and as with all Data Community DC (http://www.meetup.com/Data-Visualization-DC/events/103349942/www.datacommunitydc.org) events we cap the night with Data Drinks.\n\nAgenda\n\n6:30pm -- Networking and Refreshments 7:00pm -- Introduction & Announcements 7:15pm -- Presentation #1 7:45pm -- Readjust & Announcements 7:55pm -- Presentation #2 8:25pm -- Q&A - Discussion 8:40pm -- Data Drinks Bios\n\nJoseph Sexton (http://www.terpconnect.umd.edu/~jsexton/)\n\nJoe is a research professor at the University of Maryland whose research focuses on ecosystem dynamics and the remote sensing methods required to monitor landscape changes over time. He developes statistical and ecological analyses for the Global Forest Cover Change Project (http://glcf.umiacs.umd.edu/research/portal/gfcc/index.shtml), a joint project of the Global Land Cover Facility (http://www.glcf.umd.edu/index.shtml), NASA's Goddard Space Flight Center (http://www.nasa.gov/centers/goddard/home/index.html), and South Dakota State University (http://globalmonitoring.sdstate.edu/). The project is mining more than thirty years of Landsat images to map changes in Earth's forest cover from 1975 to 2005. Joe also contributes ecological, statistical, and remote sensing expertise to collaborative studies of urban heat islands, threatened and endangered species habitat, tropical deforestation, climate effects on boreal biomes, and urban growth.\n\nElizabeth Lyon\n\nLiz is a Geographer with the U.S. Army Corps of Engineers. She leads innovative research and technology development in social media, social sciences, and geospatial technology. Currently she works on building technical capacity for spatial narrative development. Elizabeth volunteers her time in Washington DC growing the geospatial community. She is currently completing her Ph.D. in Geography at George Mason University. She has a Certificate in Computational Social Science from George Mason University, a Masters of Science in Geography from University of Illinois and a bachelor’s degree in Economics and French from Augustana College."
#> 
#> $data$event$dateTime
#> [1] "2013-02-18T18:30:00-05:00"
#> 
#> $data$event$duration
#> [1] "PT2H"
#> 
#> $data$event$group
#> $data$event$group$name
#> [1] "Data Visualization DC"
#> 
#> $data$event$group$urlname
#> [1] "data-visualization-dc"
#> 
#> $data$event$group$city
#> [1] "Washington"
#> 
#> 
#> $data$event$venues
#> $data$event$venues[[1]]
#> $data$event$venues[[1]]$name
#> [1] "Browsermedia/NClud"
#> 
#> $data$event$venues[[1]]$address
#> [1] "1203 19th Street"
#> 
#> $data$event$venues[[1]]$city
#> [1] "Washington"
#> 
#> $data$event$venues[[1]]$state
#> [1] "DC"
#> 
#> $data$event$venues[[1]]$postalCode
#> [1] "20036"
#> 
#> $data$event$venues[[1]]$country
#> [1] "us"
#> 
#> $data$event$venues[[1]]$lat
#> [1] 38.9058
#> 
#> $data$event$venues[[1]]$lon
#> [1] -77.04343
#> 
#> $data$event$venues[[1]]$venueType
#> [1] ""
```

The result structure mirrors your query structure: - `data`: Top-level
wrapper  
- `event`: The query field you requested  
- Nested fields match your selection set

**Extract specific data**:

``` r
# Get just the event title
result$data$event$title
#> [1] "Ecosystem GIS & Community Building"

# Get group information
result$data$event$group
#> $name
#> [1] "Data Visualization DC"
#> 
#> $urlname
#> [1] "data-visualization-dc"
#> 
#> $city
#> [1] "Washington"

# Get venue coordinates
venue <- result$data$event$venues[[1]]
c(lat = venue$lat, lng = venue$lon)
#>       lat       lng 
#>  38.90580 -77.04343
```

## Working with Mutations

Mutations modify data on the server (create, update, delete operations).
They require appropriate permissions based on your Meetup account and
group roles.

### Discovering Available Mutations

``` r
mutations <- meetupr_schema_mutations(schema = schema)
mutations
#> # A tibble: 16 × 4
#>    field_name                description                  args_count return_type
#>    <chr>                     <chr>                             <int> <chr>      
#>  1 addGroupToNetwork         ""                                    1 AddGroupTo…
#>  2 announceEvent             "Request to announce the ev…          1 AnnounceEv…
#>  3 closeEventRsvps           "Request to close a possibi…          1 CloseEvent…
#>  4 createEvent               "Request to create an event"          1 CreateEven…
#>  5 createGroupDraft          "Request to create a new gr…          1 CreateGrou…
#>  6 createGroupEventPhoto     "Create a photo in a group …          1 PhotoUploa…
#>  7 createVenue               ""                                    1 CreateVenu…
#>  8 deleteEvent               "Request to delete event"             1 DeleteEven…
#>  9 deleteGroupDraft          ""                                    1 Boolean    
#> 10 editEvent                 "Request to edit the event"           1 EditEventP…
#> 11 openEventRsvps            "Request to open a possibil…          1 OpenEventR…
#> 12 publishEventDraft         "Request to publish the eve…          1 PublishEve…
#> 13 publishGroupDraft         "Request to publish the exi…          1 PublishGro…
#> 14 updateGroup               "Changes any field of a gro…          2 Group      
#> 15 updateGroupDraft          "Request to update the exis…          1 UpdateGrou…
#> 16 updateGroupMembershipRole "Allows a Group leader to g…          1 UpdateGrou…
```

Each mutation: - Takes an `input` argument (usually an INPUT_OBJECT
type)  
- Returns a payload type with `errors` field and the modified object  
- Requires authentication and appropriate permissions

**Common mutation patterns**:

- **Create**: `createEvent`, `createGroup`  
- **Update**: `updateEvent`, `updateMember`  
- **Delete**: `deleteEvent`, `removeGroupMember`  
- **RSVP**: `createEventRsvp`, `deleteEventRsvp`

### Understanding Mutation Structure

Mutations follow a standard pattern in the Meetup API:

``` r
mutation_query <- "
mutation OperationName($input: InputType!) {
  mutationField(input: $input) {
    # Always check for errors
    errors {
      code
      message
    }

    # The modified object (if successful)
    resultField {
      id
      # other fields you want back
    }
  }
}
"
```

**Mutation response structure**:

1.  **errors**: Array of error objects (null if successful)  
2.  **Result field**: The created/updated object (null if errors
    occurred)

Always check the `errors` field before accessing the result.

### Example: RSVP to an Event

``` r
# First, explore the mutation
mutations |>
  filter(field_name == "createEventRsvp")

# Check what input fields are needed
rsvp_input <- meetupr_schema_type("CreateEventRsvpInput", schema = schema)
rsvp_input

# Build the mutation
rsvp_mutation <- "
mutation RSVPToEvent($input: CreateEventRsvpInput!) {
  createEventRsvp(input: $input) {
    errors {
      code
      message
    }
    rsvp {
      id
      response
      created
    }
  }
}
"

# Execute (requires authentication and valid event)
result <- meetupr_query(
  rsvp_mutation,
  input = list(
    eventId = "123456",
    response = "YES"
  )
)

# Check for errors
if (!is.null(result$data$createEventRsvp$errors)) {
  cli::cli_alert_danger("RSVP failed")
  print(result$data$createEventRsvp$errors)
} else {
  cli::cli_alert_success("RSVP successful")
  print(result$data$createEventRsvp$rsvp)
}
```

**Important mutation considerations**:

- **Permissions**: You must have appropriate group roles  
- **Validation**: Input must match schema requirements exactly  
- **Idempotency**: Some mutations can be repeated safely, others
  cannot  
- **Rate limits**: Mutations count toward API rate limits (500 req/60s)

## Advanced Introspection Patterns

### Exploring Enum Values

Enums are fixed sets of allowed values (like event status: UPCOMING,
PAST, CANCELLED):

``` r
# Find all enum types
enum_types <- schema$types[sapply(schema$types, function(x) {
  x$kind == "ENUM"
})]

# Example: Event status values
event_status <- enum_types[sapply(enum_types, function(x) {
  x$name == "EventStatus"
})][[1]]

# Get allowed values
sapply(event_status$enumValues, function(x) x$name)
#>  [1] "ACTIVE"              "AUTOSCHED"           "AUTOSCHED_CANCELLED"
#>  [4] "AUTOSCHED_DRAFT"     "AUTOSCHED_FINISHED"  "BLOCKED"            
#>  [7] "CANCELLED"           "CANCELLED_PERM"      "DRAFT"              
#> [10] "PAST"                "PENDING"             "PROPOSED"           
#> [13] "TEMPLATE"
```

This tells you exactly which status values are valid when filtering
events.

### Finding Required vs. Optional Fields

Field types can be wrapped in modifiers: - `!` suffix means **required**
(NON_NULL kind)  
- `[]` brackets mean **list/array** (LIST kind)

``` r
# Find required fields on Event
event |>
  filter(grepl("!", type)) |>
  select(field_name, type)
#> # A tibble: 0 × 2
#> # ℹ 2 variables: field_name <chr>, type <chr>
```

The `!` indicates you must provide this field in mutations or it will
always be present in queries.

### Discovering Input Types for Mutations

Input types define what data mutations accept:

``` r
# Find all input types
input_types <- meetupr_schema_search("Input", schema = schema) |>
  filter(kind == "INPUT_OBJECT")

input_types
#> # A tibble: 35 × 4
#>    type_name                  kind         description               field_count
#>    <chr>                      <chr>        <chr>                           <int>
#>  1 AddGroupToNetworkInput     INPUT_OBJECT ""                                  0
#>  2 AnnounceEventInput         INPUT_OBJECT ""                                  0
#>  3 CloseEventRsvpsInput       INPUT_OBJECT ""                                  0
#>  4 CommunicationSettingsInput INPUT_OBJECT "Event communication too…           0
#>  5 CovidPrecautionsInput      INPUT_OBJECT ""                                  0
#>  6 CreateEventInput           INPUT_OBJECT ""                                  0
#>  7 CreateGroupDraftInput      INPUT_OBJECT ""                                  0
#>  8 CreateVenueInput           INPUT_OBJECT ""                                  0
#>  9 DeleteEventInput           INPUT_OBJECT ""                                  0
#> 10 DeleteGroupDraftInput      INPUT_OBJECT ""                                  0
#> # ℹ 25 more rows
```

Examine specific input types to see required fields:

``` r
# See what fields CreateEventInput requires
create_event_input <- meetupr_schema_type("CreateEventInput", schema = schema)
create_event_input
#> # A tibble: 1 × 1
#>   message                            
#>   <chr>                              
#> 1 Type CreateEventInput has no fields
```

### Understanding Pagination Types

Meetup uses cursor-based pagination with Connection/Edge patterns:

``` r
# Find pagination-related types
pagination_types <- meetupr_schema_search("Connection", schema = schema)
pagination_types
#> # A tibble: 27 × 4
#>    type_name                        kind   description               field_count
#>    <chr>                            <chr>  <chr>                           <int>
#>  1 EventSearchConnection            OBJECT ""                                  3
#>  2 FeaturedEventPhotoConnection     OBJECT ""                                  3
#>  3 FeaturedEventPhotoConnectionEdge OBJECT ""                                  2
#>  4 GroupEventConnection             OBJECT ""                                  3
#>  5 GroupEventSearchConnection       OBJECT ""                                  3
#>  6 GroupMemberConnection            OBJECT ""                                  3
#>  7 GroupSearchConnection            OBJECT ""                                  3
#>  8 GroupVenueConnection             OBJECT "#######################…           3
#>  9 HostRsvpConnection               OBJECT ""                                  3
#> 10 MemberEventConnection            OBJECT ""                                  3
#> # ℹ 17 more rows
```

**Pagination pattern**:

``` graphql
{
  group(urlname: "rladies-lagos") {
    upcomingEvents(input: {first: 10, after: "cursor"}) {
      pageInfo {
        hasNextPage
        endCursor
      }
      edges {
        node {
          # Event fields here
        }
      }
    }
  }
}
```

- `pageInfo`: Contains `hasNextPage` (boolean) and `endCursor`
  (string)  
- `edges`: Array of results  
- `node`: The actual object (Event, Group, etc.)

The meetupr package handles pagination automatically in wrapper
functions, but understanding this structure helps when building custom
queries.

## Exporting Schema for External Tools

Some developers prefer graphical schema explorers or IDE plugins. Export
the schema as JSON:

``` r
# Export full schema
schema_json <- meetupr_schema(asis = TRUE)
writeLines(schema_json, "meetupr_schema.json")
```

This JSON can be imported into: - [GraphQL
Voyager](https://apis.guru/graphql-voyager/) for visual exploration  
- IDE plugins (VS Code GraphQL extension, IntelliJ GraphQL plugin)

## Practical Tips and Workflow

### Use the Meetup API Playground

The [Meetup API Playground](https://www.meetup.com/api/playground)
provides: - Autocomplete for fields and types  
- Real-time validation  
- Example queries  
- Schema documentation browser

Build and test your query there, then copy it into
[`meetupr_query()`](http://rladies.org/meetupr/reference/meetupr_query.md).

### Use Debug Mode

Enable debug mode to see the exact GraphQL being sent:

``` r
meetupr::local_meetupr_debug(TRUE)

# Your query here
result <- meetupr_query(custom_query, eventId = "123")

meetupr::local_meetupr_debug(FALSE)
```

This prints: - The complete query with variables substituted  
- Request headers  
- Response structure

## Next Steps

- **Build custom queries**: See the [Custom Queries
  vignette](http://rladies.org/meetupr/articles/graphql.md) for
  template-based query patterns  
- **Authentication**: See the [Getting Started
  vignette](http://rladies.org/meetupr/articles/meetupr.md) for auth
  setup  
- **Advanced auth**: See the [Advanced Authentication
  vignette](http://rladies.org/meetupr/articles/advanced-auth.md) for
  custom OAuth apps  
- **API Reference**: Visit <https://www.meetup.com/graphql/> for
  official schema documentation
