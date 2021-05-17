test_that("meetup_auth() works", {

  # New app imitating meetup dot com
meetup_app <- webfakes::new_app_process(
  webfakes::oauth2_resource_app(
    refresh_duration = .Machine$integer.max,
    access_duration = 100L,
    authorize_endpoint = "/authorize",
    token_endpoint = "/access"
  )
)
meetup_app$start()

# Register an app
url <- paste0(
  meetup_app$url("/register"),
  "?name=meetup",
  "&redirect_uri=", httr::oauth_callback()
)
reg_resp <- httr::GET(url)
regdata <- httr::content(reg_resp)
withr::local_options(
  list(
    "meetupr.consumer_key" = regdata$client_id[[1]],
    "meetupr.consumer_secret" = regdata$client_secret[[1]]
    )
  )
withr::local_envvar(
  list(
    "MEETUP_AUTH_URL" = meetup_app$url(),
    "MEETUP_TESTTHAT" = TRUE
    )
  )

td <- withr::local_tempdir()
token <- meetup_auth(
  new_user = TRUE,
  token_path = file.path(td, "token.rds"),
  use_appdir = FALSE)

  expect_s3_class(token, "Token2.0")
  expect_true(file.exists(file.path(td, "token.rds")))
  expect_s3_class(readRDS(file.path(td, "token.rds"))[[1]], "Token2.0")

})
