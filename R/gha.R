#' GitHub Actions workflow helpers
#'
#' Create GitHub Actions workflows for JWT and encrypted-token CI auth.
#'
#' These helpers write workflow YAML into `.github/workflows/` so you can
#' enable non-interactive authentication for meetupr in GitHub Actions.
#'
#' Which helper to use:
#' - use_gha_jwt_token(): For Meetup Pro accounts that use a static JWT
#'   token. The generated workflow provides a JWT and client id as
#'   repository secrets so the runner can authenticate via JWT.
#' - use_gha_encrypted_token(): For regular OAuth apps. This creates a
#'   rotation workflow that loads an encrypted `.meetupr.rds` token,
#'   refreshes it when needed, and writes the rotated encrypted file
#'   back to the repo. Requires a decryption password stored as a
#'   repository secret (default: MEETUPR_ENCRYPT_PWD).
#'
#' Important notes:
#' - These functions only write the workflow YAML. They do not create
#'   repository secrets or commit/push files for you.
#' - Review the generated YAML and add the required secrets in your
#'   repository settings before enabling the workflow.
#'
#' @name use_gha
#' @template client_name
#' @param jwt Name of the GitHub secret that contains the JWT token.
#'   Defaults to "MEETUPR_JWT_TOKEN".
#' @param client_key Name of the GitHub secret that contains the client
#'   id. Defaults to "MEETUPR_client_key".
#' @param token_path Path to the encrypted token file in the repo.
#'   Defaults to get_encrypted_path().
#' @param overwrite If FALSE and file exists, function aborts.
#' @param filename Path to write the workflow YAML file.
#'   Defaults to appropriate path in `.github/workflows/`.
#' @return Invisibly returns the path to the created workflow file.
NULL

#' @describeIn use_gha Create workflow for JWT token auth.
#' @export
use_gha_jwt_token <- function(
  client_name = get_client_name(),
  jwt = "MEETUPR_JWT_TOKEN",
  client_key = "MEETUPR_client_key",
  overwrite = FALSE,
  filename = ".github/workflows/meetupr-jwt-token.yml"
) {
  env_jwt_name <- paste0(client_name, "_jwt_token")
  env_clientid_name <- paste0(client_name, "_client_key")

  yaml_lines <- read_replace_template(
    "jwt-token.yml",
    client_name = client_name
  )

  write_gha_workflow(filename, yaml_lines, overwrite = overwrite)

  cli::cli_alert_success(
    c(
      "Created GitHub Actions workflow for JWT token authentication. ",
      "i" = "Remember to add the required secrets in your repository settings",
      "*" = "{.envvar MEETUPR_CLIENT_NAME}: {client_name}",
      "*" = "{.envvar {client_name}_jwt_token}: Your JWT token",
      "*" = "{.envvar {client_name}_jwt_issuer}: Your Meetup ID",
      "*" = "{.envvar {client_name}_client_key}: Your client key"
    )
  )
  invisible(filename)
}

#' @describeIn use_gha Create workflow for encrypted token rotation.
#' @export
use_gha_encrypted_token <- function(
  token_path = get_encrypted_path(),
  overwrite = FALSE,
  filename = ".github/workflows/meetupr-rotate-token.yml"
) {
  yaml_lines <- read_replace_template(
    "rotate-token.yml",
    token_path = token_path
  )

  write_gha_workflow(
    filename,
    yaml_lines,
    overwrite = overwrite
  )

  cli::cli_alert_success(
    c(
      "Created GitHub Actions workflow for encrypted 
      token rotation. ",
      "i" = "Remember to add the required secret
       in your repository settings",
      "*" = "{.envvar meetupr_encrypt_pwd}: Your 
      encryption password"
    )
  )
  invisible(filename)
}

#' @keywords internal
#' @noRd
get_gha_template_path <- function(name) {
  path <- system.file("gha", name, package = "meetupr")
  if (nzchar(path)) {
    return(path)
  }
  cli::cli_abort(
    "GHA template {.file {name}} not found in installed package."
  )
}

#' Read and replace placeholders in a GHA template
#'
#' Placeholders are of the form {{NAME}} and replaced using the named
#' list `replacements`.
#'
#' @keywords internal
#' @noRd
read_replace_template <- function(name, ...) {
  replacements <- list(...)

  path <- get_gha_template_path(name)
  txt <- readLines(path, warn = FALSE)
  if (length(replacements) == 0) {
    return(txt)
  }

  for (nm in names(replacements)) {
    placeholder <- sprintf("<<%s>>", nm)
    val <- as.character(replacements[[nm]])
    txt <- gsub(placeholder, val, txt, fixed = TRUE)
  }

  txt
}


#' Write a GitHub Actions workflow file
#'
#' Internal helper used by public GHA helpers.
#'
#' @keywords internal
#' @noRd
write_gha_workflow <- function(
  filename,
  yaml_lines,
  overwrite = FALSE,
  open = TRUE
) {
  fs::dir_create(fs::path_dir(filename))

  if (fs::file_exists(filename) && !overwrite) {
    cli::cli_abort(
      c(
        "Workflow file already exists at 
        {.path {filename}}.",
        i = "Set {.arg overwrite = TRUE} to replace it."
      )
    )
  }

  writeLines(yaml_lines, filename, useBytes = TRUE)

  if (open) {
    if (rstudioapi::hasFun("navigateToFile")) {
      rstudioapi::navigateToFile(filename)
    } else {
      utils::file.edit(filename)
    }
  }

  invisible(filename)
}
