library(vcr)
library(withr)

invisible(
  vcr::vcr_configure()
)

Sys.setenv("MEETUPR_DEBUG" = "FALSE")
event_id <- "103349942"
