test_that("generator produces similar args as `graphql_file()", {

  find_group_fmls <- as.pairlist(c(
    # provided by generator
    rlang::fn_fmls(function(.file){}),
    # pass through args
    rlang::fn_fmls(gql_find_groups)
  ))
  graphql_file_fmls <- rlang::fn_fmls(graphql_file)

  expect_equal(find_group_fmls, graphql_file_fmls)

})
