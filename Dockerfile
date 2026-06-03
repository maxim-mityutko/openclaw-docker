ARG OPENCLAW_IMAGE_VERSION="latest"
FROM ghcr.io/openclaw/openclaw:${OPENCLAW_IMAGE_VERSION}

ARG RBW_VERSION="1.15.0"
ARG KUBECTL_VERSION="stable"
ARG HELM_VERSION="stable"

COPY utils/pinentry.py /tmp/pinentry.py

# ---------------------------------------------------------------------------------------------------------------------

RUN echo "Deploy custom skills..."
COPY --chown=node:node skills/ /app/custom/skills/

# ---------------------------------------------------------------------------------------------------------------------

USER root
# ---------------------------------------------------------------------------------------------------------------------

RUN echo "Installing standard dependencies..."
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        curl \
        jq \
        ripgrep

# ---------------------------------------------------------------------------------------------------------------------

RUN echo "Installing 'RBW' - Bitwarden unofficial client..."
RUN curl -fsSL \
      "https://github.com/doy/rbw/releases/download/${RBW_VERSION}/rbw_${RBW_VERSION}_linux_amd64.tar.gz" \
      -o /tmp/rbw.tar.gz; \
    tar -xzf /tmp/rbw.tar.gz -C /tmp; \
    install -m 0755 /tmp/rbw /usr/local/bin/rbw; \
    install -m 0755 /tmp/rbw-agent /usr/local/bin/rbw-agent; \
    rbw --version

RUN echo "Cheaky 'pinentry' replacement, make sure that BITWARDEN_MASTER_PASSWORD environment variable is set during execution..."
RUN install -m 0755 /tmp/pinentry.py /usr/local/bin/pinentry.py

# ---------------------------------------------------------------------------------------------------------------------

RUN echo "Installing Karakeep CLI..."
RUN npm install -g @karakeep/cli && karakeep --version

# ---------------------------------------------------------------------------------------------------------------------

RUN echo "Installing Summarize CLI and dependencies..."
RUN npm i -g @steipete/summarize && summarize --version
RUN apt-get install -y --no-install-recommends ffmpeg && ffmpeg -version
RUN apt-get install -y --no-install-recommends yt-dlp && yt-dlp --version

# ---------------------------------------------------------------------------------------------------------------------

RUN echo "Installing GitHub CLI..."
RUN apt-get install -y --no-install-recommends curl ca-certificates \
    && mkdir -p -m 755 /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && gh --version

# ---------------------------------------------------------------------------------------------------------------------

RUN echo "Installing kubectl..."
RUN set -eux; \
    if [ "$KUBECTL_VERSION" = "stable" ]; then \
      KUBECTL_VERSION="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"; \
    fi; \
    curl -fsSL \
      "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
      -o /tmp/kubectl; \
    install -m 0755 /tmp/kubectl /usr/local/bin/kubectl; \
    kubectl version --client=true

# ---------------------------------------------------------------------------------------------------------------------

RUN echo "Installing Helm..."
RUN set -eux; \
    if [ "$HELM_VERSION" = "stable" ]; then \
      HELM_VERSION="$(curl -fsSL https://get.helm.sh/helm-latest-version)"; \
    fi; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64|arm64) ;; \
      *) echo "Unsupported architecture: $arch"; exit 1 ;; \
    esac; \
    curl -fsSL \
      "https://get.helm.sh/helm-${HELM_VERSION}-linux-${arch}.tar.gz" \
      -o /tmp/helm.tar.gz; \
    tar -xzf /tmp/helm.tar.gz -C /tmp; \
    install -m 0755 "/tmp/linux-${arch}/helm" /usr/local/bin/helm; \
    helm version --short

# ---------------------------------------------------------------------------------------------------------------------

RUN echo "Cleaning up..."
RUN apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && apt-get clean \
    && rm -rf \
        /tmp/* \
        /var/lib/apt/lists/* \
        /var/cache/apt/* \
        /var/tmp/*

# ---------------------------------------------------------------------------------------------------------------------

USER node

# ---------------------------------------------------------------------------------------------------------------------

RUN echo "Installing @openclaw/discord..."
RUN npm install --prefix /tmp/openclaw-discord @openclaw/discord \
    && rm -rf /app/custom/extensions/discord \
    && mkdir -p /app/custom/extensions \
    && cp -a /tmp/openclaw-discord/node_modules/@openclaw/discord /app/custom/extensions/discord \
    && npm install --omit=dev --omit=peer --legacy-peer-deps --ignore-scripts --no-audit --no-fund --prefix /app/custom/extensions/discord \
    && rm -rf /tmp/openclaw-discord
