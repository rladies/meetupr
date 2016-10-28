## ---- echo = FALSE, message = FALSE--------------------------------------
knitr::opts_chunk$set(collapse = T, comment = "#>")
options(tibble.print_min = 4L, tibble.print_max = 4L)
library(dplyr)

## ------------------------------------------------------------------------
# NSE version:
summarise(mtcars, mean(mpg))

# SE versions:
summarise_(mtcars, ~mean(mpg))
summarise_(mtcars, quote(mean(mpg)))
summarise_(mtcars, "mean(mpg)")

## ------------------------------------------------------------------------
constant1 <- function(n) ~n
summarise_(mtcars, constant1(4))

## ------------------------------------------------------------------------
n <- 10
dots <- list(~mean(mpg), ~n)
summarise_(mtcars, .dots = dots)

summarise_(mtcars, .dots = setNames(dots, c("mean", "count")))

## ------------------------------------------------------------------------
library(lazyeval)
# Interp works with formulas, quoted calls and strings (but formulas are best)
interp(~ x + y, x = 10)
interp(quote(x + y), x = 10)
interp("x + y", x = 10)

# Use as.name if you have a character string that gives a variable name
interp(~ mean(var), var = as.name("mpg"))
# or supply the quoted name directly
interp(~ mean(var), var = quote(mpg))

## ------------------------------------------------------------------------
interp(~ f(a, b), f = quote(mean))
interp(~ f(a, b), f = as.name("+"))
interp(~ f(a, b), f = quote(`if`))

## ------------------------------------------------------------------------
interp(~ x + y, .values = list(x = 10))

# You can also interpolate variables defined in the current
# environment, but this is a little risky becuase it's easy
# for this to change without you realising
y <- 10
interp(~ x + y, .values = environment())

