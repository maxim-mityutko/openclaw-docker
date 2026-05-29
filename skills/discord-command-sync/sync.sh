#!/usr/bin/env bash
#
# Sync Discord global application commands between two OpenClaw Discord accounts.
#
# This helper is intended to run inside the OpenClaw container, where the rendered
# OpenClaw config and Discord bot token environment variables are available. It
# reads the source account's registered global application commands from the
# Discord API and replaces the target account's global commands with the same
# command definitions.
#
# Usage:
#   sync.sh [source_account] [target_account] [source_application_id] [target_application_id]
#
# Defaults:
#   source_account=source
#   target_account=target
#
# Application IDs are resolved in this order: positional argument, account
# applicationId from openclaw.json, ${ENV_VAR} placeholder in openclaw.json, env
# secret object in openclaw.json, then DISCORD_BOT_<ACCOUNT>_APPLICATION_ID.
# Bot tokens are resolved from the account token config in openclaw.json.
#
# Warning: this performs a Discord bulk overwrite for the target application's
# global commands. Any existing target-only global commands will be removed.
#
set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  echo "Usage: $0 [source_account] [target_account] [source_application_id] [target_application_id]"
  echo "Example: $0 source target SOURCE_APPLICATION_ID TARGET_APPLICATION_ID"
  exit 0
fi

SOURCE_APPLICATION_ID="${3:-${SOURCE_APPLICATION_ID:-}}"
TARGET_APPLICATION_ID="${4:-${TARGET_APPLICATION_ID:-}}"
SOURCE_ACCOUNT="${1:-source}"
TARGET_ACCOUNT="${2:-target}"

node - "${SOURCE_ACCOUNT}" "${TARGET_ACCOUNT}" "${SOURCE_APPLICATION_ID}" "${TARGET_APPLICATION_ID}" <<'NODE'
const fs = require("fs");

function stripJsonComments(s) {
  let out = "";
  let inString = false;
  let escaped = false;

  for (let i = 0; i < s.length; i += 1) {
    const char = s[i];
    const next = s[i + 1];

    if (inString) {
      out += char;
      if (escaped) {
        escaped = false;
      } else if (char === "\\") {
        escaped = true;
      } else if (char === "\"") {
        inString = false;
      }
    } else if (char === "\"") {
      inString = true;
      out += char;
    } else if (char === "/" && next === "/") {
      while (i < s.length && s[i] !== "\n") i += 1;
      out += "\n";
    } else {
      out += char;
    }
  }

  return out;
}

function accountEnvName(account, suffix) {
  return `DISCORD_BOT_${account.toUpperCase().replace(/[^A-Z0-9]/g, "_")}_${suffix}`;
}

function resolveValue(value) {
  if (!value) return "";

  if (typeof value === "string") {
    const envOnly = value.match(/^\$\{([A-Z0-9_]+)\}$/);
    if (envOnly) return process.env[envOnly[1]] || "";
    return value;
  }

  if (typeof value === "object" && value.source === "env" && value.id) {
    return process.env[value.id] || "";
  }

  return "";
}

function resolveApplicationId(account, accountConfig, explicitValue) {
  return (
    explicitValue ||
    resolveValue(accountConfig.applicationId) ||
    process.env[accountEnvName(account, "APPLICATION_ID")] ||
    ""
  );
}

const [, , sourceAccount, targetAccount, sourceApplicationIdArg, targetApplicationIdArg] = process.argv;
const configPath = `${process.env.OPENCLAW_CONFIG_DIR || "/home/node/.openclaw"}/openclaw.json`;
const cfg = JSON.parse(stripJsonComments(fs.readFileSync(configPath, "utf8")));

const accounts = cfg.channels?.discord?.accounts || {};
const src = accounts[sourceAccount];
const dst = accounts[targetAccount];

if (!src) {
  console.error(`Missing source Discord account: ${sourceAccount}`);
  process.exit(1);
}

if (!dst) {
  console.error(`Missing target Discord account: ${targetAccount}`);
  process.exit(1);
}

const srcToken = resolveValue(src.token) || process.env[src.token?.id];
const dstToken = resolveValue(dst.token) || process.env[dst.token?.id];
const srcApplicationId = resolveApplicationId(sourceAccount, src, sourceApplicationIdArg);
const dstApplicationId = resolveApplicationId(targetAccount, dst, targetApplicationIdArg);

if (!srcApplicationId) {
  console.error(`Missing applicationId for source account: ${sourceAccount}`);
  process.exit(1);
}

if (!dstApplicationId) {
  console.error(`Missing applicationId for target account: ${targetAccount}`);
  process.exit(1);
}

if (!srcToken) {
  console.error(`Missing source token for account: ${sourceAccount}`);
  process.exit(1);
}

if (!dstToken) {
  console.error(`Missing target token for account: ${targetAccount}`);
  process.exit(1);
}

function commandBody(c) {
  const keys = [
    "name",
    "name_localizations",
    "description",
    "description_localizations",
    "type",
    "options",
    "default_member_permissions",
    "dm_permission",
    "contexts",
    "integration_types",
    "nsfw"
  ];
  return Object.fromEntries(keys.filter((k) => c[k] !== undefined).map((k) => [k, c[k]]));
}

(async () => {
  const get = await fetch(`https://discord.com/api/v10/applications/${srcApplicationId}/commands`, {
    headers: { Authorization: `Bot ${srcToken}` }
  });
  const commands = await get.json();

  if (!Array.isArray(commands)) {
    console.log("Failed to read source commands:", get.status, commands);
    process.exit(1);
  }

  console.log(`Read ${commands.length} commands from ${sourceAccount}`);

  const put = await fetch(`https://discord.com/api/v10/applications/${dstApplicationId}/commands`, {
    method: "PUT",
    headers: {
      Authorization: `Bot ${dstToken}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify(commands.map(commandBody))
  });

  const result = await put.json();
  console.log(`Deploy to ${targetAccount}:`, put.status);
  console.log(Array.isArray(result) ? result.map((c) => `/${c.name}`).join(" ") : result);
})();
NODE
