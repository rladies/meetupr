#' @keywords internal
"_PACKAGE"

# Global variable bindings for R CMD check
utils::globalVariables(c(
  # attendee_mappings
  "id",
  "member_member_url",
  "member_member_photo_base_url",

  # explore functions
  "field_name",

  # groups_mappings
  "memberships_total_count",
  "membership_metadata_status",

  # members_mappings
  "node_id",
  "node_name",
  "node_member_url",
  "node_member_photo_base_url",
  "metadata_status",
  "metadata_role",

  # process_pro_event_data
  "eventUrl",
  "eventType",
  "venue_postalCode",
  "dateTime",
  "datetime",

  # process_pro_group_data
  "foundedDate",
  "memberships.count",
  "joinMode",
  "category.id",
  "category.name",
  "country_name",
  "pastEvents.count",
  "upcomingEvents.count",
  "membershipMetadata.status",
  "isPrivate",

  # rsvp_mappings
  "status"
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
