---
name: nordvpn-zong-nordgui
description: Keep NordVPN working on the ZONG carrier (and similar SNI/DPI-filtering networks) using the custom OpenVPN-based NordGUI instead of the official client, including its build, packaging, install, and GitHub upstream workflow. Use when the official `nordvpn` client hangs at "Connecting" on ZONG, when the user wants to (re)build or upstream the custom NordGUI, or when troubleshooting NordVPN connectivity, About version mismatch, or passwordless Connect on this machine.
---

# NordVPN on ZONG — custom NordGUI (the working client)

## Why the official client fails here
- **ZONG escalated to DPI/SNI filtering (2026-08-22).** It allows `api.nordvpn.com` (Cloudflare front, ECH outer SNI `cloudflare-ech.com`) so login works, but **resets/drops TLS to Nord VPN server hostnames** (`uk*.nordvpn.com`, `ae*.nordvpn.com`, etc.). Therefore:
  - Official `nordvpn` client hangs at "Connecting": auth succeeds, tunnel setup RST/timeout.
  - `NORDLYNX` (WireGuard UDP) is blocked; `NORDWHISPER`/Webtunnel also gets reset.
- A plain `curl https://api.nordvpn.com` works (it is NOT the blocked resource) — do not let that fool you into thinking the client "should" connect.

## The working solution: custom NordGUI
- A GTK4/libadwaita OpenVPN front-end (solitude-themed) that drives OpenVPN directly via a `pkexec` helper. It does **not** use `nordvpnd`.
- It connects because the server `.ovpn` files are Nord's **port-53 UDP** anti-censorship profile: every `remote` line is a bare IP on UDP/53 (`remote 146.70.238.3 53`), `proto udp`, `verify-x509-name CN=<host>.nordvpn.com` — **no server hostname/SNI** is sent, so ZONG's SNI filter can't match it.
- **Status (2026-08-22):** custom NordGUI is the ACTIVE client; the official `nordvpn`/`nordvpn-bin` package is removed. Verified connected (e.g. Azerbaijan) via the UDP/53 profiles.

## Key file locations
- App (source): `/usr/local/share/nordvpn-gui/nordvpn_gui.py` (root-owned 0755)
- Launcher: `/usr/local/bin/nordvpn-gui`
- Helper (root, pkexec target): `/usr/local/bin/nordvpn-gui-helper`
- Polkit rule (MUST be here): `/etc/polkit-1/rules.d/50-nordvpn-gui.rules`
- Server configs (imported via GUI "Add server files"): `~/.config/nordgui/servers/*.ovpn` (legacy `~/nordvpn/*.ovpn` is also scanned)
- Credentials: `~/.nordvpn-creds` (line 1 = username, line 2 = password; mode 600)
- Packaged download: `/mnt/media/Dots/nord/nordgui-1.2-1-any.pkg.tar.zst`
- Source of truth: GitHub repo `git@github.com:Xtremist98/nordgui.git` (branch `main`). The local packaging tree `/home/linuxer/nordgui` was deleted; clone from GitHub to build.

## Build & packaging (PKGBUILD)
- Version is **two places that must stay in sync**: `PKGBUILD` `pkgver` and the `d.set_version("X.Y")` string in `nordvpn_gui.py` (line ~1550). If they differ, **About** shows the stale string. Current = `1.2` / `1.2-1`.
- PKGBUILD builds from a tarball `nordgui-$pkgver.tar.gz` that contains a top-level `nordgui-$pkgver/` directory (with `share/`, `bin/`, etc.). Build steps:
  1. `cp` the edited `share/nordvpn-gui/nordvpn_gui.py` into the versioned staging dir.
  2. `tar czf nordgui-$pkgver.tar.gz nordgui-$pkgver` (the PKGBUILD `source` points at this).
  3. `makepkg` (run **without** `-s`; all deps already present on this box).
- **Packaging gotchas (already fixed in 1.2, do not regress):**
  - `depends=('librsvg')` — NOT `'rsvg-convert'` (that's a command; `pacman` can't resolve a command as a dep and the build aborts unless you pass `makepkg --assume-installed rsvg-convert`).
  - The polkit rule installs to **`/etc/polkit-1/rules.d/`** — polkit ignores `/usr/local/share/polkit-1/rules.d/`. The 1.1.1 package shipped it to the wrong path, so Connect always prompted for a password.
- Install: `sudo pacman -U /mnt/media/Dots/nord/nordgui-1.2-1-any.pkg.tar.zst`.

## Upstream (GitHub) workflow
- `gh` is authenticated as `Xtremist98` (token in OS keyring) and SSH push works.
- After a new build:
  1. Back up the `.pkg.tar.zst` to `/mnt/media/Dots/nord/`.
  2. In the cloned repo: `git add -A && git commit -m "..." && git push origin main`.
  3. Release: `gh release create vX.Y --title "vX.Y" --notes "..." --repo Xtremist98/nordgui /mnt/media/Dots/nord/nordgui-X.Y-1-any.pkg.tar.zst`.
- **Replacing a release asset:** `gh release delete-asset` with the GraphQL `RA_...` ID is flaky ("not found"). The reliable path is `gh release delete vX.Y --repo Xtremist98/nordgui -y` then `gh release create vX.Y ...` again (this also lets you delete the now-stale git tag with `git tag -d vX.Y && git push origin :vX.Y`). For a pure version bump, prefer deleting the old release+tag and recreating rather than swapping assets in place.

## DNS / killswitch (from the 2026-08-21 fixes — still apply)
- Keep `nordvpn set dns 127.0.0.1` (local dnscrypt DoH proxy on `:53`) so DNS resolves real IPs through the tunnel and direct. Do NOT re-enable the NordVPN kill switch (it blocks all traffic when the VPN is down).
- These `nordvpn` settings are only relevant if the official client is ever reinstalled; the custom GUI bypasses nordvpn config entirely.

## Troubleshooting
- **About shows wrong version** → edit `d.set_version(...)` in `nordvpn_gui.py` (both installed `/usr/local/share/...` and the repo source), rebuild.
- **Connect prompts for password** → polkit rule missing from `/etc/polkit-1/rules.d/`; reinstall the corrected package (or `sudo cp` the rule there).
- **Officially-client "Connecting" wedge** → that's the removed `nordvpnd`; `sudo systemctl restart nordvpnd` only matters if the official client is reinstalled. The custom GUI uses `openvpn` via the helper, not `nordvpnd`.
- **If ZONG blocks UDP/53 too** → next lever: switch the `.ovpn` profiles to TCP/443 (`proto tcp`, `remote <ip> 443`). Not needed as of 2026-08-22.
- **"No internet without VPN"** → check `ip route | grep tun0` (orphaned tunnel) and `resolvectl` DNS (must be `127.0.0.1`). See the ZONG DNS-hijack notes in AGENTS.md.

## Caveat
NordGUI works *as long as* ZONG keeps allowing UDP/53 to Nord's server IPs. The official client cannot be made to work on this carrier today.
