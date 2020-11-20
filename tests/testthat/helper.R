key <- cyphr::key_sodium(
  sodium::keygen(seed = charToRaw(Sys.getenv("MEETUPR_PWD")))
)

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

library("meetupr")
urlname <- "rladies-nashville"
past_events <- get_events(urlname = urlname,
                          event_status = "past")
