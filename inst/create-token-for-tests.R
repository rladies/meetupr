# thanks Jenny Bryan https://github.com/r-lib/gargle/blob/4fcf142fde43d107c6a20f905052f24859133c30/R/secret.R

# token created with the R-Ladies account itself
# otherwise no access to pro endpoints
token_path <- testthat::test_path(".meetup_token.rds")
use_build_ignore(token_path)
use_git_ignore(token_path)
if (file.exists(token_path)) file.remove(token_path)

meetupr::meetup_auth(
  token = NULL,
  new_user = TRUE,
  cache = TRUE,
  set_renv = FALSE,
  token_path = token_path
)

# sodium_key <- sodium::keygen()
# set_renv("MEETUPR_PWD" = sodium::bin2hex(sodium_key))
key <- cyphr::key_sodium(sodium::hex2bin(Sys.getenv("MEETUPR_PWD")))

cyphr::encrypt_file(
  token_path,
  key = key,
  dest = testthat::test_path("secret.rds")
)

