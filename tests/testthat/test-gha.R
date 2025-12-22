describe("use_gha_jwt_token", {
  it("reads template, substitutes placeholders and writes workflow", {
    # Avoid opening editor: mock rstudio navigation
    local_mocked_bindings(
      hasFun = function(name) TRUE,
      navigateToFile = function(path, line = 1L) {
        invisible(TRUE)
      },
      .package = "rstudioapi"
    )

    client <- "myapp"
    temp_file <- withr::local_tempfile(fileext = ".yml")

    expect_message(
      res <- use_gha_jwt_token(
        client_name = client,
        jwt = jwt_secret,
        client_key = client_key_secret,
        overwrite = FALSE,
        filename = temp_file
      ),
      "Created GitHub Actions workflow for JWT"
    )

    expect_equal(
      res,
      temp_file
    )
    expect_true(file.exists(res))
    expect_true(
      any(grepl(client, readLines(res), fixed = TRUE))
    )

    # Overwrite path + snapshot of cli output
    expect_snapshot({
      use_gha_jwt_token(
        client_name = client,
        jwt = jwt_secret,
        client_key = client_key_secret,
        overwrite = TRUE,
        filename = temp_file
      )
    })
  })
})

describe("use_gha_encrypted_token", {
  it("reads rotate template, substitutes and writes workflow", {
    local_mocked_bindings(
      hasFun = function(name) TRUE,
      navigateToFile = function(path, line = 1L) invisible(TRUE),
      .package = "rstudioapi"
    )

    temp_file <- withr::local_tempfile(fileext = ".yml")
    fake_token <- withr::local_tempfile(fileext = ".rds")

    expect_message(
      res <- use_gha_encrypted_token(
        token_path = fake_token,
        overwrite = FALSE,
        filename = temp_file
      ),
      "Created GitHub Actions workflow for encrypted "
    )

    expect_equal(res, temp_file)
    expect_true(file.exists(res))

    content <- readLines(res)
    expect_true(
      any(grepl("meetupr_encrypt_pwd", content, fixed = TRUE))
    )
    expect_true(any(grepl(fake_token, content, fixed = TRUE)))

    expect_snapshot({
      use_gha_encrypted_token(
        token_path = fake_token,
        overwrite = TRUE,
        filename = temp_file
      )
    })
  })
})

describe("write_gha_workflow", {
  it("writes file and opens when requested", {
    # Mock rstudio navigation so utils::file.edit is not called
    local_mocked_bindings(
      hasFun = function(name) TRUE,
      navigateToFile = function(path, line = 1L, ...) {
        invisible(TRUE)
      },
      .package = "rstudioapi"
    )

    filename <- withr::local_tempfile(fileext = ".yml")
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
    filename <- withr::local_tempfile(fileext = ".yml")
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


describe("get_gha_template_path", {
  it("returns correct path within package", {
    path <- get_gha_template_path("jwt-token.yml")
    expect_true(file.exists(path))
    expect_true(grepl("jwt-token.yml$", path))
  })

  it("errors for unknown template", {
    expect_error(
      get_gha_template_path("nonexistent.yml"),
      regexp = "not found in installed package"
    )
  })
})

describe("read_replace_template", {
  it("reads template and replaces placeholders", {
    tmp <- withr::local_tempdir()
    withr::local_dir(tmp)

    # Create a simple template with placeholders
    tmpl <- file.path(tmp, "template.yml")
    writeLines(
      c(
        "line1: <<PLACEHOLDER1>>",
        "line2: <<PLACEHOLDER2>>"
      ),
      tmpl
    )

    local_mocked_bindings(
      get_gha_template_path = function(name) {
        file.path(tmp, name)
      }
    )

    result <- read_replace_template(
      "template.yml",
      PLACEHOLDER1 = "value1",
      PLACEHOLDER2 = "value2"
    )

    expect_equal(
      result,
      c(
        "line1: value1",
        "line2: value2"
      )
    )
  })

  it("handles missing placeholders gracefully", {
    tmp <- withr::local_tempdir()
    withr::local_dir(tmp)

    tmpl <- file.path(tmp, "template2.yml")
    writeLines(
      c(
        "line1: <<PLACEHOLDER1>>",
        "line2: <<PLACEHOLDER2>>"
      ),
      tmpl
    )

    local_mocked_bindings(
      get_gha_template_path = function(name) {
        file.path(tmp, name)
      }
    )

    result <- read_replace_template(
      "template2.yml",
      PLACEHOLDER1 = "value1"
    )

    expect_equal(
      result,
      c(
        "line1: value1",
        "line2: <<PLACEHOLDER2>>"
      )
    )
  })
})
