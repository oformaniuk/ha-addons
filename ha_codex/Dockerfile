ARG BUILD_ARCH=amd64

FROM golang:1.24-trixie AS hab-builder
ARG BUILD_ARCH
ARG HAB_VERSION=1.6.4
RUN git clone --depth 1 --branch "${HAB_VERSION}" https://github.com/balloob/home-assistant-build-cli.git /src
WORKDIR /src
RUN case "$BUILD_ARCH" in \
      aarch64) export GOARCH=arm64 ;; \
      amd64) export GOARCH=amd64 ;; \
      *) echo "Unsupported BUILD_ARCH: $BUILD_ARCH" >&2; exit 1 ;; \
    esac \
 && CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /hab .

FROM ghcr.io/home-assistant/base-debian:trixie
ARG BUILD_VERSION
ARG BUILD_ARCH
ARG TTYD_VERSION=1.7.7
# Pin this so a Codex upgrade always corresponds to a new add-on release.
# The update workflow keeps this value current.
ARG CODEX_VERSION=0.155.1

ENV NODE_ENV=production \
    npm_config_update_notifier=false \
    npm_config_fund=false \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium \
    EDITOR=/usr/bin/nano \
    VISUAL=/usr/bin/nano \
    GIT_EDITOR=/usr/bin/nano \
    SUDO_EDITOR=/usr/bin/nano

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    bash \
    bubblewrap \
    ca-certificates \
    chromium \
    curl \
    dtach \
    git \
    jq \
    nano \
    nodejs \
    npm \
    openssh-server \
    procps \
    python3 \
    python3-venv \
    python3-yaml \
    ripgrep \
    sudo \
    vim \
 && rm -rf /var/lib/apt/lists/*

RUN case "$BUILD_ARCH" in \
      aarch64) ARCH=aarch64 ;; \
      amd64) ARCH=x86_64 ;; \
      *) echo "Unsupported BUILD_ARCH: $BUILD_ARCH" >&2; exit 1 ;; \
    esac \
 && curl -fsSL "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.${ARCH}" -o /usr/bin/ttyd \
 && chmod +x /usr/bin/ttyd

COPY --from=hab-builder /hab /usr/local/bin/hab

RUN python3 -m venv /opt/zigporter-venv \
 && /opt/zigporter-venv/bin/pip install --no-cache-dir zigporter \
 && ln -s /opt/zigporter-venv/bin/zigporter /usr/local/bin/zigporter

RUN npm install -g "@openai/codex@${CODEX_VERSION}" prettier yaml-language-server \
 && npm cache clean --force

COPY rootfs/opt/ha-mcp-server/package*.json /opt/ha-mcp-server/
COPY rootfs/opt/ha-lsp-server/package*.json /opt/ha-lsp-server/
RUN (cd /opt/ha-mcp-server && npm install --omit=dev) & \
    (cd /opt/ha-lsp-server && npm install --omit=dev) & \
    wait && npm cache clean --force

COPY rootfs /
RUN chmod +x /usr/local/bin/* \
 && chmod +x /etc/s6-overlay/s6-rc.d/init-codex/run \
 && chmod +x /etc/s6-overlay/s6-rc.d/ha-codex/run \
 && chmod +x /etc/profile.d/*.sh \
 && mkdir -p /data/.local/share/codex /data/.codex /data/.config/codex /data/sessions /run/sshd

WORKDIR /homeassistant

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD pgrep ttyd >/dev/null || exit 1

LABEL \
  io.hass.name="Codex" \
  io.hass.description="AI coding agent for editing Home Assistant configuration" \
  io.hass.type="app" \
  io.hass.arch="aarch64|amd64" \
  io.hass.version="${BUILD_VERSION}"
