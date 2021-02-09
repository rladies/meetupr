# Stuff to set up on load, run this last (hence the filename)
# Taken from googlesheets3/zzz.R
.onLoad <- function(libname, pkgname) {

  op <- options()
  op.meetupr <- list(
    meetupr.consumer_key     = "2vagj0ut3btomqbb32tca763m1",
    meetupr.consumer_secret  = "k73s3jrah57hp9ej21e8dslnl5"
  )
  toset <- !(names(op.meetupr) %in% names(op))
  if(any(toset)) options(op.meetupr[toset])

  invisible()

}

# https://github.com/r-hub/rhub/blob/5c339d7b95d75172beec85603ee197c2502903b1/R/utils.R#L21

`%||%` <- function(l, r) if (is.null(l)) r else l
