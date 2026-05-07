# OpenClaw Docker
![Static Badge](https://img.shields.io/badge/OpenClaw%20Image-v2026.5.6-green)

## Why

## Secrets Management
- using VaultWarden to manage secrets for all services instead of providing them via environment variables
- simplifies secrets management, as only VaultWarden master password will be provided to container
- for security purposes create a dedicated account for OpenClaw in VaultWarden and only provide secrets scoped for the bot

### RBW

RBW is an unofficial Bitwarden command-line client. This image includes `rbw`
and `rbw-agent` so tools inside the container can retrieve Bitwarden secrets
without relying on a browser or desktop integration.

`rbw-agent` normally asks `pinentry` to prompt for the master password. In this
container, interactive pinentry prompts are awkward and often unavailable, so
the pinentry command should be replaced with
`/usr/local/bin/rbw_master_password_from_env.py`. The script emulates the small
pinentry protocol surface that `rbw-agent` needs and returns master password from
from the `RBW_MASTER_PASSWORD` environment variable instead.

```sh
rbw config set email john@doe.com
rbw config set base_url https://vault.doe.com
rbw config set pinentry /usr/local/bin/rbw_master_password_from_env.py
rbw login
rbw unlock
```
