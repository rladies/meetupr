if (nzchar(Sys.getenv("MEETUPR_PWD"))) {
  key <- cyphr::key_sodium(sodium::hex2bin(Sys.getenv("MEETUPR_PWD")))

  temptoken <- tempfile(fileext = ".rds")

  cyphr::decrypt_file(
    testthat::test_path("secret.rds"),
    key = key,
    dest = temptoken
  )

  token <- readRDS(temptoken)[[1]]

  meetupr::meetup_auth(
    token = token,
    set_renv = FALSE,
    cache = FALSE
  ) -> token

  Sys.setenv(MEETUPR_PAT = temptoken)

} else {
  Sys.setenv("MEETUPR_TESTING" = TRUE)
  token <- meetup_token()
}


library("vcr")
invisible(vcr::vcr_configure(
  filter_sensitive_data = list(
    "<<<my_access_token>>>" = token$credentials$access_token %||% "lala",
    "<<<my_refresh_token>>>" = token$credentials$refresh_token %||% "lala"
  ),
  dir = "../fixtures"
))
vcr::check_cassette_names()


