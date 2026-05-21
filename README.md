# Secure browser in Docker (Brave + ExpressVPN extension)

This stack runs **Brave** in a container ([LinuxServer.io](https://docs.linuxserver.io/images/docker-brave)) with **noVNC** and an **HTTPS** UI. **VPN is not in Docker** anymore: you use the **ExpressVPN browser extension** inside Brave if you want encrypted/proxied browsing for that session.

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

   If you removed the old VPN service and still see an orphan **`vpn`** container:

   ```bash
   docker compose up -d --remove-orphans
   ```

2. Open the UI:
   - **HTTP (noVNC):** http://localhost:8123  
   - **HTTPS:** https://localhost:8124 (accept the self-signed certificate if prompted)

3. In Brave, install **ExpressVPN** from the [Chrome Web Store](https://chrome.google.com/webstore) (or Brave’s extension flow), pin it, sign in, and connect when you want protected browsing.

4. Data: bookmarks, extensions, and profile live under **`./brave-data`** on the host.

## Configuration

Edit `docker-compose.yml` as needed:

- **`PUID` / `PGID`** — align with your host user for `brave-data` ownership (default `1000`).
- **`TZ`** — time zone for the container.
- **`ports`** — default published ports are **8123** → 3000 (noVNC) and **8124** → 3001 (HTTPS).
- **`deploy.resources.limits.cpus`** — raise or lower the CPU cap for Brave.

Optional: use `.env` for values you inject into Compose later (file is optional for the current compose).

## Troubleshooting

- **No outbound from Brave:** from the project directory run `./debug-connectivity.sh` (checks `wget` / DNS inside `brave-browser`).
- **Extension won’t install or connect:** confirm your ExpressVPN account supports the **browser extension**; try the HTTPS UI or ExpressVPN’s own troubleshooting docs.

## Migrating from the old Gluetun setup

The following are **removed** from this project:

- **Gluetun** (`vpn` service), OpenVPN credentials in Compose, `./gluetun` server list scripts  
- **`rotate-vpn.sh`**, **`update-gluetun-servers.sh`**

You can delete the **`./gluetun`** directory on disk if it is still there. Old **OpenVPN username/password** values are no longer in `docker-compose.yml`; rotate them in your ExpressVPN account if they were ever committed or shared.
