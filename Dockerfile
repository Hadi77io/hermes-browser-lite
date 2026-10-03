# Hermes Browser Lite — noVNC + Chromium + CDP (lightweight)
#
# Minimal alternative to linuxserver/chromium:
#   Xvfb + x11vnc + noVNC (websockify) + openbox + chromium + nginx (basic-auth)
#
# Exposes:
#   3000 — noVNC web UI (basic auth via VNC_USER/VNC_PASSWORD; proxied by any domain/router)
#   9224 — Chrome DevTools CDP proxy (basic auth via CDP_USER/CDP_PASSWORD) -> 127.0.0.1:9222
#
# Env:
#   VNC_USER / VNC_PASSWORD   — noVNC gate (default hermes / must set)
#   CDP_USER / CDP_PASSWORD   — CDP gate  (default hermes / must set)
#
# Persistent profile: mount a volume at /config (chrome user-data-dir = /config/chrome).

FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        chromium \
        xvfb \
        x11vnc \
        novnc \
        websockify \
        openbox \
        nginx-light \
        openssl \
        tini \
        procps \
        curl \
        ca-certificates \
        fonts-noto-core \
        fonts-liberation \
    && rm -rf /var/lib/apt/lists/* /etc/nginx/sites-enabled/default

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 3000 9224

ENTRYPOINT ["/usr/bin/tini", "--", "/start.sh"]
