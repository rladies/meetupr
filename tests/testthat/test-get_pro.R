test_that("get_pro_groups() works", {
  mock_if_no_auth()
  vcr::local_cassette("get_pro_groups")
  groups <- get_pro_groups(urlname = "rladies")
  expect_s3_class(groups, "data.frame")
  expect_gt(nrow(groups), 10)
})

test_that("get_pro_events() works", {
  mock_if_no_auth()
  vcr::local_cassette("get_pro_events")
  skip_if_not(is_self_pro(), "Skipping Pro tests")
  events <- get_pro_events(
    urlname = "rladies",
    status = "cancelled"
  )
  expect_s3_class(events, "data.frame")
  expect_gt(nrow(events), 5)
})

test_that("get_pro_events() warns for non-Pro organizers", {
  mock_if_no_auth()
  vcr::local_cassette("get_pro_events_non_pro")
  local_mocked_bindings(
    is_self_pro = function() FALSE
  )
  expect_warning(
    get_pro_events(urlname = "rladies"),
    "The authenticated user must have Pro access"
  )
})

test_that("is_self_pro returns TRUE for Pro organizers", {
  mock_resp <- list(data = list(self = list(isProOrganizer = TRUE)))
  local_mocked_bindings(
    meetup_query = function(...) mock_resp,
    meetup_auth_status = function(...) TRUE
  )
  expect_true(is_self_pro())
})

test_that("is_self_pro returns FALSE for non-Pro organizers", {
  mock_resp <- list(data = list(self = list(isProOrganizer = FALSE)))
  local_mocked_bindings(
    meetup_query = function(...) mock_resp
  )
  expect_false(is_self_pro())

  local_mocked_bindings(
    meetup_auth_status = function(...) FALSE
  )
  expect_false(is_self_pro())
})
