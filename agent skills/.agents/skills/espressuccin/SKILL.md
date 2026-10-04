---
name: espressuccin
description: Build, switch, and maintain the Espressuccin warm café-dark Omarchy theme on this machine — covers the thpm edit/regen chain (source gtk.css → omarchy theme refresh → thpm hook-run), the Nautilus row:selected selection fix, GTK CSS parser constraints (!important and custom properties unsupported in GTK3), the gsettings reset pitfall after `omarchy theme refresh`, root-app theming (fix-root-espressuccin.sh), the shipped GTK package backup, and the Brave solid-#1a1713 wallpaper. Use when editing the espressuccin theme, fixing GTK3 app colors (Nautilus/xed/pavucontrol/Chromium/Brave), or re-theming root apps.
---

# Espressuccin — warm café-dark Omarchy theme

## Architecture (thpm copy chain — VERIFIED)
espressuccin is a **full GTK theme + thpm overlay** hybrid. The GTK CSS is hand-authored in ONE source file:

```
~/.config/omarchy/themes/espressuccin/gtk.css   ← THE source of truth (hand-authored)
```
It reaches the live session via a 3-step chain (thpm does NOT author CSS — it only copies theme-provided `gtk.css` verbatim; it would only *generate* one from colors.toml when a theme ships NO gtk.css, per `thpm/compat.py:_gtk_payload`):

1. **`omarchy theme refresh`** — stages `gtk.css` → `~/.local/state/omarchy/current/theme/gtk.css` (thpm reads THIS staged copy, not the source dir directly).
2. **`thpm hook-run theme-set espressuccin`** — copies the staged file → `~/.config/gtk-{3.0,4.0}/thpm-theme.css` (the live overlay).
3. `~/.config/gtk-{3.0,4.0}/gtk.css` are 83-byte `@import url('thpm-theme.css')` stubs.

**Editing `thpm-theme.css` directly is pointless** — overwritten next regen. Always edit the source, then `omarchy theme refresh && thpm hook-run theme-set espressuccin`.

**BUT `omarchy theme refresh` resets gsettings `gtk-theme` → `'Adwaita-dark'`.** Fix = `hyprctl reload`, which re-runs `~/.config/hypr/looknfeel.lua` (~line 21): it sets `gsettings ... gtk-theme` from `~/.local/state/omarchy/current/theme.name` (fallback Adwaita-dark). Live value must be `'espressuccin'`.

All four files must stay **md5-identical** `22ca6ae5b848d403d510bdc2c7be4df0`:
- `~/.config/omarchy/themes/espressuccin/gtk.css`
- `~/.local/state/omarchy/current/theme/gtk.css`
- `~/.config/gtk-3.0/thpm-theme.css`
- `~/.config/gtk-4.0/thpm-theme.css`

## GTK CSS parser constraints (both HIT 2026-09-22)
- **`!important` is NOT supported by the GTK CSS parser** → error "Junk at end of value". Never use it.
- **GTK3 does NOT support CSS custom properties** (`--accent-bg-color: ...`) → "gtk.css:N:4 Expected semicolon" parse failure that kills the ENTIRE overlay (apps fall back to raw theme). Custom-property blocks only parse in the GTK4/libadwaita layer. When writing selectors that must survive in `thpm-theme.css` (loaded by both GTK3 and GTK4), use plain `background-color:`/`color:` rules only.

## Nautilus selection color (THE fix — user-confirmed 2026-09-22)
**Symptom:** Nautilus file/folder selection rendered `#403e3c` (a muted red-brown, not theme selection `#2e2a24`).
**Root cause:** Nautilus ships app-priority CSS (higher than user) that pins `row:selected` to `#403e3c`; the theme-priority solid selection rules lose → only themed when a user-priority rule matches.
**Fix (works):** solid `row:selected` rules in the thpm user chain (which runs at priority 800, above app CSS):
```css
columnview row:selected, listview row:selected, treeview.view row:selected,
filechooser columnview > listview row:selected, .nautilus-list-view row:selected {
  background-color: #2e2a24; color: #d1c4a9;
}
```
Now **9 `row:selected` matches** in `thpm-theme.css` (grep-count). The fix needed only these plain rules — a GTK4-only `--accent-bg-color` custom-property block (added for the same goal) had to be REMOVED because it broke the GTK3 parse (see constraints above).

