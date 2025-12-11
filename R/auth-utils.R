#' Check all authentication methods and return details
#'
#' @template client_name
#' @param silent logical, suppress messages if TRUE
#' @return list with logicals and details for each method
#' @export
#' @examples
#' \dontrun{
#' # Check detailed authentication status with default client name
#' status_details <- meetupr_auth_status()
#'
#' # Check detailed authentication status with a specific client name
#' status_details <- meetupr_auth_status(client_name = "custom_client")
#'
#' # Suppress output messages
#' status_details <- meetupr_auth_status(silent = TRUE)
#' }
meetupr_auth_status <- function(
  client_name = get_client_name(),
  silent = FALSE
) {
  # 1. JWT token
  jwt <- tryCatch(
    get_jwt_token(client_name = client_name),
    error = function(e) NULL
  )

  jwt_issuer <- meetupr_key_get(
    "jwt_issuer",
    client_name = client_name,
    error = FALSE
  )

  client_key <- meetupr_key_get(
    "client_key",
    client_name = client_name,
    error = FALSE
  )

  jwt_valid <- !is_empty(jwt) &&
    !is_empty(jwt_issuer) &&
    !is_empty(client_key)

  if (jwt_valid) {
    if (!silent) {
      cli::cli_alert_success("JWT setup found and is valid")
    }
  } else {
    if (!silent) {
      cli::cli_alert_warning("JWT setup not found or invalid")
    }
  }

  # 2. Encrypted token file
  encrypted_path <- get_encrypted_path(
    client_name = client_name
  )

  encrypt_pwd <- meetupr_key_get(
    "encrypt_pwd",
    client_name = client_name,
    error = FALSE
  )

  encrypted_valid <- !is_empty(encrypt_pwd) &&
    file.exists(encrypted_path)

  if (encrypted_valid) {
    if (!silent) {
      cli::cli_alert_success("Encrypted token found")
    }
  } else {
    if (!silent) {
      cli::cli_alert_warning("Encrypted token not found or password is empty")
    }
  }

  # 3. httr2 OAuth cache
  cache_path <- get_cache_path(client_name)

  if (!dir.exists(cache_path)) {
    if (!silent) {
      cli::cli_alert_danger("Not authenticated: No token cache found")
    }
  }

  cache_files <- list_token_files(cache_path)
  cache_valid <- length(cache_files) > 0

  if (cache_valid) {
    if (!silent) {
      cli::cli_alert_success("Token found in cache")
      if (length(cache_files) > 1) {
        cli::cli_alert_info("Multiple token files found in cache:")
        for (f in cache_files) {
          cli::cli_text(" - {.file {f}}")
        }
      }
    }
  } else {
    if (!silent) {
      cli::cli_alert_danger("Not authenticated: No token found in cache")
    }
  }

  type <- if (jwt_valid) {
    "jwt"
  } else if (encrypted_valid) {
    "encrypted"
  } else if (cache_valid) {
    "cache"
  } else {
    "none"
  }

  # Return detailed status
  list(
    auth = list(
      any = jwt_valid || encrypted_valid || cache_valid,
      client_name = client_name,
      method = type
    ),
    jwt = list(
      available = jwt_valid,
      value = jwt %||% NULL,
      issuer = jwt_issuer %||% NA_character_,
      client_key = client_key %||% NULL
    ),
    encrypted = list(
      available = encrypted_valid,
      pwd = encrypt_pwd %||% NULL,
      path = encrypted_path %||% NA_character_
    ),
    cache = list(
      available = cache_valid,
      files = cache_files %||% NA_character_
    )
  ) |>
    invisible()
}

#' Logical checker
#' @describeIn meetupr_auth_status Check if any
#' authentication method is available
#' @export
has_auth <- function(
  client_name = get_client_name()
) {
  meetupr_auth_status(
    client_name,
    silent = TRUE
  )$auth$any
}

#' Get OAuth Flow Parameters
#'
#' @return List with auth_url and redirect_uri
#' @keywords internal
#' @noRd
meetupr_oauth_flow_params <- function() {
  urls <- meetupr_api_urls()
  list(
    auth_url = urls$auth,
    redirect_uri = urls$redirect
  )
}

#' List token files in cache directory
#'
#' @param cache_path Path to OAuth cache
#' @param pattern File pattern to match
#' @return Character vector of file paths
#' @keywords internal
#' @noRd
list_token_files <- function(
  cache_path = get_cache_path(),
  pattern = "\\.rds(\\.enc)?$"
) {
  if (!dir.exists(cache_path)) {
    return(character(0))
  }

  list.files(
    cache_path,
    pattern = pattern,
    full.names = TRUE
  )
}

#' Get OAuth Cache Path for Client
#' @template client_name
#' @return Path to OAuth cache directory for the client
#' @keywords internal
#' @noRd
get_cache_path <- function(
  client_name = get_client_name()
) {
  file.path(
    httr2::oauth_cache_path(),
    client_name
  )
}

#' Minimal mock for authentication in tests
#'
#' Makes the package believe authentication is available.
#' Use in tests to enable vcr cassettes without real credentials.
#'
#' @param env Environment to set the variables in
#' @param force Logical, force mocking even if auth exists
#' @return Logical, TRUE if mocking was applied
#' @keywords internal
#' @noRd
mock_if_no_auth <- function(
  force = FALSE
) {
  if (has_auth() && !force) {
    return(invisible(FALSE))
  }

  mock_rsa_key <- paste(
    "-----BEGIN RSA PRIVATE KEY-----",
    "MIIEpAIBAAKCAQEA7Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw",
    "Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5",
    "Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5",
    "Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5",
    "Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5Qw5",
    "-----END RSA PRIVATE KEY-----",
    sep = "\n"
  )

  Sys.unsetenv(c(
    "MEETUPR_CLIENT_NAME",
    paste0("meetupr_", valid_keys)
  ))

  Sys.setenv(
    "MEETUPR_CLIENT_NAME" = "testclient",
    "testclient_client_key" = "fake_client_key",
    "testclient_jwt_token" = mock_rsa_key,
    "testclient_jwt_issuer" = "1234567890"
  )
  invisible(TRUE)
}

#' Minimal mock for authentication in tests
#' @keywords internal
#' @noRd
mock_auth <- function() {
  mock_if_no_auth(force = TRUE)
}
