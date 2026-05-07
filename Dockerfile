ARG OPENCLAW_IMAGE_VERSION=latest
ARG RBW_VERSION=1.15.0

FROM ghcr.io/openclaw/openclaw:${OPENCLAW_IMAGE_VERSION}

USER root

RUN echo "Installing standard dependencies..."
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        curl \
        jq

RUN echo "Installing 'rbw' Bitwarden unnoficial clientt..."
RUN curl -fsSL \
      "https://github.com/doy/rbw/releases/download/${RBW_VERSION}/rbw_${RBW_VERSION}_linux_amd64.tar.gz" \
      -o /tmp/rbw.tar.gz; \
    tar -xzf /tmp/rbw.tar.gz -C /tmp; \
    install -m 0755 /tmp/rbw /usr/local/bin/rbw; \
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
