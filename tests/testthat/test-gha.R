describe("write_gha_workflow", {
  it("writes file and opens when requested", {
    tmp <- withr::local_tempdir()
    withr::local_dir(tmp)

    # Mock rstudio navigation so utils::file.edit is not called
    local_mocked_bindings(
      hasFun = function(name) TRUE,
      navigateToFile = function(path, line = 1L, ...) {
        message("opened:", path)
        invisible(TRUE)
      },
      .package = "rstudioapi"
    )

    filename <- ".github/workflows/test.yml"
    yaml <- c("name: test", "jobs: {}")

    res <- write_gha_workflow(
      filename = filename,
      yaml_lines = yaml,
      overwrite = FALSE,
      open = TRUE
    )

    expect_equal(res, filename)
    expect_true(file.exists(filename))

    # Overwrite = TRUE should succeed and produce the same side-effect
    expect_snapshot({
      write_gha_workflow(
        filename = filename,
        yaml_lines = yaml,
        overwrite = TRUE,
        open = TRUE
      )
    })
  })

  it("errors when file exists and overwrite = FALSE", {
    tmp <- withr::local_tempdir()
    withr::local_dir(tmp)

    filename <- ".github/workflows/exist.yml"
    fs::dir_create(fs::path_dir(filename))
    writeLines("existing", filename)

    expect_error(
      write_gha_workflow(
        filename = filename,
        yaml_lines = "x: 1",
        overwrite = FALSE,
        open = FALSE
      ),
      regexp = "Workflow file already exists",
      fixed = FALSE
    )
  })
})

describe("use_gha_jwt_token", {
  it("reads template, substitutes placeholders and writes workflow", {
    tmp <- withr::local_tempdir()
    withr::local_dir(tmp)

    # Create a simple template with placeholders
    jwt_tmpl <- file.path(tmp, "jwt-token.yml")
    writeLines(
      c(
        "name: Test JWT",
        "on:",
        "  workflow_dispatch:",
        "jobs:",
        "  jwt-job:",
        "    env:",
        "      \"{{CLIENT_ENV_JWT}}\": 
          ${{ secrets.{{JWT_SECRET}} }}",
        "      \"{{CLIENT_ENV_CLIENTID}}\": 
          ${{ secrets.{{client_key_SECRET}} }}",
        "    steps:",
        "      - name: noop",
        "        run: echo ok"
      ),
      jwt_tmpl
    )

    local_mocked_bindings(
      get_gha_template_path = function(name) {
        file.path(tmp, name)
      }
    )

    # Avoid opening editor: mock rstudio navigation
    local_mocked_bindings(
      hasFun = function(name) TRUE,
      navigateToFile = function(path, line = 1L) {
        invisible(TRUE)
      },
      .package = "rstudioapi"
    )

    # Capture cli success output for snapshot
    local_mocked_bindings(
      cli_alert_success = function(x) {
        message("CREATED:", paste(x, collapse = "\n"))
        invisible(TRUE)
      },
      .package = "cli"
    )

    client <- "myapp"
    jwt_secret <- "MEETUPR_JWT_TOKEN_X"
    client_key_secret <- "MEETUPR_client_key_X"

    res <- use_gha_jwt_token(
      client_name = client,
      jwt = jwt_secret,
      client_key = client_key_secret,
      overwrite = FALSE
    )

    expect_equal(res, ".github/workflows/meetupr-jwt-token.yml")
    expect_true(file.exists(res))

    content <- readLines(res)
    # Ensure placeholders were replaced with expected env names
    expect_true(
      any(grepl(paste0(client, "_jwt_token"), content, fixed = TRUE))
    )
    expect_true(any(grepl(jwt_secret, content, fixed = TRUE)))
    expect_true(
      any(grepl(client_key_secret, content, fixed = TRUE))
    )

    # Overwrite path + snapshot of cli output
    expect_snapshot({
      use_gha_jwt_token(
        client_name = client,
        jwt = jwt_secret,
        client_key = client_key_secret,
        overwrite = TRUE
      )
    })
  })
})

describe("use_gha_encrypted_token", {
  it("reads rotate template, substitutes and writes workflow", {
    tmp <- withr::local_tempdir()
    withr::local_dir(tmp)

    # Create rotate template with placeholders
    rotate_tmpl <- file.path(tmp, "rotate-token.yml")
    writeLines(
      c(
        "name: Rotate",
        "on:",
        "  workflow_dispatch:",
        "jobs:",
        "  rotate:",
        "    env:",
        "      \"meetupr_encrypt_pwd\": ${{ secrets.{{ENCRYPT_SECRET}} }}",
        "    steps:",
        "      - name: refresh",
        "        run: echo refreshed",
        "      - name: commit",
        "        run: git add {{TOKEN_PATH}}"
      ),
      rotate_tmpl
    )

    local_mocked_bindings(
      get_gha_template_path = function(name) {
        file.path(tmp, name)
      }
    )

    local_mocked_bindings(
      hasFun = function(name) TRUE,
      navigateToFile = function(path, line = 1L) invisible(TRUE),
      .package = "rstudioapi"
    )

    local_mocked_bindings(
      cli_alert_success = function(x) {
        message("CREATED_ROT:", paste(x, collapse = "\n"))
        invisible(TRUE)
      },
      .package = "cli"
    )

    fake_token <- "path/to/.meetupr.rds"

    res <- use_gha_encrypted_token(
      token_path = fake_token,
      overwrite = FALSE
    )

    expect_equal(res, ".github/workflows/meetupr-rotate-token.yml")
    expect_true(file.exists(res))

    content <- readLines(res)
    expect_true(
      any(grepl("meetupr_encrypt_pwd", content, fixed = TRUE))
    )
    expect_true(any(grepl(fake_token, content, fixed = TRUE)))

    expect_snapshot({
      use_gha_encrypted_token(
        token_path = fake_token,
        overwrite = TRUE
      )
    })
  })
})

describe("both helpers - existing workflow handling", {
  it("error when workflow exists and overwrite = FALSE", {
    tmp <- withr::local_tempdir()
    withr::local_dir(tmp)

    fs::dir_create(".github/workflows")
    writeLines("x", ".github/workflows/meetupr-jwt-token.yml")
    writeLines("x", ".github/workflows/meetupr-rotate-token.yml")

    expect_error(
      use_gha_jwt_token(overwrite = FALSE),
      regexp = "Workflow file already exists",
      fixed = FALSE
    )

    expect_error(
      use_gha_encrypted_token(overwrite = FALSE),
      regexp = "Workflow file already exists",
      fixed = FALSE
    )
  })
})
