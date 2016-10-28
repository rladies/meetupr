## ---- echo=FALSE---------------------------------------------------------
library("stringr")
knitr::opts_chunk$set(comment = "#>", collapse = TRUE)

## ------------------------------------------------------------------------
strings <- c(
  "apple", 
  "219 733 8965", 
  "329-293-8753", 
  "Work: 579-499-7527; Home: 543.355.3679"
)
phone <- "([2-9][0-9]{2})[- .]([0-9]{3})[- .]([0-9]{4})"

## ------------------------------------------------------------------------
# Which strings contain phone numbers?
str_detect(strings, phone)
str_subset(strings, phone)

## ------------------------------------------------------------------------
# Where in the string is the phone number located?
(loc <- str_locate(strings, phone))
str_locate_all(strings, phone)

## ------------------------------------------------------------------------
# What are the phone numbers?
str_extract(strings, phone)
str_extract_all(strings, phone)
str_extract_all(strings, phone, simplify = TRUE)

## ------------------------------------------------------------------------
# Pull out the three components of the match
str_match(strings, phone)
str_match_all(strings, phone)

## ------------------------------------------------------------------------
str_replace(strings, phone, "XXX-XXX-XXXX")
str_replace_all(strings, phone, "XXX-XXX-XXXX")

## ------------------------------------------------------------------------
col2hex <- function(col) {
  rgb <- col2rgb(col)
  rgb(rgb["red", ], rgb["green", ], rgb["blue", ], max = 255)
}

# Goal replace colour names in a string with their hex equivalent
strings <- c("Roses are red, violets are blue", "My favourite colour is green")

colours <- str_c("\\b", colors(), "\\b", collapse="|")
# This gets us the colours, but we have no way of replacing them
str_extract_all(strings, colours)

# Instead, let's work with locations
locs <- str_locate_all(strings, colours)
Map(function(string, loc) {
  hex <- col2hex(str_sub(string, loc))
  str_sub(string, loc) <- hex
  string
}, strings, locs)

## ------------------------------------------------------------------------
matches <- col2hex(colors())
names(matches) <- str_c("\\b", colors(), "\\b")

str_replace_all(strings, matches)