## Palette (espressuccin)
- Flat warm espresso surfaces, ALL `#1a1713` (background/dark/darker/lighter).
- Single creamy ink: `foreground #d1c4a9` (no two-tier — user decision 2026-09-21 for everpuccin does NOT carry over; espressuccin is one ink). `dark_foreground #8a8274`. cursor `#d1c4a9`.
- `accent #A7C080` (sage), `selection #2e2a24` (raised), muted `#7c7468`.
- Syntax: red `#E67E80`, green `#A7C080`, yellow `#DBBC7F`, blue `#7FBBB3`, magenta `#D699B6`, cyan `#83C092`, orange `#E69875`, brown `#A19983`. Brights `#F18F91/#B7D090/#E7C78B/#8FCAC2/#E3A8C3/#98D1A6`.
- ANSI 16-color table (warm blacks, single ink for whites): color0 `#241f19`, color7/color15 `#d1c4a9`, color8 `#5c584e`, colors 1-6/9-14 = the syntax hues.
- **Hyprland active border = SINGLE Sage Green** `rgba(A7C080ff)` (NOT the multi-stop gradients of rose-pine); inactive `rgba(2E2A24aa)`.
- Theme dir `~/.config/omarchy/themes/espressuccin/`: `colors.toml`, `gtk.css`, `shell.toml`, `hyprland.lua`, `icons.theme`, `cliamp.toml`, `backgrounds/`, `preview.png`.
- Live icon theme `'Yaru-wartybrown'` (from theme's `icons.theme` via 55-icon-theme hook).

## GTK apps coverage
- **GTK3 apps (xed, pavucontrol, Chromium/Brave, gnome-disks):** read the GTK3 theme name. They're themed only if `gsettings gtk-theme` = `'espressuccin'` (looknfeel.lua assertion + full theme installed). If they look unthemed after any theme op, run `hyprctl reload` and re-check gsettings.
- **Chromium/Brave chrome is `#1a1713`** via GTK3 `window_bg_color` (`gtk-3.0/gtk.css` line ~61) + `.background.chromium` rules.

## Brave solid wallpaper (2026-09-22)
User wants a plain flat `#1a1713` background for Brave. PNG: **`/home/linuxer/Pictures/Wallpapers/brave/solid-1a1713.png`** (1920×1080, every pixel `(26,23,19)` = `#1a1713`, verified with numpy). That reference is for Brave's New Tab custom background / desktop wall — NOT a desktop-theme change.

## Root apps (`/home/linuxer/fix-root-espressuccin.sh` — run `sudo bash ~/fix-root-espressuccin.sh`)
Idempotent 3-step script (agent is sudoless — user must run it):
1. `[1/3]` Refresh `/usr/share/themes/espressuccin` from staging `/home/linuxer/espressuccin-theme-build/espressuccin` (chmod a+rX).
2. `[2/3]` `/root/.config/gtk-{3.0,4.0}`: copy theme `gtk.css` → `thpm-theme.css` + `@import` stub, then write `settings.ini`:
   - `gtk-theme-name=espressuccin`, `gtk-application-prefer-dark-theme=true`
   - **NO icon-theme line** (user decision: "let the system render it from the theme itself" — do not re-add `gtk-icon-theme-name`).
3. `[3/3]` `/usr/bin/gparted` wrapper `export GTK_THEME=espressuccin` via sed.

**Why step 2 is needed:** `/root/.config/gtk-*` only ever had CSS overlays, never `settings.ini`, so root apps (btrfs-assistant, gparted via pkexec) pinned `gtk-theme-name=rose-pine-dark` — stale. Kvantum + qt6ct steps were REMOVED from the script per user decision (2026-09-22) — current version is only the 3 steps above. The agent CANNOT verify `/root/...` — use `sudo cat /root/.config/gtk-3.0/settings.ini`.

## Package backup (shipped, NO rebuild needed)
- `/mnt/media/Dots/gtk-themes/espressuccin-gtk-theme-1.0-1-any.pkg.tar.zst` (md5 matches the build pkg `c6569eee...`).
- Build payload `/home/linuxer/espressuccin-theme-build/espressuccin` is byte-identical to live `/usr/share/themes/espressuccin`.
- Pkg already contains the selection fix in `libadwaita-tweaks.css` (5 `row:selected`).

## Verification snippets
```
md5sum ~/.config/omarchy/themes/espressuccin/gtk.css \
       ~/.local/state/omarchy/current/theme/gtk.css \
       ~/.config/gtk-{3,4}.0/thpm-theme.css          # all 22ca6ae5b848d403d510bdc2c7be4df0
grep -c row:selected ~/.config/gtk-4.0/thpm-theme.css # 9
gsettings get org.gnome.desktop.interface gtk-theme   # 'espressuccin'
gsettings get org.gnome.desktop.interface icon-theme   # 'Yaru-wartybrown'
grep -c '!important' ~/.config/gtk-4.0/thpm-theme.css  # 0
grep -c '--accent-bg-color' ~/.config/gtk-{3,4}.0/thpm-theme.css  # 0
```
Parse-check both overlays with GTK's CssProvider (Gtk.CssProvider.load_from_path) — must not error.

## General edit runbook (post-edit)
1. Edit `~/.config/omarchy/themes/espressuccin/gtk.css`.
2. `omarchy theme refresh` (stages copy; WARNING: also resets gsettings gtk-theme).
3. `thpm hook-run theme-set espressuccin` (copies to both thpm-theme.css).
4. `hyprctl reload` (re-asserts gsettings gtk-theme='espressuccin' from theme.name).
5. Verify md5 parity + `grep -c row:selected` = 9 + no `!important`/`--accent-bg-color` + parse clean.
6. Relaunch affected GTK apps (they read CSS at launch).