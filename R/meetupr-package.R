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
#' Knit vignettes
#'
#' This function processes all R Markdown files in the `vignettes` directory,
#' knitting them into HTML format. It also handles the copying of any
#' generated figures to the appropriate location within the `vignettes/static`
#' directory. After processing, it cleans up any temporary files created during
#' the knitting process.
#' The function is intended for internal use in knitting the vignettes
#' during development and get record vcr
#' cassettes.
#' @return A list containing a summary of the knitting process, including the
#' names of the processed files.
#' @keywords internal
#' @noRd
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
