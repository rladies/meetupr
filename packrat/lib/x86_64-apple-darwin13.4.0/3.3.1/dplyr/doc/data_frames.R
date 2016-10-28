## ---- echo = FALSE, message = FALSE--------------------------------------
knitr::opts_chunk$set(collapse = T, comment = "#>")
options(tibble.print_min = 4L, tibble.print_max = 4L)
library(dplyr)

## ------------------------------------------------------------------------
location(iris)

## ------------------------------------------------------------------------
iris2 <- iris
location(iris2)

## ------------------------------------------------------------------------
changes(iris2, iris)

## ------------------------------------------------------------------------
iris2$Sepal.Length <- iris2$Sepal.Length * 2
changes(iris, iris2)

## ------------------------------------------------------------------------
iris3 <- mutate(iris, Sepal.Length = Sepal.Length * 2)
changes(iris3, iris)

