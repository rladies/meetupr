#' CI Authentication with Encrypted Token Rotation
#'
#' Manage Meetup API authentication in CI environments using
#' encrypted tokens that auto-refresh when expired.
#'
#' @param path Path to encrypted token file. Default
#'   `".meetupr.rds"`.
#' @param password Encryption password. If NULL, generates random
#'   password.
#' @template client_name
#' @param ... Additional arguments to [meetupr_client()].
#'
#' @return
#' - [meetupr_encrypt_setup()]: Encryption password (invisibly)
#' - [meetupr_encrypt_load()]: httr2_token object
#'
#' @details
#' Setup: Run [meetupr_auth()], then [meetupr_encrypt_setup()]. Commit
#' the encrypted file and add password to CI secrets as
#' `meetupr_encrypt_pwd`.
#'
#' [meetupr_encrypt_load()] checks token expiration and refreshes only
#' when needed, saving the rotated token back to the encrypted
#' file.
#'
#' @examples
#' \dontrun{
#' meetupr_auth()
#' password <- meetupr_encrypt_setup()
#'
#' # In CI
#' token <- meetupr_encrypt_load()
#' }
#'
#' @name meetupr_encrypt
NULL

#' @describeIn meetupr_encrypt Setup encrypted token for CI
#' @export
meetupr_encrypt_setup <- function(
  path = ".meetupr.rds",
  password = NULL,
  client_name = get_client_name(),
  ...
) {
  rlang::check_installed("cyphr", reason = "to encrypt tokens")
  rlang::check_installed(
    "sodium",
    reason = "for token encryption"
  )

  if (!has_auth(client_name = client_name)) {
    cli::cli_abort(
      c(
        "No authentication found",
        "i" = "Run {.code meetupr_auth()} first"
      )
    )
  }

  flow_params <- meetupr_oauth_flow_params()

  token <- httr2::oauth_token_cached(
    client = meetupr_client(
      client_name = client_name,
      ...
    ),
    flow = httr2::oauth_flow_auth_code,
    flow_params = meetupr_oauth_flow_params()
  )

  if (is_empty(token)) {
    cli::cli_abort(c(
      "Failed to retrieve cached token",
      "i" = "Run {.code meetupr_auth()} first"
    ))
  }

  if (is.null(password)) {
    password <- sodium::bin2hex(sodium::random(32))
    cli::cli_alert_info("Generated encryption password")
  }

  key <- cyphr::key_sodium(sodium::hex2bin(password))
  tempfile <- withr::local_tempfile(fileext = ".rds")

  saveRDS(token, tempfile)

  cyphr::encrypt_file(
    tempfile,
    key = key,
    dest = path
  )

  cli::cli_h2("Encrypted Token Setup Complete")
  cli::cli_bullets(
    c(
      "v" = paste(
        "Encrypted token saved to",
        "{.path {path}}"
      ),
      "i" = "Commit this file to your repository",
      "!" = paste(
        "Add encryption password to CI secrets as",
        "{.envvar {client_name}_encrypt_pwd}:"
      ),
      " " = password
    )
  )

  if (
    rlang::is_installed("clipr") &&
      clipr::clipr_available()
  ) {
    clipr::write_clip(password)
    cli::cli_alert_success("Password copied to clipboard")
  }

  invisible(password)
}

