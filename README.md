# hermes-browser-lite

Lightweight server-hosted browser for automation:

- **Chromium** driven over **CDP** (DevTools protocol)
- **noVNC** web UI (Xvfb + x11vnc + websockify) — log into sites yourself from any device
- **nginx** basic-auth gates on both surfaces
- Persian/Arabic-capable fonts included
- Persistent profile volume (`/config`)

Roughly 2–3× lighter on RAM than a full linuxserver/chromium stack:
no KasmVNC desktop, no window decorations overhead — just Xvfb + x11vnc + openbox + chromium.

## Env

| Var | Default | Purpose |
|---|---|---|
| `VNC_USER` | `hermes` | noVNC basic-auth user |
| `VNC_PASSWORD` | — (required) | noVNC basic-auth password |
| `CDP_USER` | `hermes` | CDP basic-auth user |
| `CDP_PASSWORD` | — (required) | CDP basic-auth password |

## Ports

- `3000` — noVNC web UI (point a domain/router here)
- `9224` — CDP proxy (with auth) → `127.0.0.1:9222`

## Docker

```yaml
services:
  browser:
    build:
      context: https://github.com/Hadi77io/hermes-browser-lite.git#main
    mem_limit: 1100m
    shm_size: 512m
    security_opt: [seccomp:unconfined]
    environment:
      VNC_USER: hermes
      VNC_PASSWORD: "change-me"
      CDP_USER: hermes
      CDP_PASSWORD: "change-me-too"
    volumes:
      - blite_config:/config
    ports:
      - "49814:9224"
volumes:
  blite_config:
```
