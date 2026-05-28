---
name: github-app-token
description: Obtain a GitHub App installation token for use with GitHub CLI (gh). Uses a bundled script to authenticate as a GitHub App and mint a short-lived token.
metadata: {"clawdbot":{"emoji":"🔑","os":["linux","macos"],"requires":{"bins":["bash","base64","curl","jq","openssl","rbw"]}}}
---

# GitHub App Token Skill

Obtain a GitHub App installation token to use with the GitHub CLI (`gh`).

## Prerequisites

For the default `wrapper.sh` path, the following fields must exist in the `GitHub` Bitwarden entry:
- `GITHUB_APP_ID` — App ID from the GitHub App settings
- `GITHUB_APP_INSTALLATION_ID` — Installation ID (found in the URL after installing the App on your account/org)
- `GITHUB_APP_PRIVATE_KEY` — Private key (`.pem` file contents), base64-encoded

## Usage

Use `wrapper.sh` by default when the GitHub App secrets are available in the `GitHub` Bitwarden entry and `rbw` can be called directly. The wrapper retrieves the three required fields with `rbw`, exports them for `token.sh`, and prints only the installation token.

Do not set or override `HOME` for `rbw` when using the wrapper. The runtime environment is expected to make `rbw` available with the correct configuration.

### Default: Bitwarden via wrapper.sh

Use this path for normal OpenClaw/container workflows where Vaultwarden/Bitwarden is the source of truth for the GitHub App credentials.

```bash
export GH_TOKEN="$(bash "${SKILL_DIR}/wrapper.sh" 2>/dev/null)"
```

Then use `gh` normally:

```bash
gh pr list --repo owner/repo --state open
```

`wrapper.sh` is intentionally small: it only fetches `GITHUB_APP_ID`, `GITHUB_APP_INSTALLATION_ID`, and `GITHUB_APP_PRIVATE_KEY` from Bitwarden, then delegates token minting to `token.sh`. If `wrapper.sh` fails because `rbw` is locked, missing, misconfigured, or unable to find the expected fields, ask the user for guidelines before trying another credential source or changing vault configuration.

### Fallback: call token.sh directly

Use `token.sh` directly when the secrets are not available through Bitwarden, when `rbw` is unavailable, or when the user provides credentials through another appropriate channel such as an existing environment, a CI secret store, Kubernetes secrets, or a local secret manager.

Before calling `token.sh`, obtain these values without printing them:

- `GITHUB_APP_ID`: numeric GitHub App ID.
- `GITHUB_APP_INSTALLATION_ID`: numeric installation ID for the GitHub App installation.
- `GITHUB_APP_PRIVATE_KEY`: base64-encoded private key PEM.

```bash
export GITHUB_APP_ID="123456"
export GITHUB_APP_INSTALLATION_ID="98765432"
export GITHUB_APP_PRIVATE_KEY="$(openssl base64 -A < github-app-private-key.pem)"

export GH_TOKEN="$(bash "${SKILL_DIR}/token.sh")"
```

Use `token.sh` when the credentials are already available as environment variables or can be retrieved by a user-approved mechanism. The script does not talk to Bitwarden; it signs a GitHub App JWT from the environment variables, exchanges it for an installation access token, and prints only that token.

## Token Lifetime

GitHub App installation tokens expire after **60 minutes**. Re-run the script to get a fresh token if your session outlives the token lifetime.

## Notes

- The token script (`token.sh`) and wrapper (`wrapper.sh`) are bundled alongside this SKILL.md in the skill directory.
- `SKILL_DIR` is a convention — resolve it relative to the skill directory path.
- **Never echo credential values.** Captured tool output becomes part of the session trajectory — only the final GitHub token should ever appear in command output.
- The `GITHUB_APP_PRIVATE_KEY` value (base64-encoded PEM) is sensitive. Do not log, echo, or include it in any command output.