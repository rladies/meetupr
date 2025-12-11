# write_gha_workflow / writes file and opens when requested

    Code
      write_gha_workflow(filename = filename, yaml_lines = yaml, overwrite = TRUE,
        open = TRUE)
    Message
      opened:.github/workflows/test.yml

# use_gha_jwt_token / reads template, substitutes placeholders and writes workflow

    Code
      use_gha_jwt_token(client_name = client, jwt = jwt_secret, client_key = client_key_secret,
        overwrite = TRUE)
    Message
      CREATED:Created GitHub Actions workflow for JWT token authentication at
      {.path {filename}}
      Remember to add the required secrets in your repository settings
        - {.envvar {jwt}}: Your JWT token
        - {.envvar {client_key}}: Your client ID

# use_gha_encrypted_token / reads rotate template, substitutes and writes workflow

    Code
      use_gha_encrypted_token(token_path = fake_token, overwrite = TRUE)
    Message
      CREATED_ROT:Created GitHub Actions workflow for 
            encrypted token rotation at
      {.path {filename}}
      Remember to add the required secret
             in your repository settings
        - {.envvar {secret_name}}: Your 
            encryption password

