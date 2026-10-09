# cursor-accent — durable backups + re-apply (2026-10-09)

The cursor is the plugin's sage **Bibata-Modern-Classic**, recolored from the
active espressuccin theme (accent `#A7C080`, body `#1a1713`), installed as
`~/.local/share/icons/Omarchy-Accent/` with BOTH:
- `hyprcursors/` — used by the Hyprland compositor (hyprcursor)
- `cursors/`    — XCursor set used by GTK/Qt/Xwayland apps (no hyprcursor support)

WinSur was retired (envs.lua / autostart.lua / gsettings now point at Omarchy-Accent).

## Files here
- `recolor.py` — PATCHED copy of the plugin's `recolor.py` (see below).
- `xcursorgen` — user-local binary (from `xorg-xcursorgen 1.0.9-1`), needs
  `libx11 libxcursor libpng glibc` (all installed on Arch). Lives at `~/.local/bin/xcursorgen`.

## Why recolor.py is patched (3 changes vs the plugin's tracked original)
1. Prepends `~/.local/bin` to `PATH` (so `xcursorgen` is found from hooks/services).
2. Builds `--hypr --x11 --x11-symlink adwaita` in one pass (produces both cursor sets).
3. Adds a fingerprint cache (`~/.local/state/cursor-accent/fingerprint`): the
   `post-boot` hook runs on EVERY Hyprland start, and a full build is ~52s
   (renders the XCursor PNGs at 11 sizes). When the theme/shape/build inputs are
   unchanged it just re-applies the cursor (~0.3s). This keeps login CPU low on
   this 3.3GB / 0.8GHz-clamped box.

## After `omarchy plugin update` (it overwrites the tracked recolor.py)
```bash
cp /mnt/media/Dots/cursor-accent/recolor.py \
   ~/.config/omarchy/plugins/io.github.smoothpixels.cursor-accent/recolor.py
python3 ~/.config/omarchy/plugins/io.github.smoothpixels.cursor-accent/recolor.py espressuccin
```
The hooks in `~/.config/omarchy/hooks/{theme-set,post-boot}.d/cursor-accent.sh`
are user hooks and are NOT touched by plugin updates — they keep calling recolor.py.

## If `xcursorgen` is ever missing again (no sudo)
`xorg-xcursorgen` is in `extra`; deps are already installed.
```bash
mkdir -p ~/.local/bin
curl -fsSL -o /tmp/xcursorgen.pkg.tar.zst \
  https://mirror.omarchy.org/extra/os/x86_64/xorg-xcursorgen-1.0.9-1-x86_64.pkg.tar.zst
bsdtar -xOf /tmp/xcursorgen.pkg.tar.zst usr/bin/xcursorgen > ~/.local/bin/xcursorgen
chmod +x ~/.local/bin/xcursorgen
```
(`rsvg-convert`, from `librsvg`, is also required for the X11 build and is installed.)

## Revert to WinSur (not wanted, recorded for completeness)
```bash
sed -i 's/Omarchy-Accent/WinSur/' ~/.config/hypr/envs.lua
sed -i 's/setcursor Omarchy-Accent/setcursor WinSur/' ~/.config/hypr/autostart.lua
gsettings set org.gnome.desktop.interface cursor-theme 'WinSur'
hyprctl reload && hyprctl setcursor WinSur 16
```
