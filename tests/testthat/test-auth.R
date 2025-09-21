test_that("meetup_client returns a valid oauth client", {
  mock_if_no_auth()
  withr::local_envvar(c(
    MEETUP_CLIENT_ID = "client_id",
    MEETUP_CLIENT_SECRET = "client_secret",
    MEETUP_CLIENT_NAME = "meetupr"
  ))
  client <- meetup_client()
  expect_equal(client$id, "client_id")
  expect_equal(client$secret, "client_secret")
  expect_equal(client$name, "meetupr")
})

test_that("meetup_client throws error when credentials are missing", {
  mock_if_no_auth()
  withr::local_envvar(c(
    MEETUP_CLIENT_ID = "",
    MEETUP_CLIENT_SECRET = ""
  ))
  expect_error(meetup_client(), "Meetup client ID and secret are required.")
})

test_that("has_jwt_credentials returns true when all credentials are set", {
  mock_if_no_auth()
  withr::local_envvar(c(
    MEETUP_CLIENT_ID = "client_id",
    MEETUP_MEMBER_ID = "member_id",
    MEETUP_RSA_KEY = "rsa_key"
  ))
  expect_true(has_jwt_credentials())
})

test_that("has_jwt_credentials returns false when credentials are missing", {
  mock_if_no_auth()
  withr::local_envvar(c(
    MEETUP_CLIENT_ID = "",
    MEETUP_MEMBER_ID = "",
    MEETUP_RSA_KEY = ""
  ))
  expect_false(has_jwt_credentials())
})

test_that("has_jwt_credentials checks file path if RSA key is not set", {
  mock_if_no_auth()
  temp_rsa <- withr::local_tempfile()
  write("example_key", temp_rsa)
  withr::local_envvar(c(
    MEETUP_CLIENT_ID = "client_id",
    MEETUP_MEMBER_ID = "member_id",
    MEETUP_RSA_KEY = "",
    MEETUP_RSA_PATH = temp_rsa
  ))
  expect_true(has_jwt_credentials())
})

test_that("has_jwt_credentials returns FALSE for bad RSA", {
  withr::local_envvar(
    MEETUP_CLIENT_ID = "test_client_id",
    MEETUP_MEMBER_ID = "test_member_id",
    MEETUP_RSA_PATH = "",
    MEETUP_RSA_KEY = ""
  )

  result <- has_jwt_credentials()

  expect_false(result)
})

test_that("has_jwt_credentials handles RSA_PATH that doesn't exist", {
  temp_path <- withr::local_tempfile()

  withr::local_envvar(
    MEETUP_CLIENT_ID = "test_client_id",
    MEETUP_MEMBER_ID = "test_member_id",
    MEETUP_RSA_PATH = temp_path,
    MEETUP_RSA_KEY = ""
  )

  result <- has_jwt_credentials()

  expect_false(result)
})

test_that("has_oauth_credentials returns true when all credentials are set", {
  mock_if_no_auth()
  withr::local_envvar(c(
    MEETUP_CLIENT_ID = "client_id",
    MEETUP_CLIENT_SECRET = "client_secret"
  ))
  expect_true(has_oauth_credentials())
})

test_that("has_oauth_credentials returns false when credentials are missing", {
  mock_if_no_auth()
  withr::local_envvar(c(
    MEETUP_CLIENT_ID = "",
    MEETUP_CLIENT_SECRET = ""
  ))
  expect_false(has_oauth_credentials())
})

test_that("get_rsa_key returns rsa key from environment variable", {
  withr::local_envvar(
    MEETUP_RSA_KEY = "-----BEGIN RSA PRIVATE KEY-----",
    MEETUP_RSA_PATH = NULL
  )
  expect_equal(get_rsa_key(), "-----BEGIN RSA PRIVATE KEY-----")
})

test_that("get_rsa_key throws error if file does not exist", {
  withr::local_envvar(c(MEETUP_RSA_PATH = "nonexistent_file"))
  expect_error(get_rsa_key(), "Private key file not found:")
})

test_that("get_rsa_key reads key content from file", {
  temp_rsa <- withr::local_tempfile()
  write("example_key", temp_rsa)
  withr::local_envvar(c(MEETUP_RSA_PATH = temp_rsa, MEETUP_RSA_KEY = ""))
  expect_equal(get_rsa_key(), "example_key")
})

test_that("get_rsa_key throws error when no RSA key is available", {
  withr::local_envvar(c(MEETUP_RSA_KEY = "", MEETUP_RSA_PATH = ""))
  expect_error(get_rsa_key(), "RSA private key not found.")
})
