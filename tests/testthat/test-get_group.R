test_that("get_group_members() works with one status", {
  mock_if_no_auth()
  vcr::use_cassette("get_group_members", {
    members <- get_group_members("rladies-lagos")
  })
  expect_s3_class(members, "data.frame")
})

test_that("get_group_members validates rlang", {
  expect_error(get_group_members("valid_url", extra_parameter = "unexpected"))
})

test_that("get_group returns valid data", {
  vcr::use_cassette("get_group", {
    res <- get_group("rladies-lagos")
  })
  expect_s3_class(res, "meetup_group")
  expect_true(is.list(res))
  expect_named(
    res,
    c(
      "id",
      "name",
      "description",
      "urlname",
      "link",
      "location",
      "timezone",
      "created",
      "members",
      "total_events",
      "organizer",
      "category",
      "photo_url"
    )
  )
})


test_that("process_group_data parses data when non-empty", {
  data <- list(
    id = "test_id",
    name = "test_name",
    description = "test description",
    urlname = "test_urlname",
    link = "test_link",
    city = "test_city",
    country = "test_country",
    timezone = "test_timezone",
    foundedDate = "2023-01-01T00:00:00.000Z",
    stats = list(memberCounts = list(all = 100)),
    events = list(totalCount = 10),
    organizer = list(id = "org_id", name = "org_name"),
    topicCategory = list(id = "cat_id", name = "cat_name"),
    keyGroupPhoto = list(baseUrl = "photo_url")
  )
  res <- process_group_data(data)
  expect_s3_class(res, "meetup_group")
  expect_equal(res$name, "test_name")
})

test_that("process_group_data handles edge cases", {
  expect_error(process_group_data(NULL), "No group data returned")
  expect_error(process_group_data(list()), "No group data returned")
})

test_that("extract_group_location returns correct location", {
  data <- list(city = "City Test", country = "Country Test")
  res <- extract_group_location(data)
  expect_equal(res$city, "City Test")
  expect_equal(res$country, "Country Test")
})

test_that("extract_group_location handles NULL input", {
  res <- extract_group_location(list())
  expect_null(res$city)
  expect_null(res$country)
})

test_that("extract_organizer_info extracts valid organizer data", {
  data <- list(id = "123", name = "Organizer Name")
  res <- extract_organizer_info(data)
  expect_equal(res$id, "123")
  expect_equal(res$name, "Organizer Name")
})

test_that("extract_organizer_info handles NULL input", {
  res <- extract_organizer_info(NULL)
  expect_null(res)
})

test_that("extract_category_info extracts valid category data", {
  data <- list(id = "456", name = "Category Name")
  res <- extract_category_info(data)
  expect_equal(res$id, "456")
  expect_equal(res$name, "Category Name")
})

test_that("extract_category_info handles NULL input", {
  res <- extract_category_info(NULL)
  expect_null(res)
})

test_that("print.meetup_group outputs full data correctly", {
  group <- structure(
    list(
      name = "Tech Enthusiasts",
      urlname = "tech-enthusiasts",
      link = "http://meetup.com/tech-enthusiasts",
      location = list(city = "San Francisco", country = "USA"),
      timezone = "PST",
      created = as.POSIXct("2020-01-01"),
      members = 500,
      total_events = 100,
      organizer = list(name = "Jane Doe"),
      category = list(name = "Technology"),
      description = "A group for tech lovers"
    ),
    class = c("meetup_group", "list")
  )

  expect_snapshot(print.meetup_group(group))
})

test_that("print.meetup_group handles missing optional fields", {
  group <- structure(
    list(
      name = "Beginner Coders",
      urlname = "beginner-coders",
      link = "http://meetup.com/beginner-coders",
      location = NULL,
      timezone = "EST",
      created = as.POSIXct("2021-06-15"),
      members = 200,
      total_events = 20,
      organizer = NULL,
      category = NULL,
      description = NA_character_
    ),
    class = c("meetup_group", "list")
  )
  expect_snapshot(print.meetup_group(group))
})

test_that("print.meetup_group handles long descriptions", {
  group <- structure(
    list(
      name = "History Lovers",
      urlname = "history-lovers",
      link = "http://meetup.com/history-lovers",
      location = list(city = "Boston", country = "USA"),
      timezone = "EST",
      created = as.POSIXct("2019-09-20"),
      members = 1000,
      total_events = 50,
      organizer = list(name = "John Smith"),
      category = list(name = "Education"),
      description = paste(
        rep("This is a great group for history enthusiasts. ", 10),
        collapse = ""
      )
    ),
    class = c("meetup_group", "list")
  )
  expect_snapshot(print.meetup_group(group))
})

test_that("print.meetup_group handles edge case with location parts", {
  group <- structure(
    list(
      name = "Science Gurus",
      urlname = "science-gurus",
      link = "http://meetup.com/science-gurus",
      location = list(city = NULL, country = "USA"),
      timezone = "CST",
      created = as.POSIXct("2018-03-01"),
      members = 300,
      total_events = 30,
      organizer = list(name = "Sarah Lee"),
      category = NULL,
      description = "Discussing science topics"
    ),
    class = c("meetup_group", "list")
  )
  expect_snapshot(print.meetup_group(group))
})
