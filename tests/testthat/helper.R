library(vcr)
library(withr)

invisible(
  vcr::vcr_configure(
    filter_sensitive_data = list(
      "<<<MEETUP_CLIENT_SECRET>>>" = Sys.getenv("MEETUP_CLIENT_SECRET"),
      "<<<MEETUP_RSA_KEY>>>" = Sys.getenv("MEETUP_RSA_KEY")
    )
  )
)

event_id <- "103349942"
