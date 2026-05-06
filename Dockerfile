FROM ghcr.io/openclaw/openclaw:2026.5.6

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends jq \
    && rm -rf /var/lib/apt/lists/*

USER node
