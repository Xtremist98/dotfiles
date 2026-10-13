# cursor-accent — durable backups + re-apply (updated 2026-10-10)

The cursor is the plugin's sage **Bibata-Modern-Classic**, recolored from the
active theme (espressuccin: accent `#A7C080`, body `#1a1713`), installed as
`~/.local/share/icons/Omarchy-Accent/` with BOTH:
- `hyprcursors/` — used by the Hyprland compositor (hyprcursor)
- `cursors/`    — XCursor set used by GTK/Qt/Xwayland apps (no hyprcursor support)

## Current model (2026-10-10) — canonical plugin setup, NO theme env, size 18
- Plugin installed the README way: `omarchy plugin add https://github.com/SmoothPixels/cursor-accent.git --enable --yes`
  then `~/.config/omarchy/plugins/io.github.smoothpixels.cursor-accent/tools/install-cursor-hook.sh`
  (installs the `theme-set` + `post-boot` hooks into `~/.config/omarchy/hooks/`).
- `~/.config/hypr/envs.lua` sets ONLY `HYPRCURSOR_SIZE=18` + `XCURSOR_SIZE=18` (user tuned 20 → 18).
  There is deliberately **no `HYPRCURSOR_THEME` / `XCURSOR_THEME`** — the plugin's
  post-boot hook applies `Omarchy-Accent` each login.
- `~/.config/hypr/autostart.lua` has **no** `hyprctl setcursor` line.
- `gsettings org.gnome.desktop.interface cursor-theme 'Omarchy-Accent'`, `cursor-size 18`
  (GTK apps; needs the `cursors/` set).
- A fresh Omarchy carries no cursor theme to clean up — nothing to remove.

## Files here
- `recolor.py` — PATCHED copy of the plugin's `recolor.py` (see below).
- `xcursorgen` — user-local binary (from `xorg-xcursorgen 1.0.9-1`), needs
  `libx11 libxcursor libpng glibc`. Lives at `~/.local/bin/xcursorgen`.

## Why recolor.py is patched (4 changes vs the plugin's tracked original)
1. Prepends `~/.local/bin` to `PATH` (so `xcursorgen` is found from hooks/services).
2. Builds `--hypr --x11 --x11-symlink adwaita` in one pass (both cursor sets).
3. Fingerprint cache (`~/.local/state/cursor-accent/fingerprint`): the `post-boot`
   hook runs on EVERY Hyprland start and a full build is ~52s (XCursor PNGs at
   11 sizes). When inputs are unchanged it just re-applies (~0.3s). Keeps login
   cheap on this 3.3GB / 0.8GHz-clamped box.
4. **Atomic install** (2026-10-10): the original does `rmtree(install_dir)` then
   `copytree`, leaving a window where the theme is empty/half-written. A running
   Hyprland reading a shape then gets a NULL cairo surface and **segfaults** in
   `CCursorBuffer` (crash report 2026-10-09, matched the rebuild). The patch
   builds `.Omarchy-Accent.new`, then `rename()` swaps it in (atomic on the same
   fs) with the old one moved aside, so the theme dir is never absent/partial.

## After `omarchy plugin update` / `plugin add` (it overwrites recolor.py)
```bash
cp /mnt/media/Dots/cursor-accent/recolor.py \
   ~/.config/omarchy/plugins/io.github.smoothpixels.cursor-accent/recolor.py
bash ~/.config/omarchy/plugins/io.github.smoothpixels.cursor-accent/tools/install-cursor-hook.sh
```
The hooks in `~/.config/omarchy/hooks/{theme-set,post-boot}.d/cursor-accent.sh`
are user hooks, NOT touched by plugin updates — they keep calling recolor.py.
Re-run `install-cursor-hook.sh` only if the plugin's install path changes.

## If `xcursorgen` is ever missing again (no sudo)
```bash
mkdir -p ~/.local/bin
curl -fsSL -o /tmp/xcursorgen.pkg.tar.zst \
  https://mirror.omarchy.org/extra/os/x86_64/xorg-xcursorgen-1.0.9-1-x86_64.pkg.tar.zst
bsdtar -xOf /tmp/xcursorgen.pkg.tar.zst usr/bin/xcursorgen > ~/.local/bin/xcursorgen
chmod +x ~/.local/bin/xcursorgen
```
(`rsvg-convert`, from `librsvg`, is also required for the X11 build and is installed.)

## Verify
```bash
ls ~/.local/share/icons/Omarchy-Accent/{cursors,hyprcursors} | head
file ~/.local/share/icons/Omarchy-Accent/cursors/left_ptr   # Xcursor data v1.0
hyprctl configerrors   # empty
```