#' @describeIn meetupr_encrypt Load and refresh encrypted token
#' @export
meetupr_encrypt_load <- function(
  path = get_encrypted_path(),
  client_name = get_client_name(),
  password = meetupr_key_get(
    "encrypt_pwd",
    client_name = client_name
  ),
  ...
) {
  rlang::check_installed("cyphr", reason = "to decrypt tokens")
  rlang::check_installed(
    "sodium",
    reason = "for token decryption"
  )

  if (!file.exists(path)) {
    cli::cli_abort(
      c(
        "Encrypted token file not found at",
        "{.path {path}}"
      )
    )
  }

  if (is_empty(password)) {
    cli::cli_abort(
      c(
        "Encryption password not found",
        "x" = "Environment variable {.val {client_name}_encrypt_pwd} is empty",
        "i" = c(
          "Set in CI secrets or run",
          "{.code {client_name}_encrypt_setup()}"
        )
      )
    )
  }

  key <- cyphr::key_sodium(sodium::hex2bin(password))
  temp_token <- withr::local_tempfile(fileext = ".rds")

  cyphr::decrypt_file(
    path,
    key = key,
    dest = temp_token
  )

  token <- readRDS(temp_token)

  if (check_debug_mode()) {
    cli::cli_alert_info("Loaded encrypted token")
  }

  token_age <- Sys.time() -
    as.POSIXct(
      token$expires_at,
      origin = "1970-01-01"
    )

  if (!token_age >= 0) {
    if (check_debug_mode()) {
      cli::cli_alert_info("Token still valid, no refresh needed")
    }
    return(token)
  }

  if (check_debug_mode()) {
    cli::cli_alert_info("Token expired, refreshing")
  }

  new_token <- tryCatch(
    {
      client <- meetupr_client(
        client_name = client_name,
        ...
      )
      resp <- httr2::request(meetupr_api_urls()$token) |>
        httr2::req_body_form(
          client_key = client$id,
          client_secret = client$secret,
          grant_type = "refresh_token",
          refresh_token = token$refresh_token
        ) |>
        httr2::req_perform() |>
        httr2::resp_body_json()

      structure(
        list(
          token_type = resp$token_type,
          access_token = resp$access_token,
          expires_at = unclass(
            Sys.time() + as.numeric(resp$expires_in)
          ),
          refresh_token = resp$refresh_token
        ),
        class = "httr2_token"
      )
    },
    error = function(e) {
      cli::cli_abort(
        c(
          "Failed to refresh OAuth token",
          "x" = conditionMessage(e),
          "i" = paste(
            "Re-run {.code meetupr_encrypt_setup()}",
            "to generate new token"
          )
        )
      )
    }
  )

  saveRDS(new_token, temp_token)
  cyphr::encrypt_file(
    temp_token,
    key = key,
    dest = path
  )

  if (check_debug_mode()) {
    cli::cli_alert_success(
      paste(
        "Updated encrypted token at",
        "{.path {path}}"
      )
    )
  }

  new_token
}

#' @describeIn meetupr_encrypt Get encrypted token path
#' @export
get_encrypted_path <- function(client_name = get_client_name()) {
  path <- meetupr_key_get(
    "encrypt_path",
    client_name = client_name,
    error = FALSE
  )

  if (is_empty(path)) {
    path <- sprintf(".%s.rds", client_name)
  }

  normalize_path(path, mustWork = FALSE)
}

#' Resolve JWT private key input (path or PEM string)
#'
#' Looks up the JWT key from the function argument, keyring,
#' environment variable, or the default jwt file path.
#'
#' @param jwt_token Path or PEM/SSH string containing the private key.
#' @param client_name OAuth client name
#' @return Character scalar: normalized file path or PEM string, or NA.
#' @keywords internal
#' @noRd
get_jwt_token <- function(
  jwt_token = NULL,
  client_name = get_client_name()
) {
  # If user supplied an explicit value, accept path or PEM/string
  if (!is_empty(jwt_token)) {
    if (
      is.character(jwt_token) &&
        length(jwt_token) == 1L &&
        file.exists(jwt_token)
    ) {
      return(normalize_path(jwt_token, winslash = "/"))
    }
    if (
      is.character(jwt_token) &&
        grepl(
          "^-----BEGIN .*PRIVATE KEY",
          jwt_token,
          perl = TRUE
        )
    ) {
      return(jwt_token)
    }
    # Accept single-line secrets or PEM without header/footer as-is
    return(as.character(jwt_token))
  }

  # Check keyring / package credentials
  token <- meetupr_key_get(
    "jwt_token",
    client_name = client_name,
    error = FALSE
  )
  if (!is_empty(token)) {
    if (is.character(token) && length(token) == 1L && file.exists(token)) {
      return(normalize_path(token))
    }
    return(as.character(token))
  }

  # Check environment variable used for CI/secrets
  env_token <- Sys.getenv("meetupr_jwt_token", "")
  if (nzchar(env_token)) {
    if (file.exists(env_token)) {
      return(normalize_path(env_token))
    }
    return(env_token)
  }

  # Fallback to default path (~/.ssh/<client>.rsa)
  token_path <- get_jwt_path(client_name = client_name)
  if (file.exists(token_path)) {
    return(normalize_path(token_path))
  }

  NA_character_
}

get_jwt_path <- function(client_name = get_client_name()) {
  path <- meetupr_key_get(
    "jwt_token",
    client_name = client_name,
    error = FALSE
  )

  if (is_empty(path)) {
    path <- file.path(
      fs::path_home(),
      ".ssh",
      paste0(client_name, ".rsa")
    )
  }

  normalize_path(path, mustWork = FALSE)
}
