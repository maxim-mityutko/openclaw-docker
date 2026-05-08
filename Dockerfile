ARG OPENCLAW_IMAGE_VERSION="latest"
FROM ghcr.io/openclaw/openclaw:${OPENCLAW_IMAGE_VERSION}

ARG RBW_VERSION="1.15.0"

COPY scripts/rbw_master_password_from_env.py /tmp/rbw_master_password_from_env.py

# ---------------------------------------------------------------------------------------------------------------------

RUN echo "Installing standard dependencies..."
USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        curl \
        jq 

# ---------------------------------------------------------------------------------------------------------------------

# RUN echo "Installing HomeBrew, because why not..."
# USER root
# RUN apt-get install -y --no-install-recommends \
#         build-essential \
#         sudo

# ENV HOMEBREW_NO_ANALYTICS=1
# RUN useradd -m -s /bin/bash linuxbrew \
#     && echo 'linuxbrew ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# USER linuxbrew
# RUN NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
#     && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" \
#     && brew --version
# ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"

# ---------------------------------------------------------------------------------------------------------------------

RUN echo "Installing 'RBW' - Bitwarden unofficial client..."
USER root
RUN curl -fsSL \
      "https://github.com/doy/rbw/releases/download/${RBW_VERSION}/rbw_${RBW_VERSION}_linux_amd64.tar.gz" \
      -o /tmp/rbw.tar.gz; \
    tar -xzf /tmp/rbw.tar.gz -C /tmp; \
    install -m 0755 /tmp/rbw /usr/local/bin/rbw; \
    install -m 0755 /tmp/rbw-agent /usr/local/bin/rbw-agent; \
    rbw --version

RUN echo "Cheaky 'pinentry' replacement, make sure that BITWARDEN_MASTER_PASSWORD environment variable is set during execution..."
RUN install -m 0755 /tmp/rbw_master_password_from_env.py /usr/local/bin/rbw_master_password_from_env.py

# ---------------------------------------------------------------------------------------------------------------------

RUN echo "Installing Karakeep CLI..."
USER root
RUN npm install -g @karakeep/cli && karakeep --version

# ---------------------------------------------------------------------------------------------------------------------

RUN echo "Installing Summarize CLI and dependencies..."
USER root
RUN npm i -g @steipete/summarize; summarize --version
RUN apt-get install -y --no-install-recommends ffmpeg && ffmpeg -version
RUN apt-get install -y --no-install-recommends yt-dlp && yt-dlp --version


# USER linuxbrew
# RUN brew install summarize; \
#     summarize --version
# RUN brew install ffmpeg yt-dlp; \
#     ffmpeg -version; \
#     yt-dlp --version

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

# USER linuxbrew
# RUN brew install gh; \
#     gh --version

# ---------------------------------------------------------------------------------------------------------------------

RUN echo "Cleaning up..."
# USER linuxbrew
# RUN brew cleanup -s

USER root
ENV SUDO_FORCE_REMOVE=yes
RUN apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && apt-get purge -y --auto-remove sudo \
    && apt-get clean \
    && rm -rf \
        /tmp/* \
        /var/lib/apt/lists/* \
        /var/cache/apt/* \
        /var/tmp/*

# ---------------------------------------------------------------------------------------------------------------------
USER node
