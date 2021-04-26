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
    use_appdir = FALSE,
    cache = FALSE
  ) -> token

  meetup_auth(token = temptoken)

} else {
  if (!identical(Sys.getenv("NOT_CRAN"), "true")) {
    Sys.setenv("MEETUPR_TESTING" = TRUE)
  }
  token <- meetup_token()
}


library("vcr")
invisible(vcr::vcr_configure(
  filter_request_headers = list(Authorization = "not my bearer token"),
  filter_sensitive_data = list(
    "<<<my_refresh_token>>>" = token$credentials$refresh_token %||% "lala"
  ),
  dir = "../fixtures"
))
vcr::check_cassette_names()


