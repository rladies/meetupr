test_that("meetup_api_prefix returns the correct default URL", {
  withr::local_envvar(c(MEETUP_API_URL = NULL))
  expect_equal(meetup_api_prefix(), "https://api.meetup.com/gql-ext")
})

test_that("meetup_api_prefix returns custom URL if set", {
  withr::local_envvar(c(MEETUP_API_URL = "https://custom.meetup.com"))
  expect_equal(meetup_api_prefix(), "https://custom.meetup.com")
})

test_that("meetupr_req configures request with proper headers", {
  mock_if_no_auth()
  req <- meetupr_req()
  expect_equal(httr2::req_get_headers(req)$`Content-Type`, "application/json")
})

test_that("meetupr_req handles JWT authentication", {
  mock_if_no_auth()
  withr::local_envvar(c(
    MEETUP_AUTH_METHOD = "jwt",
    MEETUP_CLIENT_ID = "client_id",
    MEETUP_MEMBER_ID = "member_id"
  ))

  testthat::local_mocked_bindings(
    get_rsa_key = function() "mock_key"
  )
  req <- meetupr_req()
  expect_equal(
    req$policies$auth_sign$params$flow,
    "oauth_flow_bearer_jwt"
  )
})

test_that("meetupr_req handles OAuth authentication", {
  mock_if_no_auth()
  withr::local_envvar(c(
    MEETUP_AUTH_METHOD = "oauth",
    MEETUP_CLIENT_ID = "client_id",
    MEETUP_CLIENT_SECRET = "client_secret"
  ))
  req <- meetupr_req(cache = FALSE)
  expect_equal(
    req$policies$auth_sign$params$flow,
    "oauth_flow_auth_code"
  )
})

test_that("meetupr_req raises error if no authentication is set", {
  withr::local_envvar(c(
    MEETUP_AUTH_METHOD = "",
    MEETUP_CLIENT_ID = "",
    MEETUP_CLIENT_SECRET = ""
  ))
  expect_error(meetupr_req(), "Authentication required. Set either:")
})
