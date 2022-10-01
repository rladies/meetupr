# test_that("get_pro_groups() works", {
#   vcr::use_cassette("get_pro_groups", {
#     groups <- get_pro_groups(urlname = "rladies") |> head(2)
#   })
#   expect_s3_class(groups, "data.frame")
#   expect_true(
#     all(
#       names(groups) %in% c("id", "name", "urlname", "description", "latitude", "longitude",
#                            "city", "state", "country", "membership_status", "members",
#                            "past_events_count", "upcoming_events_count", "created",
#                            "proJoinDate", "timezone", "join_mode", "who", "is_private")
#     ))
# })
#
# test_that("get_pro_events() works", {
#   urlname <- "rladies"
#   status = "UPCOMING"
#   vcr::use_cassette("get_pro_events", {
#     groups <- get_pro_events(urlname = urlname, status = status)
#   })
#   expect_s3_class(events, "data.frame")
#   expect_true(
#     all(
#       names(events) %in% c("id", "title", "link", "status", "duration", "going", "waiting",
#                            "description", "event_type", "group_name", "group_urlname",
#                            "venue_lat", "venue_lon", "venue_name", "venue_address",
#                            "venue_city", "venue_state", "venue_zip", "venue_country", "time")
#     ))
# })
