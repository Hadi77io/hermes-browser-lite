#!/bin/bash
# Hermes Browser Lite — startup: Xvfb + openbox + x11vnc + noVNC(websockify) + nginx + chromium
set -e

VNC_USER="${VNC_USER:-hermes}"
VNC_PASSWORD="${VNC_PASSWORD:?set VNC_PASSWORD}"
CDP_USER="${CDP_USER:-hermes}"
CDP_PASSWORD="${CDP_PASSWORD:?set CDP_PASSWORD}"

mkdir -p /config/chrome /etc/nginx/conf.d

# ---------- nginx: noVNC (:3000, basic auth) + CDP proxy (:9224, basic auth) ----------
VNC_HASH="$(openssl passwd -apr1 "$VNC_PASSWORD")"
CDP_HASH="$(openssl passwd -apr1 "$CDP_PASSWORD")"
printf '%s:%s\n' "$VNC_USER" "$VNC_HASH" > /etc/nginx/.htpasswd_vnc
printf '%s:%s\n' "$CDP_USER" "$CDP_HASH" > /etc/nginx/.htpasswd_cdp
chmod 640 /etc/nginx/.htpasswd_vnc /etc/nginx/.htpasswd_cdp
chown root:www-data /etc/nginx/.htpasswd_vnc /etc/nginx/.htpasswd_cdp

cat > /etc/nginx/conf.d/hermes-browser.conf <<'NGINX_EOF'
server {
    listen 3000;
    auth_basic "hermes-browser";
    auth_basic_user_file /etc/nginx/.htpasswd_vnc;
    location = / { return 302 /vnc.html; }
    location / { root /usr/share/novnc; }
    location /websockify {
        proxy_pass http://127.0.0.1:6080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
    }
}
server {
    listen 9224;
    auth_basic "cdp";
    auth_basic_user_file /etc/nginx/.htpasswd_cdp;
    location / {
        proxy_pass http://127.0.0.1:9222;
        proxy_set_header Host 127.0.0.1;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
    }
}
NGINX_EOF

# ---------- X stack ----------
export DISPLAY=:1
Xvfb :1 -screen 0 1440x900x24 -nolisten tcp &
sleep 1
openbox &
x11vnc -display :1 -rfbport 5900 -localhost -forever -shared -nopw -quiet -bg -o /var/log/x11vnc.log
websockify --web /usr/share/novnc 127.0.0.1:6080 127.0.0.1:5900 &

nginx -g 'daemon off;' &

# ---------- chromium (lean flags) ----------
CHROME_FLAGS=(
  --no-sandbox
  --disable-dev-shm-usage
  --disable-gpu
  --disable-software-rasterizer
  --no-first-run
  --no-default-browser-check
  --hide-crash-restore-bubble
  --disable-sync
  --disable-extensions
  --disable-default-apps
  --disable-background-networking
  --disable-component-update
  --password-store=basic
  --disable-features=Translate,MediaRouter,OptimizationHints,CalculateNativeWinOcclusion
  --renderer-process-limit=2
  --js-flags=--max-old-space-size=300
  --window-size=1400,880
  --window-position=0,0
  --remote-debugging-port=9222
  --remote-allow-origins=*
  --user-data-dir=/config/chrome
)

echo "[browser-lite] starting chromium..."
while true; do
  # stale singleton locks survive container recreates on the persistent profile
  rm -f /config/chrome/SingletonLock /config/chrome/SingletonCookie /config/chrome/SingletonSocket 2>/dev/null || true
  chromium "${CHROME_FLAGS[@]}" about:blank && break
  echo "[browser-lite] chromium exited — restarting in 2s"
  sleep 2
done
