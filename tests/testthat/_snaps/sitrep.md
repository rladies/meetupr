# meetupr_sitrep(): prints setup when no auth and returns auth invisibly

    Code
      meetupr_sitrep()
    Message
      H1: meetupr Situation Report
      H2: Active Authentication Method
      DANGER: No Authentication Configured
      H2: Setup Instructions
      H3: Interactive Setup:
      OL: Run {.code meetupr_auth()} to authenticate
      H3: CI/CD Setup:
      UL: Authenticate locally first with; {.code meetupr_auth()}; See the vignette on setting up authentication for CI/CD:; {.url https://rladies.org/meetupr/articles/advanced-auth.html}

# meetupr_sitrep(): runs full report when auth available and API works

    Code
      meetupr_sitrep()
    Message
      H1: meetupr Situation Report
      H2: Active Authentication Method
      SUCCESS: Authentication available
      INFO: Active method: {.strong {auth_status$auth$method}}
      INFO: Client name: {.strong {auth_status$auth$client_name}}
      SUCCESS: JWT token: Available and valid
      SUCCESS: JWT issuer: {.strong {auth_status$jwt$issuer}}
      SUCCESS: Client key: {.strong {substr(auth_status$jwt$client_key, 1, 6)}}...
      H2: API Connectivity Test
      SUCCESS: API Connection: Working
      DANGER: API Connection: Failed - {e$message}

# display_auth_status(): alerts danger when no auth available

    Code
      display_auth_status(auth)
    Message
      H2: Active Authentication Method
      DANGER: No Authentication Configured

# display_auth_status(): prefers JWT over other available methods

    Code
      display_auth_status(auth)
    Message
      H2: Active Authentication Method
      SUCCESS: Authentication available
      i Active method: jwt
      i Client name: rladies
      SUCCESS: JWT token: Available and valid
      SUCCESS: JWT issuer: {.strong {auth_status$jwt$issuer}}
      SUCCESS: Client key: {.strong {substr(auth_status$jwt$client_key, 1, 6)}}...

# display_auth_status(): shows Encrypted when JWT missing

    Code
      display_auth_status(auth)
    Message
      H2: Active Authentication Method
      SUCCESS: Authentication available
      i Active method: encrypted
      i Client name: rladies
      SUCCESS: Encrypted token: Available
      SUCCESS: Encrypted token path: {.strong {auth_status$encrypted$path}}
      DANGER: Password for decryption: Not set

# display_auth_status(): shows Refresh when earlier methods missing

    Code
      display_auth_status(auth)
    Message
      H2: Active Authentication Method
      SUCCESS: Authentication available
      i Active method: refresh
      i Client name: rladies

# display_auth_status(): shows OAuth cache when others missing

    Code
      display_auth_status(auth)
    Message
      H2: Active Authentication Method
      SUCCESS: Authentication available
      i Active method: cache
      i Client name: rladies
      SUCCESS: OAuth cache: Available

# test_api_connectivity(): prints setup and returns NULL when no auth

    Code
      test_api_connectivity()
    Message
      H2: Setup Instructions
      H3: Interactive Setup:
      OL: Run {.code meetupr_auth()} to authenticate
      H3: CI/CD Setup:
      UL: Authenticate locally first with; {.code meetupr_auth()}; See the vignette on setting up authentication for CI/CD:; {.url https://rladies.org/meetupr/articles/advanced-auth.html}

# test_api_connectivity(): reports working when get_self returns user info

    Code
      test_api_connectivity()
    Message
      H2: API Connectivity Test
      SUCCESS: API Connection: Working
      x API Connection: Failed - unused argument ("(ID: {user_info$id})")

# test_api_connectivity(): warns on unexpected NULL response from get_self

    Code
      test_api_connectivity()
    Message
      H2: API Connectivity Test
      WARN: API Connection: Unexpected response

# test_api_connectivity(): handles errors from get_self and shows danger

    Code
      test_api_connectivity()
    Message
      H2: API Connectivity Test
      DANGER: API Connection: Failed - {e$message}

