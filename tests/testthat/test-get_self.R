test_that("get_self returns basic user info", {
  use_cassette("get_self_basic", {
    user <- get_self(extended = FALSE, check_pro = FALSE)
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
})


test_that("get_self returns extended user info", {
  use_cassette("get_self_extended", {
    user <- get_self(extended = TRUE, check_pro = FALSE)
  })

  expect_type(user, "list")
  expect_named(
    user$profile,
    c("bio", "member_url", "join_time", "preferred_locale")
  )
  expect_named(user$location, c("city", "state", "country", "lat", "lon"))
})


test_that("get_self checks pro access", {
  use_cassette("get_self_pro_check", {
    user <- get_self(extended = FALSE, check_pro = TRUE)
  })

  expect_true(is.logical(user$has_pro_access))
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

  expect_true(determine_pro_status(user_data_pro, TRUE))
  expect_false(determine_pro_status(user_data_non_pro, TRUE))

  expect_true(is.na(determine_pro_status(user_data_pro, FALSE)))
  expect_true(is.na(determine_pro_status(user_data_non_pro, FALSE)))

  user_data_missing_fields <- list()
  expect_false(determine_pro_status(user_data_missing_fields, TRUE))

  user_data_empty_networks <- list(
    isProOrganizer = FALSE,
    adminProNetworks = character(0)
  )
  expect_false(determine_pro_status(user_data_empty_networks, TRUE))
})
