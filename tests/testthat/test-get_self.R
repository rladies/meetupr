describe("get_self", {
  it("handles user with complete profile", {
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

    local_mocked_bindings(
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

  it("handles user with minimal profile", {
    mock_if_no_auth()

    mock_data <- list(
      id = "456",
      name = "Minimal User",
      country = "GB"
    )

    local_mocked_bindings(
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
})

describe("determine_pro_status", {
  it("calculates correctly", {
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

  it("returns TRUE for pro organizer", {
    user_data <- list(isProOrganizer = TRUE)
    expect_true(determine_pro_status(user_data))
  })

  it("returns TRUE for admin networks", {
    user_data <- list(
      isProOrganizer = FALSE,
      adminProNetworks = c("network1", "network2")
    )
    expect_true(determine_pro_status(user_data))
  })

  it("returns FALSE for non-pro users", {
    user_data <- list(
      isProOrganizer = FALSE,
      adminProNetworks = NULL
    )
    expect_false(determine_pro_status(user_data))
  })

  it("handles missing fields", {
    user_data <- list()
    expect_false(determine_pro_status(user_data))
  })

  it("handles empty networks", {
    user_data <- list(
      isProOrganizer = FALSE,
      adminProNetworks = character(0)
    )
    expect_false(determine_pro_status(user_data))
  })

  it("handles NULL pro organizer field", {
    user_data <- list(
      isProOrganizer = NULL,
      adminProNetworks = c("network1")
    )
    expect_true(determine_pro_status(user_data))
  })
})

describe("process_self_data", {
  it("handles empty data", {
    expect_error(
      process_self_data(list()),
      "No user data returned from self query"
    )
  })

  it("uses null coalescing operator correctly", {
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
})

describe("extract_location_info", {
  it("extracts all location fields", {
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
    expect_equal(location$country, "United States")
    expect_equal(location$lat, 37.7749)
    expect_equal(location$lon, -122.4194)
  })

  it("handles missing fields", {
    user_data <- list(
      city = "Chicago"
    )

    location <- extract_location_info(user_data)

    expect_equal(location$city, "Chicago")
    expect_null(location$state)
    expect_null(location$country)
    expect_null(location$lat)
    expect_null(location$lon)
  })
})

describe("extract_profile_info", {
  it("extracts all profile fields", {
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

  it("handles missing fields", {
    user_data <- list(bio = "Just a bio")

    profile <- extract_profile_info(user_data)

    expect_equal(profile$bio, "Just a bio")
    expect_null(profile$member_url)
    expect_null(profile$join_time)
    expect_null(profile$preferred_locale)
  })
})

describe("print.meetupr_user", {
  it("handles missing email", {
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
      class = c("meetupr_user", "list")
    )

    output <- capture.output(print(user))
    expect_false(any(grepl("Email:", output)))
  })

  it("handles missing location", {
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
      class = c("meetupr_user", "list")
    )

    output <- capture.output(print(user))
    expect_false(any(grepl("Location:", output)))
  })

  it("outputs full data correctly", {
    user <- structure(
      list(
        id = "user123",
        name = "John Doe",
        email = "john@example.com",
        is_organizer = TRUE,
        is_leader = FALSE,
        is_pro_organizer = TRUE,
        is_member_plus_subscriber = FALSE,
        has_pro_access = TRUE,
        location = list(city = "New York", country = "USA")
      ),
      class = c("meetupr_user", "list")
    )
    expect_snapshot(print.meetupr_user(user))
  })

  it("handles missing optional fields", {
    user <- structure(
      list(
        id = "user123",
        name = "John Doe",
        email = NULL,
        is_organizer = FALSE,
        is_leader = FALSE,
        is_pro_organizer = FALSE,
        is_member_plus_subscriber = FALSE,
        has_pro_access = NA,
        location = list(city = NULL, country = NULL)
      ),
      class = c("meetupr_user", "list")
    )

    expect_snapshot(print.meetupr_user(user))
  })

  it("handles partial location data", {
    user <- structure(
      list(
        id = "user123",
        name = "John Doe",
        is_organizer = TRUE,
        is_leader = TRUE,
        is_pro_organizer = FALSE,
        is_member_plus_subscriber = TRUE,
        has_pro_access = FALSE,
        location = list(city = "Los Angeles", country = NULL)
      ),
      class = c("meetupr_user", "list")
    )

    expect_snapshot(print.meetupr_user(user))
  })
})

describe("is_self_pro", {
  it("returns TRUE for Pro organizers", {
    mock_resp <- list(data = list(self = list(isProOrganizer = TRUE)))
    local_mocked_bindings(
      meetupr_query = function(...) mock_resp,
      has_auth = function(...) TRUE
    )
    expect_true(is_self_pro())
  })

  it("returns FALSE for non-Pro organizers", {
    mock_resp <- list(data = list(self = list(isProOrganizer = FALSE)))

    local_mocked_bindings(
      meetupr_query = function(...) mock_resp,
      has_auth = function(...) TRUE
    )
    expect_false(is_self_pro())
  })
})
