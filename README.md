# OpenClaw Docker
![Static Badge](https://img.shields.io/badge/OpenClaw%20Image-v2026.5.6-green)

## Why

## Secrets Management

OpenClaw should retrieve service credentials from Vaultwarden instead of
receiving each secret as a separate container environment variable.

The container only needs the Vaultwarden master password, exposed as
`RBW_MASTER_PASSWORD`, so `rbw` can unlock the vault at runtime and fetch the
specific credentials OpenClaw needs. For better isolation, create a dedicated
Vaultwarden account for OpenClaw and share only the items that are required by
the bot.

### RBW

RBW is an unofficial Bitwarden command-line client. This image includes `rbw`
and `rbw-agent` so tools inside the container can retrieve Bitwarden secrets
without relying on a browser or desktop integration.

`rbw-agent` normally asks `pinentry` to prompt for the master password. In this
container, interactive pinentry prompts are awkward and often unavailable, so
the pinentry command should be replaced with
`/usr/local/bin/rbw_master_password_from_env.py`. The script emulates the small
pinentry protocol surface that `rbw-agent` needs and returns the master password
from the `RBW_MASTER_PASSWORD` environment variable instead.

```sh
rbw config set email john@doe.com
rbw config set base_url https://vault.doe.com
rbw config set pinentry /usr/local/bin/rbw_master_password_from_env.py
rbw login
rbw unlock
```
