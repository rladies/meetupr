## ---- echo = FALSE, message = FALSE--------------------------------------
knitr::opts_chunk$set(collapse = T, comment = "#>")
options(tibble.print_min = 4L, tibble.print_max = 4L)
library(dplyr)

## ---- eval = FALSE-------------------------------------------------------
#  my_db <- src_sqlite("my_db.sqlite3", create = T)

## ---- eval = FALSE-------------------------------------------------------
#  library(nycflights13)
#  flights_sqlite <- copy_to(my_db, flights, temporary = FALSE, indexes = list(
#    c("year", "month", "day"), "carrier", "tailnum"))

## ------------------------------------------------------------------------
flights_sqlite <- tbl(nycflights13_sqlite(), "flights")
flights_sqlite

## ---- eval = FALSE-------------------------------------------------------
#  tbl(my_db, sql("SELECT * FROM flights"))

## ------------------------------------------------------------------------
select(flights_sqlite, year:day, dep_delay, arr_delay)
filter(flights_sqlite, dep_delay > 240)
arrange(flights_sqlite, year, month, day)
mutate(flights_sqlite, speed = air_time / distance)
summarise(flights_sqlite, delay = mean(dep_time))

## ------------------------------------------------------------------------
c1 <- filter(flights_sqlite, year == 2013, month == 1, day == 1)
c2 <- select(c1, year, month, day, carrier, dep_delay, air_time, distance)
c3 <- mutate(c2, speed = distance / air_time * 60)
c4 <- arrange(c3, year, month, day, carrier)

## ------------------------------------------------------------------------
c4

## ------------------------------------------------------------------------
collect(c4)

## ------------------------------------------------------------------------
c4$query

## ------------------------------------------------------------------------
explain(c4)

## ------------------------------------------------------------------------
# In SQLite variable names are escaped by double quotes:
translate_sql(x)
# And strings are escaped by single quotes
translate_sql("x")

# Many functions have slightly different names
translate_sql(x == 1 && (y < 2 || z > 3))
translate_sql(x ^ 2 < 10)
translate_sql(x %% 2 == 10)

# R and SQL have different defaults for integers and reals.
# In R, 1 is a real, and 1L is an integer
# In SQL, 1 is an integer, and 1.0 is a real
translate_sql(1)
translate_sql(1L)

## ---- eval = FALSE-------------------------------------------------------
#  translate_sql(mean(x, trim = T))
#  # Error: Invalid number of args to SQL AVG. Expecting 1

## ------------------------------------------------------------------------
translate_sql(glob(x, y))
translate_sql(x %like% "ab*")

## ------------------------------------------------------------------------
by_tailnum <- group_by(flights_sqlite, tailnum)
delay <- summarise(by_tailnum,
  count = n(),
  dist = mean(distance),
  delay = mean(arr_delay)
)
delay <- filter(delay, count > 20, dist < 2000)
delay_local <- collect(delay)

## ---- eval = FALSE-------------------------------------------------------
#  flights_postgres <- tbl(src_postgres("nycflights13"), "flights")

## ---- eval = FALSE-------------------------------------------------------
#  daily <- group_by(flights_postgres, year, month, day)
#  
#  # Find the most and least delayed flight each day
#  bestworst <- daily %>%
#    select(flight, arr_delay) %>%
#    filter(arr_delay == min(arr_delay) || arr_delay == max(arr_delay))
#  bestworst$query
#  
#  # Rank each flight within a daily
#  ranked <- daily %>%
#    select(arr_delay) %>%
#    mutate(rank = rank(desc(arr_delay)))
#  ranked$query

