
#' Default verbose value
#'
#' Wrapper around
#' ```r
#' getOption("meetupr.verbose", rlang::is_interactive())
#' ```
#'
#' @export
#' @keywords internal
#' @return Result of `"meetupr.verbose"` option. If no `"meetupr.verbose"` option is set, `rlang::is_interactive()` is returned.
meetupr_verbose <- function() {
  getOption("meetupr.verbose", rlang::is_interactive())
}
