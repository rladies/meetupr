---
title: "R-Ladies chapters on meetup.com"
author: "Claudia Vitolo"
date: "2020-10-16"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{R-Ladies chapters on meetup.com}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---



## Install and load packages


```r
devtools::install_github("rladies/meetupr")
```


```r
library("purrr")
library("dplyr")
library("lubridate")
library("tidyr")
library("ggplot2")
library("meetupr")
library("raster")
```

## How many R-Ladies chapter are out there?


```r
meetup_groups <- find_groups(text = "r-ladies")

# Keep only groups whose name contains the string "r-ladies"
meetup_groups <- meetup_groups[which(grepl("r-ladies",
                                           tolower(meetup_groups$name))),]
```

## Chapters that require attention

*Which chapters do not belong to R-Ladies Global?* Needed for to migrate to meetup pro


```r
chapters2migrate <- meetup_groups[meetup_groups$organizer != "R-Ladies Global",]
chapters2migrate$name
```

## Onboarded chapters

*Which chapters have been fully onboarded by R-Ladies Global?*


```r
# Keep only groups whose organiser is "R-Ladies Global"
# and remove the 'resources' column
rladies <- meetup_groups[meetup_groups$organizer == "R-Ladies Global", 1:20]
```

## Growth


```r
df <- data.frame(Date = as.Date(rladies$created), count = 1) %>%
  complete(Date = seq.Date(min(Date), max(Date), by="day")) %>%
  # mutate(dategroup = lubridate::floor_date(Date, "6 months")) %>%
  mutate(dategroup = format(Date, "%Y-%m")) %>%
  group_by(dategroup) %>%
  summarise(count_ymonth = sum(count, na.rm = TRUE)) %>%
  mutate(cum_sum = cumsum(count_ymonth))

ggplot(data = df, aes(x = dategroup, y = cum_sum)) +
  geom_bar(stat = "identity", color = "#88398A", fill = "#88398A") +
  theme_bw() + xlab("") + ylab("Number of chapters") +
  ggtitle("R-Ladies Global chapter growth") +
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1)) +
  scale_x_discrete(breaks = df$dategroup[seq(1, length(df$dategroup), by = 2)])
```

## Pie chart


```r
df <- data.frame(country = rladies$country) %>%
  merge(raster::ccodes()[,c("ISO2", "continent")],
        by.x = "country", by.y = "ISO2", all.x = T) %>%
  group_by(continent) %>%
  summarise(count = n())

# Blank theme
blank_theme <- theme_minimal()+
  theme(
  axis.title.x = element_blank(),
  axis.title.y = element_blank(),
  panel.border = element_blank(),
  panel.grid=element_blank(),
  axis.ticks = element_blank(),
  plot.title = element_text(size = 14, face = "bold")
  )

# Piechart
ggplot(df, aes(x = "", y = count, fill = continent)) +
  geom_bar(width = 1, stat = "identity") +
  coord_polar("y", start=0) +
  scale_fill_brewer("Continent", palette = 3) + blank_theme +
  theme(axis.text.x = element_blank())
```

## Chapter activity

Let us now extract the number of past events and the dates of last and next events, for each chapter.


```r
meetup_groups$past_events <- 0
meetup_groups$date_last_event <- NA
meetup_groups$date_next_event <- NA

# To avoid to exceed API request limit we use Jesse Maegan's solution:
# https://github.com/rladies/meetupr/issues/30
slowly <- function(f, delay = 0.5) {
  function(...) {
    Sys.sleep(delay)
    f(...)
  }
}
x <- map(meetup_groups$urlname,
         slowly(safely(get_events)),
         event_status = c("past", "upcoming"))

for (i in seq_along(x)){
  message(meetup_groups$urlname[i])
  if (is.null(x[[i]]$error)){
    temp_table <- x[[i]]$result
    if ("past" %in% temp_table$status){
      past <- temp_table %>%
        group_by(status) %>%
        summarise(count = n(),
                  mydates = format(max(local_date), '%Y-%m-%d'))
    meetup_groups$past_events[i] <- past$count[past$status == "past"]
    meetup_groups$date_last_event[i] <- past$mydates[past$status == "past"]
    }else{
      meetup_groups$past_events[i] <- 0
      meetup_groups$date_last_event[i] <- NA
    }
    if ("upcoming" %in% temp_table$status){
      upcoming <- temp_table %>%
        group_by(status) %>%
        summarise(count = n(),
                  mydates = format(min(local_date), '%Y-%m-%d'))
      meetup_groups$date_next_event[i] <- upcoming$mydates[upcoming$status == "upcoming"]
    }else{
      meetup_groups$date_next_event[i] <- NA
    }
  }else{
    meetup_groups$past_events[i] <- 0
    meetup_groups$date_last_event[i] <- NA
    meetup_groups$date_next_event[i] <- NA
  }
}
```

*Which chapters have never had events and have not even planned one (and have been created more than 6 months ago)?*


```r
no_events <- meetup_groups %>%
  filter(past_events == 0,
         is.na(date_next_event),
         created < Sys.Date() - 6*30) %>%
  arrange(created)
```

*Which chapters had no events in the past 6 months and have not even planned one?*


```r
no_recent_events <- meetup_groups %>%
  filter(date_last_event < as.POSIXct("2019-03-29"),
         is.na(date_next_event)) %>%
  arrange(date_last_event)
```
