# Stuff to set up on load, run this last (hence the filename)
# Taken from googlesheets3/zzz.R
.onLoad <- function(libname, pkgname) {

  op <- options()
  op.meetupr <- list(
    meetupr.consumer_key     = "2vagj0ut3btomqbb32tca763m1",
    meetupr.consumer_secret  = "k73s3jrah57hp9ej21e8dslnl5"
  )
  toset <- !(names(op.meetupr) %in% names(op))
  if(any(toset)) options(op.meetupr[toset])

  meetup_call_onload()

  invisible()
}


## quiets concerns of R CMD checks
utils::globalVariables(
  c("foundedDate", "memberships.count",
    "joinMode",
    "category.id",
    "category.name",
    "country_name",
    "memberUrl",
    "memberPhoto.baseUrl",
    "organizedGroupCount",
    "text",
    "likeCount",
    "member.id",
    "member.name",
    "user.id",
    "user.name",
    "user.memberUrl",
    "event.id",
    "event.title",
    "event.eventUrl",
    "isHost",
    "guestsCount",
    "status",
    "createdAt",
    "updatedAt",
    "eventUrl",
    "venue_postalCode",
    "dateTime",
    "node.id",
    "node.name",
    "node.memberUrl",
    "node.memberPhoto.baseUrl",
    "metadata.status",
    "metadata.role",
    "metadata.joinedDate",
    "metadata.mostRecentVisitDate",
    "group_sorter",
    "event_sorter",
    "res"
    )
  )
