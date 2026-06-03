# AGENTS.md - OpenClaw Docker

## Overview

This repository builds a custom OpenClaw container image with extra CLI tools,
Vaultwarden secret access via `rbw`, and bundled custom extensions.

## Image

The image is published to GitHub Container Registry:
`ghcr.io/maxim-mityutko/openclaw-docker`

Tag format: `v<OPENCLAW_BASE_VERSION>.<REVISION>` (e.g. `v2026.5.26.0`)

## Tools

Configurable versions via build args:

| Build arg | Default | Description |
| --- | --- | --- |
| `OPENCLAW_IMAGE_VERSION` | `latest` | Upstream OpenClaw image tag |
| `RBW_VERSION` | `1.15.0` | RBW release version |
| `KUBECTL_VERSION` | `stable` | kubectl release or `stable` |
| `HELM_VERSION` | `3.19.2` | Helm 3.x release (pin to 3.19.x or latest 3.x) |

## Making Changes

### Pull Requests

All changes to this repository must be submitted via pull request.
Never commit directly to `main`.

### Adding a new tool

1. Add the installation step to `Dockerfile` following the existing patterns
2. Add the tool to the **Tools** table in `README.md` in alphabetical order
3. Include the `Version` column (use `apt show <package>` or the upstream release page)
4. If the tool has a configurable version via build arg, add the `ARG` at the top of the Dockerfile

### Updating a tool version

1. Update the relevant `ARG` in `Dockerfile` (or use the existing build arg)
2. Update the `Version` column in `README.md`
3. Submit a PR with both changes