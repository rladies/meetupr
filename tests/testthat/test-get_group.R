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
