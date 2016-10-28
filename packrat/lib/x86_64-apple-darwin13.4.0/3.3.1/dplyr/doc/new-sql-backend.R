## ---- echo = FALSE, message = FALSE--------------------------------------
knitr::opts_chunk$set(collapse = T, comment = "#>")
options(tibble.print_min = 4L, tibble.print_max = 4L)
library(dplyr)

## ---- eval = FALSE-------------------------------------------------------
#  src_postgres <- function(dbname = NULL, host = NULL, port = NULL, user = NULL,
#                           password = NULL, ...) {
#  
#    con <- dbConnect(PostgreSQL(), host = host %||% "", dbname = dbname %||% "",
#      user = user, password = password %||% "", port = port %||% "", ...)
#  
#    src_sql("postgres", con)
#  }

## ------------------------------------------------------------------------
#' @export
src_desc.src_postgres <- function(con) {
  info <- dbGetInfo(con)
  host <- if (info$host == "") "localhost" else info$host

  paste0("postgres ", info$serverVersion, " [", info$user, "@",
    host, ":", info$port, "/", info$dbname, "]")
}

## ---- eval = FALSE-------------------------------------------------------
#  tbl.src_mssql <- function(src, from, ...) {
#    tbl_sql("mssql", src = src, from = from, ...)
#  }

## ---- eval = FALSE-------------------------------------------------------
#  copy_nycflights13(src_mssql(...))
#  copy_lahman(src_mssql(...))

