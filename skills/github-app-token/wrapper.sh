#!/usr/bin/env bash
# Retrieves GitHub App credentials from Bitwarden and prints an installation token.
#
# This script prepares token.sh by:
#   1. Reading GitHub App credentials from the GitHub Bitwarden entry.
#   2. Exporting the credentials as the environment variables token.sh expects.
#   3. Calling token.sh to mint a short-lived installation access token.
#   4. Printing only the installation access token to stdout.
#
# Required Bitwarden fields in the GitHub entry:
#
#   GITHUB_APP_ID
#     The numeric GitHub App ID.
#
#   GITHUB_APP_INSTALLATION_ID
#     The numeric installation ID for the GitHub App installation.
#
#   GITHUB_APP_PRIVATE_KEY
#     The base64-encoded GitHub App private key PEM.
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
#   export GH_TOKEN="$(./wrapper.sh)"
#   gh repo view owner/repo
#
# Credential safety:
#
#   The App ID, installation ID, and private key are never printed.
#   Do not enable shell tracing when running this script.
set -euo pipefail

GITHUB_APP_ID="$(rbw get GitHub -f GITHUB_APP_ID)"
GITHUB_APP_INSTALLATION_ID="$(rbw get GitHub -f GITHUB_APP_INSTALLATION_ID)"
GITHUB_APP_PRIVATE_KEY="$(rbw get GitHub -f GITHUB_APP_PRIVATE_KEY)"

export GITHUB_APP_ID
export GITHUB_APP_INSTALLATION_ID
export GITHUB_APP_PRIVATE_KEY

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
bash "$SKILL_DIR/token.sh"