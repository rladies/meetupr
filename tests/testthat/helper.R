library(vcr)
library(withr)

invisible(
  vcr::vcr_configure()
)

local_clean_backend <- function(env = parent.frame()) {
  # Clear any existing cached backend
  .meetupr_env$keyring_backend <- NULL

  # Ensure cleanup after test
  withr::defer(
    {
      .meetupr_env$keyring_backend <- NULL
    },
    envir = env
  )
}

event_id <- "103349942"
