# Stuff to set up on load, run this last (hence the filename)
# Taken from googlesheets3/zzz.R
.onLoad <- function(libname, pkgname) {

  op <- options()
  op.meetupr <- list(
    meetupr.httr_oauth_cache = TRUE,
    meetupr.consumer_key     = "blah", # replace this
    meetupr.consumer_secret  = "blah", # and this
    meetupr.use_oauth        = TRUE
  )
  toset <- !(names(op.meetupr) %in% names(op))
  if(any(toset)) options(op.meetupr[toset])

  invisible()

}
