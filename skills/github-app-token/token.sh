#!/usr/bin/env bash
# Generates a short-lived GitHub App installation access token.
#
# This script authenticates as a GitHub App by:
#   1. Reading GitHub App credentials from environment variables.
#   2. Decoding the base64-encoded GitHub App private key.
#   3. Creating a signed GitHub App JWT.
#   4. Exchanging that JWT for an installation access token.
#   5. Printing the installation access token to stdout.
#
# Required environment variables:
#
#   GITHUB_APP_ID
#     The numeric GitHub App ID.
#     This is the "App ID" from the GitHub App settings page.
#     Do not use the Client ID.
#
#   GITHUB_APP_INSTALLATION_ID
#     The numeric installation ID for the GitHub App installation.
#     This identifies the account/repository installation where the app is installed.
#     It can usually be found in the GitHub installation URL:
#       https://github.com/settings/installations/<installation_id>
#       https://github.com/organizations/<org>/settings/installations/<installation_id>
#
#   GITHUB_APP_PRIVATE_KEY
#     The base64-encoded GitHub App private key PEM.
#     The original PEM should be encoded before storing it in a secret manager:
#       base64 -w0 github-app-private-key.pem
#
#     This variable must contain the base64 text only, not the raw PEM.
#     Expected decoded PEM format:
#       -----BEGIN PRIVATE KEY-----
#       ...
#       -----END PRIVATE KEY-----
#
# Output:
#
#   Prints only the GitHub App installation access token to stdout.
#   The token can be used as:
#     GITHUB_TOKEN
#     GH_TOKEN
#
# Example usage:
#
#   export GITHUB_APP_ID="123456"
#   export GITHUB_APP_INSTALLATION_ID="98765432"
#   export GITHUB_APP_PRIVATE_KEY="$(base64 -w0 github-app-private-key.pem)"
#
#   export GITHUB_TOKEN="$(./token.sh)"
#   export GH_TOKEN="$GITHUB_TOKEN"
#
#   gh repo view owner/repo
#
# Token lifetime:
#
#   The generated GitHub App JWT is valid for up to 10 minutes.
#   The returned installation access token is valid for 1 hour.
#   For long-running processes, refresh the token before expiry, for example every
#   45 to 50 minutes, or generate a fresh token on demand.
set -euo pipefail

client_id="${GITHUB_APP_ID:?GITHUB_APP_ID is required}"
pem_b64="${GITHUB_APP_PRIVATE_KEY:?GITHUB_APP_PRIVATE_KEY is required}"
installation_id="${GITHUB_APP_INSTALLATION_ID:?GITHUB_APP_INSTALLATION_ID is required}"

now=$(date +%s)
iat=$((${now} - 60))  # Issues 60 seconds in the past
exp=$((${now} + 600)) # Expires 10 minutes in the future

b64enc() {
  openssl base64 -A | tr -d '=' | tr '/+' '_-' | tr -d '\n'
}

key_file="$(mktemp)"
trap 'rm -f "$key_file"' EXIT

# Decode the base64-encoded PEM into a temporary key file.
printf '%s' "$pem_b64" | openssl base64 -d -A | tr -d '\r' > "$key_file"

# Validate private key without printing it.
openssl pkey -in "$key_file" -noout >/dev/null

header_json='{
    "typ":"JWT",
    "alg":"RS256"
}'

header=$(echo -n "${header_json}" | b64enc)

payload_json="{
    \"iat\":${iat},
    \"exp\":${exp},
    \"iss\":\"${client_id}\"
}"

payload=$(echo -n "${payload_json}" | b64enc)

header_payload="${header}.${payload}"

signature=$(
  echo -n "${header_payload}" \
    | openssl dgst -sha256 -sign "$key_file" -binary \
    | b64enc
)

JWT="${header_payload}.${signature}"

# Exchange the GitHub App JWT for an installation access token.
installation_token="$(
  curl -fsSL \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${JWT}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/app/installations/${installation_id}/access_tokens" \
  | jq -r '.token'
)"

if [ -z "$installation_token" ] || [ "$installation_token" = "null" ]; then
  echo "Failed to obtain GitHub installation token" >&2
  exit 1
fi

printf '%s\n' "$installation_token"
