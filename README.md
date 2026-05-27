# OpenClaw Docker

![Static Badge](https://img.shields.io/badge/OpenClaw%20Image-v2026.5.22-green)

## Tools

| Tool | Installed as | Purpose |
| --- | --- | --- |
| `git` | APT package | Source control and repository operations. |
| `curl` | APT package | Fetch files, APIs, install scripts, and release artifacts. |
| `jq` | APT package | Parse and transform JSON from command-line workflows. |
| `rbw` | Release binary | Unofficial Bitwarden CLI for retrieving secrets from Vaultwarden. |
| `rbw-agent` | Release binary | Background agent used by `rbw` to unlock and cache vault access. |
| `rbw_master_password_from_env.py` | Local helper script | Pinentry-compatible helper that reads `BITWARDEN_MASTER_PASSWORD`. |
| `karakeep` | Global npm package | Karakeep CLI for interacting with Karakeep services. |
| `summarize` | Global npm package | Summarization CLI used by skills and media workflows. |
| `ffmpeg` | APT package | Audio and video processing dependency for media workflows. |
| `yt-dlp` | APT package | Media download/extraction tool used with summarization workflows. |
| `gh` | GitHub APT repository package | GitHub CLI for issues, pull requests, releases, and repository automation. |

## Why

- Running OpenClaw in a containerized environment has trade-offs, but it
  provides stronger security boundaries and tighter control over agent's access;
- Some skills require additional libraries that are not included in the
  original OpenClaw container;
- Secret management is handled through Vaultwarden, which simplifies Kubernetes
  deployment and removes the need to create or update encrypted secrets every
  time an agent needs access to a new service. See
  [home-infra](https://github.com/maxim-mityutko/home-infra) for the
  Kubernetes deployment this image is designed to support;

## Secrets Management

OpenClaw should retrieve service credentials from Vaultwarden instead of
receiving each secret as a separate container environment variable.

The container only needs the Vaultwarden master password, exposed as
`BITWARDEN_MASTER_PASSWORD`, so `rbw` can unlock the vault at runtime and fetch the
specific credentials OpenClaw needs. For better isolation, create a dedicated
Vaultwarden account for OpenClaw and share only the items that are required by
the bot.

Vault interactions are handled by the [Bitwarden Skill](https://clawhub.ai/asleep123/bitwarden).

### RBW

RBW is an unofficial Bitwarden command-line client. This image includes `rbw`
and `rbw-agent` so tools inside the container can retrieve Bitwarden secrets
without relying on a browser or desktop integration.

`rbw-agent` normally asks `pinentry` to prompt for the master password. In this
container, interactive pinentry prompts are awkward and often unavailable, so
the pinentry command should be replaced with
`/usr/local/bin/rbw_master_password_from_env.py`. The script emulates the small
pinentry protocol surface that `rbw-agent` needs and returns the master password
from the `BITWARDEN_MASTER_PASSWORD` environment variable instead.

```sh
rbw config set email john@doe.com
rbw config set base_url https://vault.doe.com
rbw config set pinentry /usr/local/bin/rbw_master_password_from_env.py
rbw login
rbw unlock
```

`rbw` writes its configuration to `~/.config/rbw/config.json`. If the container
cannot create or update that file, mount a prepared config file at that path
instead:

```json
{
  "email": "john@doe.com",
  "sso_id": null,
  "base_url": "https://vault.doe.com",
  "identity_url": null,
  "ui_url": null,
  "notifications_url": null,
  "lock_timeout": 3600,
  "sync_interval": 300,
  "pinentry": "/usr/local/bin/rbw_master_password_from_env.py",
  "client_cert_path": null
}
```

Refer to the [RBW configuration docs](https://github.com/doy/rbw/blob/main/README.md#configuration)
for the details about supported options.

## Versioning

This image does not use semantic versioning. Tags are based on the upstream
OpenClaw image version, with one additional digit for revisions to this custom
image. This keeps the base image version visible while still allowing local
image changes to be released independently.
