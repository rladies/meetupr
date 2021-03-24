test_that("get_event_attendees works", {
  urlname <- "rladies-nashville"
    vcr::use_cassette("get_event_attendees", {
     attendees <- get_event_attendees(urlname, "234968855")
  })

  expect_s3_class(attendees, "data.frame")
})
