#' @keywords internal
"_PACKAGE"

# Global variable bindings for R CMD check
utils::globalVariables(c(
  # attendee_mappings
  "id",
  "country",
  "venues_country",
  "field_name"
))

# nocov start
knit_vignettes <- function() {
  proc <- list.files(
    "vignettes",
    "Rmd$",
    full.names = TRUE
  )

  lapply(proc, function(x) {
    fig_path <- "static"
    knitr::knit(
      x,
      gsub("\\.Rmd$", ".html", x)
    )
    imgs <- list.files(fig_path, full.names = TRUE)
    sapply(imgs, function(x) {
      file.copy(
        x,
        file.path("vignettes", fig_path, basename(x)),
        overwrite = TRUE
      )
    })
    invisible(unlink(fig_path, recursive = TRUE))
  })

  list(
    "Knit vignettes",
    sapply(proc, basename)
  )
} # nocov end
