ARG OPENCLAW_IMAGE_VERSION="latest"
FROM ghcr.io/openclaw/openclaw:${OPENCLAW_IMAGE_VERSION}

ARG RBW_VERSION="1.15.0"

COPY scripts/rbw_master_password_from_env.py /tmp/rbw_master_password_from_env.py

USER root

RUN echo "Installing standard dependencies..."
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        curl \
        jq 

RUN echo "Cheaky 'pinentry' replacement, make sure that VAULT_MASTER_PASSWORD environment variable is set during execution..."
RUN install -m 0755 /tmp/rbw_master_password_from_env.py /usr/local/bin/rbw_master_password_from_env.py

RUN echo "Installing 'RBW' - Bitwarden unofficial client..."
RUN curl -fsSL \
      "https://github.com/doy/rbw/releases/download/${RBW_VERSION}/rbw_${RBW_VERSION}_linux_amd64.tar.gz" \
      -o /tmp/rbw.tar.gz; \
    tar -xzf /tmp/rbw.tar.gz -C /tmp; \
    install -m 0755 /tmp/rbw /usr/local/bin/rbw; \
    install -m 0755 /tmp/rbw-agent /usr/local/bin/rbw-agent; \
    rbw --version

RUN echo "Cleaning up..."
RUN apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf \
        /tmp/* \
        /var/lib/apt/lists/* \
        /var/cache/apt/* \
        /var/tmp/*

USER node
