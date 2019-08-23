# Stuff to set up on load, run this last (hence the filename)
# Taken from googlesheets3/zzz.R
.onLoad <- function(libname, pkgname) {

  op <- options()
  op.meetupr <- list(
    meetupr.httr_oauth_cache = TRUE,
    meetupr.consumer_key     = "2vagj0ut3btomqbb32tca763m1",
    meetupr.consumer_secret  = "k73s3jrah57hp9ej21e8dslnl5",
    meetupr.use_oauth        = TRUE
  )
  toset <- !(names(op.meetupr) %in% names(op))
  if(any(toset)) options(op.meetupr[toset])

  invisible()

}
