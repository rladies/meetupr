## ----setup, include=FALSE------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)
knitr::opts_chunk$set(comment = "")
library(openssl)

## ----eval=FALSE----------------------------------------------------------
#  key <- ec_keygen()
#  pubkey <- as.list(key)$pubkey
#  bin <- write_der(pubkey)
#  print(bin)

## ----echo=FALSE----------------------------------------------------------
# Temp hack because 'jose' is not yet on cran ;)
key <- read_key(system.file("testkey.pem", package = "openssl"))
pubkey <- as.list(key)$pubkey
bin <- write_der(pubkey)
print(bin)

## ------------------------------------------------------------------------
read_pubkey(bin, der = TRUE)

## ------------------------------------------------------------------------
cat(write_pem(pubkey))
cat(write_pem(key, password = NULL))

## ------------------------------------------------------------------------
str <- write_pem(key, password = "supersecret")
cat(str)
read_key(str, password = "supersecret")

## ------------------------------------------------------------------------
str <- write_ssh(pubkey)
print(str)

## ------------------------------------------------------------------------
read_pubkey(str)

## ----eval=FALSE----------------------------------------------------------
#  library(jose)
#  json <- jose::jwk_write(pubkey)
#  jsonlite::prettify(json)

## ----eval=FALSE----------------------------------------------------------
#  mykey <- jose::jwk_read(json)
#  print(mykey)

