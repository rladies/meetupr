# from https://github.com/ropensci/rtweet/blob/1bd1e16d14df8b31a13a8c2f0e0ff0e87ea066d1/R/tokens.R#L256 # nolint
# ------------------------------------------------
has_ext <- function(x) {
  stopifnot(length(x) == 1L)
  x <- basename(x)
  grepl("[[:alnum:]]{1,}\\.[[:alpha:]]{1,}$", x)
}

only_ext <- function(x) {
  if (has_ext(x)) {
    gsub(".*(?=\\.)", "", x, perl = TRUE)
  } else {
    ""
  }
}

no_ext <- function(x) {
  if (has_ext(x)) {
    gsub("(?<=[[:alnum:]]{1})\\..*(?!=\\.)", "", x, perl = TRUE)
  } else {
    x
  }
}

paste_before_ext <- function(x, p) {
  paste0(no_ext(x), p, only_ext(x))
}


uq_filename <- function(file_name) {
  stopifnot(is.character(file_name) && length(file_name) == 1L)
  if (file.exists(file_name)) {
    files <- list.files(dirname(file_name), all.files = TRUE, full.names = TRUE)
    file_name <- paste_before_ext(file_name, 1:1000)
    file_name <- file_name[!file_name %in% files][1]
  }
  file_name
}
