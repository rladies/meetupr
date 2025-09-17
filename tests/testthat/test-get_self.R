test_that("get_self returns basic user info", {
  use_cassette("get_self_basic", {
    user <- get_self()
  })

  expect_type(user, "list")
  expect_s3_class(user, "meetup_user")
  expect_named(
    user,
    c(
      "id",
      "name",
      "email",
      "is_organizer",
      "is_leader",
      "is_member_plus_subscriber",
      "is_pro_organizer",
      "has_pro_access",
      "location",
      "profile",
      "raw"
    )
  )
  expect_named(
    user$profile,
    c("bio", "member_url", "join_time", "preferred_locale")
  )
  expect_named(user$location, c("city", "state", "country", "lat", "lon"))
})


test_that("determine_pro_status calculates correctly", {
  user_data_pro <- list(
    isProOrganizer = TRUE,
    adminProNetworks = c("network1", "network2")
  )

  user_data_non_pro <- list(
    isProOrganizer = FALSE,
    adminProNetworks = NULL
  )

  expect_true(determine_pro_status(user_data_pro))
  expect_false(determine_pro_status(user_data_non_pro))

  user_data_missing_fields <- list()
  expect_false(determine_pro_status(user_data_missing_fields))

  user_data_empty_networks <- list(
    isProOrganizer = FALSE,
    adminProNetworks = character(0)
  )
  expect_false(determine_pro_status(user_data_empty_networks))
})

test_that("get_self returns correct structure", {
  mock_if_no_auth()
  vcr::use_cassette("get_self", {
    user <- get_self()
  })

  expect_type(user, "list")
  expect_s3_class(user, c("meetup_user", "list"))
  expect_named(
    user,
    c(
      "id",
      "name",
      "email",
      "is_organizer",
      "is_leader",
      "is_member_plus_subscriber",
      "is_pro_organizer",
      "has_pro_access",
      "location",
      "profile",
      "raw"
    )
  )
})

test_that("get_self handles user with complete profile", {
  mock_if_no_auth()

  mock_data <- list(
    id = "123",
    name = "Test User",
    email = "test@example.com",
    isOrganizer = TRUE,
    isLeader = FALSE,
    isMemberPlusSubscriber = TRUE,
    isProOrganizer = FALSE,
    city = "Nashville",
    state = "TN",
    country = "US",
    lat = 36.1627,
    lon = -86.7816,
    bio = "R enthusiast",
    memberUrl = "https://meetup.com/members/123",
    startDate = "2020-01-01",
    preferredLocale = "en-US"
  )

  testthat::local_mocked_bindings(
    execute = function(...) {
      process_self_data(mock_data)
    }
  )

  user <- get_self()

  expect_equal(user$id, "123")
  expect_equal(user$name, "Test User")
  expect_equal(user$email, "test@example.com")
  expect_true(user$is_organizer)
  expect_false(user$is_leader)
  expect_true(user$is_member_plus_subscriber)
  expect_false(user$is_pro_organizer)
  expect_false(user$has_pro_access)
  expect_equal(user$location$city, "Nashville")
  expect_equal(user$profile$bio, "R enthusiast")
})

test_that("get_self handles user with minimal profile", {
  mock_if_no_auth()

  mock_data <- list(
    id = "456",
    name = "Minimal User"
  )

  testthat::local_mocked_bindings(
    execute = function(...) {
      process_self_data(mock_data)
    }
  )

  user <- get_self()

  expect_equal(user$id, "456")
  expect_equal(user$name, "Minimal User")
  expect_null(user$email)
  expect_false(user$is_organizer)
  expect_false(user$is_leader)
  expect_false(user$is_member_plus_subscriber)
  expect_false(user$is_pro_organizer)
  expect_false(user$has_pro_access)
})

test_that("process_self_data handles empty data", {
  expect_error(
    process_self_data(list()),
    "No user data returned from self query"
  )

  expect_error(
    process_self_data(list(NULL)),
    "No user data returned from self query"
  )
})

test_that("extract_location_info extracts all location fields", {
  user_data <- list(
    city = "San Francisco",
    state = "CA",
    country = "US",
    lat = 37.7749,
    lon = -122.4194
  )

  location <- extract_location_info(user_data)

  expect_equal(location$city, "San Francisco")
  expect_equal(location$state, "CA")
  expect_equal(location$country, "US")
  expect_equal(location$lat, 37.7749)
  expect_equal(location$lon, -122.4194)
})

test_that("extract_location_info handles missing fields", {
  user_data <- list(city = "Chicago")

  location <- extract_location_info(user_data)

  expect_equal(location$city, "Chicago")
  expect_null(location$state)
  expect_null(location$country)
  expect_null(location$lat)
  expect_null(location$lon)
})

