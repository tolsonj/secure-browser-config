# Secure browser in Docker (Brave + ExpressVPN extension)

This stack runs **Brave** in a container ([LinuxServer.io](https://docs.linuxserver.io/images/docker-brave)) with **noVNC** and an **HTTPS** UI. **VPN is not in Docker** anymore: you use the **ExpressVPN browser extension** inside Brave if you want encrypted/proxied browsing for that session.

This project is tuned on the **`smaller-presence`** branch for **lower CPU usage** while keeping the same LinuxServer Brave image (~3 GB).

## What this approach is

| Piece | Role |
|--------|------|
| **Docker** | Isolated Brave + persistent profile in `./brave-data` |
| **ExpressVPN extension** | Optional; routes **browser** traffic per ExpressVPN’s extension rules when you enable it |
| **Your network** | Everything else (DNS, non-extension traffic, other apps) uses the **host** connection unless the extension covers it |

## What it is not

- **Not** a system-wide or container-wide VPN (unlike the old **Gluetun + OpenVPN** setup).
- **Not** a substitute for the ExpressVPN **desktop app** if you need full-device VPN.

## Prerequisites

- Docker and Docker Compose
- An **ExpressVPN** subscription if you plan to use their **browser extension** (separate from old OpenVPN “manual config” credentials)

## Quick start

1. Start the container:

   ```bash
   docker compose up -d
   ```

2. Open the UI:
   - **HTTP (noVNC):** http://localhost:8123
   - **HTTPS:** https://localhost:8124 (accept the self-signed certificate if prompted)

3. In Brave, install **ExpressVPN** from the [Chrome Web Store](https://chrome.google.com/webstore) (or Brave’s extension flow), pin it, sign in, and connect when you want protected browsing.

4. Data: bookmarks, extensions, and profile live under **`./brave-data`** on the host.

---

## Virtual display and resolution

The container uses **X11 + Xvfb** (not Wayland on Docker Desktop for Mac). By default, LinuxServer Brave creates a **15360×8640** virtual framebuffer — that is very CPU-heavy. You should always clamp resolution explicitly.

### What to set (required for resolution)

Edit these three environment variables in `docker-compose.yml`:

```yaml
- SELKIES_MANUAL_WIDTH=1280    # width in pixels
- SELKIES_MANUAL_HEIGHT=720    # height in pixels
- MAX_RES=1280x720             # max virtual framebuffer (WIDTHxHEIGHT, no spaces)
```

| Variable | Purpose |
|----------|---------|
| `SELKIES_MANUAL_WIDTH` | Locks the virtual display width. Setting width or height enables manual resolution mode. |
| `SELKIES_MANUAL_HEIGHT` | Locks the virtual display height. |
| `MAX_RES` | Caps the X11 virtual framebuffer size. Use the same value as your target resolution. |

**Apply changes** (required after every resolution change):

```bash
docker compose up -d --force-recreate
```

**Verify** the new size:

```bash
docker exec brave-browser ps aux | grep Xvfb
# Example output: -screen 0 1280x720x24
```

Or check env vars inside the container:

```bash
docker exec brave-browser env | grep -E 'SELKIES_MANUAL|MAX_RES'
```

### Resolution presets

Copy one of these blocks into `docker-compose.yml` under `environment:`.

**Low CPU (current default)**

```yaml
- SELKIES_MANUAL_WIDTH=1280
- SELKIES_MANUAL_HEIGHT=720
- MAX_RES=1280x720
```

**Balanced**

```yaml
- SELKIES_MANUAL_WIDTH=1920
- SELKIES_MANUAL_HEIGHT=1080
- MAX_RES=1920x1080
```

**Sharp / more desktop space**

```yaml
- SELKIES_MANUAL_WIDTH=2560
- SELKIES_MANUAL_HEIGHT=1440
- MAX_RES=2560x1440
```

**4K (highest CPU)**

```yaml
- SELKIES_MANUAL_WIDTH=3840
- SELKIES_MANUAL_HEIGHT=2160
- MAX_RES=3840x2160
```

| Preset | Resolution | CPU | Notes |
|--------|------------|-----|-------|
| Low CPU | 1280×720 | Lowest | Smaller text and UI; best for idle savings |
| Balanced | 1920×1080 | Medium | Good default for general browsing |
| Sharp | 2560×1440 | Higher | More screen real estate |
| 4K | 3840×2160 | High | Only if you need maximum clarity |
| Unset (avoid) | 15360×8640 | Very high | LinuxServer default when manual vars are omitted |

### Optional display-related settings

| Variable | Default | Purpose |
|----------|---------|---------|
| `SELKIES_FRAMERATE` | `8-120` | Stream framerate. Set a fixed value (e.g. `30` or `15`) to reduce encode CPU. |
| `SELKIES_ENCODER` | `x264enc,...` | Video encoder. `jpeg` is lighter when H.264 is not needed. |
| `SELKIES_SCALING_DPI` | `96` | UI/text scale inside the session. |
| `SELKIES_USE_CSS_SCALING` | `False` | If `True`, streams a lower resolution and stretches in the browser (less CPU, blurrier). |
| `SELKIES_SECOND_SCREEN` | `True` | Second virtual monitor. Set `False` to save CPU/RAM. |

You can also change some display options in the **Selkies sidebar** at https://localhost:8124 under **Screen settings**, unless a value is locked in `docker-compose.yml`.

---

## All tunable settings

Current `docker-compose.yml` on **`smaller-presence`**:

### Container basics

| Setting | Value | Purpose |
|---------|-------|---------|
| `PUID` / `PGID` | `1000` | File ownership for `./brave-data` |
| `TZ` | `America/New_York` | Container time zone |
| `ports` | `8123`, `8124` | Host → container (noVNC / HTTPS UI) |
| `shm_size` | `1gb` | Shared memory for Brave (LinuxServer recommends ≥1 GB) |
| `restart` | `unless-stopped` | Stays stopped when you stop it manually |
| `cpus` limit | `0.75` | Max CPU cores the container can use |
| `memory` limit | `2G` | Max RAM |

### Streaming / Selkies (CPU savings)

| Setting | Value | Purpose |
|---------|-------|---------|
| `SELKIES_FRAMERATE` | `30` | Fixed 30 fps stream (lower = less CPU) |
| `SELKIES_ENCODER` | `jpeg` | Lighter encoder than default H.264 |
| `SELKIES_AUDIO_ENABLED` | `False` | Disable audio streaming |
| `SELKIES_MICROPHONE_ENABLED` | `False` | Disable mic forwarding |
| `SELKIES_GAMEPAD_ENABLED` | `False` | Disable gamepad support |
| `SELKIES_ENABLE_SHARING` | `False` | Disable session sharing links |

Set any disabled feature back to `True` if you need it (e.g. audio for video playback).

### Brave launch flags

| Setting | Purpose |
|---------|---------|
| `BRAVE_CLI` | Extra Chromium flags passed at startup |

Current flags reduce background work and renderer count while keeping extensions (including ExpressVPN) working:

```
--disable-background-networking --disable-sync --disable-component-update --disable-features=Translate,MediaRouter,IsolateOrigins,site-per-process --process-per-site
```

---

## Apply any configuration change

After editing `docker-compose.yml`:

```bash
docker compose up -d --force-recreate
```

---

## Troubleshooting

- **No outbound from Brave:** from the project directory run `./debug-connectivity.sh` (checks `wget` / DNS inside `brave-browser`).
- **Extension won’t install or connect:** confirm your ExpressVPN account supports the **browser extension**; try the HTTPS UI or ExpressVPN’s own troubleshooting docs.
- **Resolution did not change:** confirm you ran `--force-recreate`, then check `docker exec brave-browser ps aux | grep Xvfb`.
- **High CPU after resolution change:** try 1280×720 and `SELKIES_FRAMERATE=15`.

## Migrating from the old Gluetun setup

The following are **removed** from this project:

- **Gluetun** (`vpn` service), OpenVPN credentials in Compose, `./gluetun` server list scripts
- **`rotate-vpn.sh`**, **`update-gluetun-servers.sh`**

You can delete the **`./gluetun`** directory on disk if it is still there. Old **OpenVPN username/password** values are no longer in `docker-compose.yml`; rotate them in your ExpressVPN account if they were ever committed or shared.
