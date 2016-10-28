## ---- echo = FALSE, message = FALSE--------------------------------------
knitr::opts_chunk$set(comment = "")
library(curl)

## ------------------------------------------------------------------------
req <- curl_fetch_memory("https://httpbin.org/get")
str(req)
parse_headers(req$headers)
cat(rawToChar(req$content))

## ------------------------------------------------------------------------
tmp <- tempfile()
curl_download("https://httpbin.org/get", tmp)
cat(readLines(tmp), sep = "\n")

## ------------------------------------------------------------------------
con <- curl("https://httpbin.org/get")
open(con)

# Get 3 lines
out <- readLines(con, n = 3)
cat(out, sep = "\n")

# Get 3 more lines
out <- readLines(con, n = 3)
cat(out, sep = "\n")

# Get remaining lines
out <- readLines(con)
close(con)
cat(out, sep = "\n")

## ------------------------------------------------------------------------
pool <- new_pool()
cb <- function(req){cat("done:", req$url, ": HTTP:", req$status, "\n")}
curl_fetch_multi('https://www.google.com', done = cb, pool = pool)
curl_fetch_multi('https://cloud.r-project.org', done = cb, pool = pool)
curl_fetch_multi('https://httpbin.org/blabla', done = cb, pool = pool)

## ------------------------------------------------------------------------
# This actually performs requests:
out <- multi_run(pool = pool)
print(out)

## ------------------------------------------------------------------------
# This is OK
curl_download('https://cran.r-project.org/CRAN_mirrors.csv', 'mirrors.csv')
mirros <- read.csv('mirrors.csv')
unlink('mirrors.csv')

## ---- echo = FALSE, message = FALSE, warning=FALSE-----------------------
close(con)
rm(con)

## ------------------------------------------------------------------------
req <- curl_fetch_memory('https://cran.r-project.org/CRAN_mirrors.csv')
print(req$status_code)

## ------------------------------------------------------------------------
# Oops a typo!
req <- curl_fetch_disk('https://cran.r-project.org/CRAN_mirrorZ.csv', 'mirrors.csv')
print(req$status_code)

# This is not the CSV file we were expecting!
head(readLines('mirrors.csv'))
unlink('mirrors.csv')

## ------------------------------------------------------------------------
h <- new_handle()
handle_setopt(h, copypostfields = "moo=moomooo");
handle_setheaders(h,
  "Content-Type" = "text/moo",
  "Cache-Control" = "no-cache",
  "User-Agent" = "A cow"
)

## ------------------------------------------------------------------------
req <- curl_fetch_memory("http://httpbin.org/post", handle = h)
cat(rawToChar(req$content))

## ------------------------------------------------------------------------
con <- curl("http://httpbin.org/post", handle = h)
cat(readLines(con), sep = "\n")

## ---- echo = FALSE, message = FALSE, warning=FALSE-----------------------
close(con)

## ------------------------------------------------------------------------
tmp <- tempfile()
curl_download("http://httpbin.org/post", destfile = tmp, handle = h)
cat(readLines(tmp), sep = "\n")

## ------------------------------------------------------------------------
curl_fetch_multi("http://httpbin.org/post", handle = h, done = function(res){
  cat("Request complete! Response content:\n")
  cat(rawToChar(res$content))
})

# Perform the request
out <- multi_run()

## ------------------------------------------------------------------------
# Start with a fresh handle
h <- new_handle()

# Ask server to set some cookies
req <- curl_fetch_memory("http://httpbin.org/cookies/set?foo=123&bar=ftw", handle = h)
req <- curl_fetch_memory("http://httpbin.org/cookies/set?baz=moooo", handle = h)
handle_cookies(h)

# Unset a cookie
req <- curl_fetch_memory("http://httpbin.org/cookies/delete?foo", handle = h)
handle_cookies(h)

## ------------------------------------------------------------------------
req1 <- curl_fetch_memory("https://httpbin.org/get", handle = new_handle())
req2 <- curl_fetch_memory("http://www.r-project.org", handle = new_handle())

## ------------------------------------------------------------------------
h <- new_handle()
system.time(curl_fetch_memory("https://api.github.com/users/ropensci", handle = h))
system.time(curl_fetch_memory("https://api.github.com/users/rstudio", handle = h))

## ------------------------------------------------------------------------
handle_reset(h)

## ------------------------------------------------------------------------
# Posting multipart
h <- new_handle()
handle_setform(h,
  foo = "blabla",
  bar = charToRaw("boeboe"),
  description = form_file(system.file("DESCRIPTION")),
  logo = form_file(file.path(Sys.getenv("R_DOC_DIR"), "html/logo.jpg"), "image/jpeg")
)
req <- curl_fetch_memory("http://httpbin.org/post", handle = h)

## ------------------------------------------------------------------------
library(magrittr)

new_handle() %>% 
  handle_setopt(copypostfields = "moo=moomooo") %>% 
  handle_setheaders("Content-Type" = "text/moo", "Cache-Control" = "no-cache", "User-Agent" = "A cow") %>%
  curl_fetch_memory(url = "http://httpbin.org/post") %$% content %>% rawToChar %>% cat

