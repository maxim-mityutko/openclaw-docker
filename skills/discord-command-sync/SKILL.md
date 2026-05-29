---
name: discord-command-sync
description: Sync registered Discord application commands from one OpenClaw Discord bot account to another when multi-account native command registration misses an account.
metadata: {"clawdbot":{"emoji":"🔄","os":["linux","macos"],"requires":{"bins":["bash","node"]}}}
---

# Discord Command Sync Skill

Sync registered Discord application commands from one OpenClaw Discord bot account to another.

Use this skill when an OpenClaw Discord account is connected and responding, but Discord does not show native slash commands for that bot.

## Prerequisites

Run the helper from inside the OpenClaw container, where the rendered OpenClaw config and Discord bot token environment variables are available.

The helper expects:

- `OPENCLAW_CONFIG_DIR/openclaw.json` to contain `channels.discord.accounts`.
- Source and target Discord account entries to exist in that config.
- Source and target bot tokens to be available through the normal account token config.
- Source and target Discord application IDs to be available through config, environment, or positional arguments.

## Usage

Use `sync.sh` to copy the source account's registered global application commands to the target account.

```bash
bash "${SKILL_DIR}/sync.sh" [source_account] [target_account] [source_application_id] [target_application_id]
```

### Default: source to target

Use this path for normal OpenClaw/container workflows where the account names are `source` and `target`.

```bash
bash "${SKILL_DIR}/sync.sh" source target
```

The helper reads the source account's registered global application commands from Discord and replaces the target account's global application commands with the same definitions.

### Explicit application IDs

Use explicit application IDs when they are not present in the rendered OpenClaw config or environment.

```bash
bash "${SKILL_DIR}/sync.sh" source target SOURCE_APPLICATION_ID TARGET_APPLICATION_ID
```

The account names still come first. Application IDs may be provided in any of these ways, in priority order:

- Positional arguments `source_application_id` and `target_application_id`.
- Plain text `applicationId` values in the Discord account config.
- `${ENV_VAR}` placeholders in `applicationId`, resolved against the container environment.
- Env secret objects like `{ "source": "env", "id": "DISCORD_BOT_TARGET_APPLICATION_ID" }`.
- Conventional env vars like `DISCORD_BOT_SOURCE_APPLICATION_ID`.

## Verification

After running the helper, reload Discord and check Server Settings -> Integrations. The target bot should show `Bot` and `Commands`.

## Notes

- The sync script (`sync.sh`) is bundled alongside this SKILL.md in the skill directory.
- `SKILL_DIR` is a convention -- resolve it relative to the skill directory path.
- Bot tokens may be plain text, `${ENV_VAR}` placeholders, or OpenClaw env secret objects. The normal account token config is preferred.
- This performs a Discord bulk overwrite for the target application's global commands. Any existing target-only global commands will be removed.
