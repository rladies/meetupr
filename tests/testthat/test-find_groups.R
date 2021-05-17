test_that("find_groups() success case", {

  vcr::use_cassette("find_groups", {
    groups <- find_groups(text = "R-Ladies", radius = 1)
  })

  expect_s3_class(groups, "data.frame")
})

test_that("find_groups() can correctly get 2 pages", {

  # Meetup defaults to 200 items per page
  # Issue #111 reported a two-page request duplicating the first page
  vcr::use_cassette("find_groups_2_pages", {
    groups <- find_groups(text = "Ansible", radius = 'global')
  })

  expect_equal(nrow(groups), 323)
})

test_that("find_groups() can correctly get 3 pages", {

  # Meetup defaults to 200 items per page
  # Issue #111 suggested that the bug might be specific to exactly 2
  # pages, so here we test that three pages works as well
  vcr::use_cassette("find_groups_3_pages", {
    groups <- find_groups(text = "London-Pub", radius = 'global')
  })

  expect_equal(nrow(groups), 411)
})