test_that("extract_profile_info extracts all profile fields", {
  user_data <- list(
    bio = "Data scientist",
    memberUrl = "https://meetup.com/members/789",
    startDate = "2019-06-15",
    preferredLocale = "es-ES"
  )

  profile <- extract_profile_info(user_data)

  expect_equal(profile$bio, "Data scientist")
  expect_equal(profile$member_url, "https://meetup.com/members/789")
  expect_equal(profile$join_time, "2019-06-15")
  expect_equal(profile$preferred_locale, "es-ES")
})

test_that("extract_profile_info handles missing fields", {
  user_data <- list(bio = "Just a bio")

  profile <- extract_profile_info(user_data)

  expect_equal(profile$bio, "Just a bio")
  expect_null(profile$member_url)
  expect_null(profile$join_time)
  expect_null(profile$preferred_locale)
})

test_that("determine_pro_status returns TRUE for pro organizer", {
  user_data <- list(isProOrganizer = TRUE)
  expect_true(determine_pro_status(user_data))
})

test_that("determine_pro_status returns TRUE for admin networks", {
  user_data <- list(
    isProOrganizer = FALSE,
    adminProNetworks = c("network1", "network2")
  )
  expect_true(determine_pro_status(user_data))
})

test_that("determine_pro_status returns FALSE for non-pro users", {
  user_data <- list(
    isProOrganizer = FALSE,
    adminProNetworks = NULL
  )
  expect_false(determine_pro_status(user_data))
})

test_that("determine_pro_status handles missing fields", {
  user_data <- list()
  expect_false(determine_pro_status(user_data))
})

test_that("determine_pro_status handles empty networks", {
  user_data <- list(
    isProOrganizer = FALSE,
    adminProNetworks = character(0)
  )
  expect_false(determine_pro_status(user_data))
})

test_that("determine_pro_status handles NULL pro organizer field", {
  user_data <- list(
    isProOrganizer = NULL,
    adminProNetworks = c("network1")
  )
  expect_true(determine_pro_status(user_data))
})

test_that("print.meetup_user displays basic info", {
  user <- structure(
    list(
      id = "123",
      name = "Test User",
      email = "test@example.com",
      is_organizer = TRUE,
      is_leader = FALSE,
      is_pro_organizer = FALSE,
      is_member_plus_subscriber = TRUE,
      has_pro_access = FALSE,
      location = list(city = "Austin", country = "US"),
      profile = list(bio = "R user"),
      raw = list()
    ),
    class = c("meetup_user", "list")
  )

  # expect_output(print(user), "Meetup User:")
  # expect_output(print(user), "ID: 123")
  # expect_output(print(user), "Name: Test User")
  # expect_output(print(user), "Email: test@example.com")
})

test_that("print.meetup_user handles missing email", {
  user <- structure(
    list(
      id = "456",
      name = "No Email User",
      email = NULL,
      is_organizer = FALSE,
      is_leader = FALSE,
      is_pro_organizer = FALSE,
      is_member_plus_subscriber = FALSE,
      has_pro_access = NA,
      location = NULL,
      profile = list(),
      raw = list()
    ),
    class = c("meetup_user", "list")
  )

  output <- capture.output(print(user))
  expect_false(any(grepl("Email:", output)))
})

test_that("print.meetup_user handles missing location", {
  user <- structure(
    list(
      id = "789",
      name = "No Location User",
      email = NULL,
      is_organizer = FALSE,
      is_leader = FALSE,
      is_pro_organizer = FALSE,
      is_member_plus_subscriber = FALSE,
      has_pro_access = FALSE,
      location = NULL,
      profile = list(),
      raw = list()
    ),
    class = c("meetup_user", "list")
  )

  output <- capture.output(print(user))
  expect_false(any(grepl("Location:", output)))
})

test_that("get_self uses meetup_template_query correctly", {
  mock_if_no_auth()

  testthat::local_mocked_bindings(
    meetup_template_query = function(
      query_name,
      data_path,
      extract_path,
      process_data
    ) {
      expect_equal(query_name, "get_self")
      expect_equal(data_path, "")
      expect_equal(extract_path, "data.self")
      expect_identical(process_data, process_self_data)
      "mock_query_object"
    },
    execute = function(query_obj, extra_graphql) {
      expect_equal(query_obj, "mock_query_object")
      expect_null(extra_graphql)
      structure(list(id = "test"), class = c("meetup_user", "list"))
    }
  )

  result <- get_self()
  expect_s3_class(result, "meetup_user")
})

test_that("process_self_data uses null coalescing operator correctly", {
  user_data <- list(
    id = "test_id",
    name = "Test Name",
    isOrganizer = NULL,
    isLeader = TRUE,
    isMemberPlusSubscriber = NULL,
    isProOrganizer = FALSE
  )

  result <- process_self_data(user_data)

  expect_false(result$is_organizer)
  expect_true(result$is_leader)
  expect_false(result$is_member_plus_subscriber)
  expect_false(result$is_pro_organizer)
})
