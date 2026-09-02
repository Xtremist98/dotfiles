# stremio-service 0.1.22 (manual AUR-free install)

Stremio Service companion daemon for Stremio Web, **v0.1.22** (latest upstream, 2026-08-25).
Payload extracted from the official release `.deb`:
`https://github.com/Stremio/stremio-service/releases/download/v0.1.22/stremio-service_amd64.deb`

## Why this exists

The AUR `stremio-service` package compiles from Rust source (long, eats all CPU/hangs the machine).
The `stremio-service-bin` AUR package ships a prebuilt `.deb` but is **stale at v0.1.15** (flagged out-of-date, no maintainer update).
This directory is a pre-built **v0.1.22** payload so a fresh install/rebuild needs no compilation and no AUR.

## Install (fresh machine)

```bash
cd /mnt/media/Dots/stremio-service
sudo bash install.sh
```

What it does:
1. Removes old `stremio-service-bin` if installed (pacman).
2. Installs the v0.1.22 files (tar copy, modes preserved) to:
   - `/usr/bin/stremio-service` (bash wrapper → `/usr/share/stremio-service/stremio-service`)
   - `/usr/share/stremio-service/` (`stremio-service` binary, `stremio-runtime`, `server.js`, `ffmpeg`, `ffprobe`)
   - `/usr/share/applications/com.stremio.service.desktop`
   - `/usr/share/icons/hicolor/scalable/apps/com.stremio.service.svg`
   - `/usr/share/metainfo/com.stremio.service.metainfo.xml`
   - `/usr/share/licenses/stremio-service/LICENSE.md`
3. Refreshes desktop/icon databases.
4. Prints version → expect `stremio-service 0.1.22`.

> Note: files owned by root (installed via sudo). There is **no pacman package record** for this manual install
> (pacman won't track/upgrade it). To update later, drop a newer `.deb` here and re-run `install.sh`
> (optionally un-`tar` it into `usr/` first, or just let install.sh overwrite).

## Manual one-off (no sudo script)

If you just want to re-apply files without the script:

```bash
cd /usr/share/stremio-service
sudo tar -xf /path/to/MEDIA/Dots/stremio-service/usr.tar ...  # not provided; files are expanded in usr/
```

Simplest manual route: use the script above.

## Autostart / service

The desktop entry triggers a per-user autostart unit. After install, confirm the service runs:

```bash
systemctl --user list-units --all | grep -i stremio
```

Start it now (if not already):

```bash
systemctl --user start app-com.stremio.service@autostart.service   # or the package's autostart name
```

## Gotcha

`/usr/bin/stremio-service` is a **bash wrapper** and MUST be executable (`0755`). The tar copy preserves it.
If you ever copy files manually and get `Permission denied`, just: `sudo chmod 755 /usr/bin/stremio-service`.

## Version history

- 0.1.22 (this payload) — 2026-08-25
- 0.1.21 — 2026-03-15
- 0.1.15 — last AUR `stremio-service-bin` (stale)