# cursor-accent — durable backups + re-apply (updated 2026-10-13)

> ⚠️ **DO NOT delete `install.sh` / `plugin/` / `INSTALL.txt` from this folder.**
> They are the **one-line OFFLINE installer for fresh Omarchy machines** and are
> load-bearing for a use case nothing else covers — a new box with no internet.
> `install.sh` ships `plugin/` next to it and does
> `rsync -a --delete "$BUNDLE/" "$PLUGIN_DIR/"`, so it is useless without it.
> Canonical mirror: `https://github.com/Xtremist98/dotfiles/tree/main/cursor-accent`
> (if it is ever lost here again, re-clone with
> `git clone --depth 1 --filter=blob:none --sparse Xtremist98/dotfiles && git sparse-checkout set cursor-accent`).
>
> This folder therefore serves **two distinct purposes** — do not conflate them:
> - **The offline installer** (`install.sh` + `plugin/` + `INSTALL.txt`) — for a
>   fresh machine with no network. Run it there; you never need it on this box.
> - **The patch kit** (`recolor.py` + `xcursorgen` + this file) — for repairing
>   *this* box after `omarchy plugin update` / `plugin add` overwrites the
>   tracked `recolor.py`.
>
> **Only caveat:** `install.sh` would also overwrite the *live* plugin on this
> box with the frozen `plugin/` snapshot, reverting any upstream fixes made
> since the bundle was cut. So on this box prefer
> `omarchy plugin add ... && cp recolor.py` over running `install.sh`.

The cursor is the plugin's sage **Bibata-Modern-Classic**, recolored from the
active theme (espressuccin: accent `#A7C080`, body `#1a1713`), installed as
`~/.local/share/icons/Omarchy-Accent/` with BOTH:
- `hyprcursors/` — used by the Hyprland compositor (hyprcursor)
- `cursors/`    — XCursor set used by GTK/Qt/Xwayland apps (no hyprcursor support)

## Current model (2026-10-10) — canonical plugin setup, NO theme env, size 18
- Plugin installed the README way: `omarchy plugin add https://github.com/SmoothPixels/cursor-accent.git --enable --yes`
  then `~/.config/omarchy/plugins/io.github.smoothpixels.cursor-accent/tools/install-cursor-hook.sh`
  (installs the `theme-set` + `post-boot` hooks into `~/.config/omarchy/hooks/`).
- `~/.config/hypr/envs.lua` sets `HYPRCURSOR_SIZE` + `XCURSOR_SIZE` (both **16** as of
  2026-10-13) and, since hyprcursor is disabled, **`XCURSOR_THEME=Omarchy-Accent`**.
  `HYPRCURSOR_THEME` stays unset.
- `~/.config/hypr/autostart.lua` has **no** `hyprctl setcursor` line.
- `gsettings org.gnome.desktop.interface cursor-theme 'Omarchy-Accent'`, `cursor-size 16`.
- A fresh Omarchy carries no cursor theme to clean up — nothing to remove.

## Files here
- `recolor.py` — PATCHED copy of the plugin's `recolor.py` (see below).
- `xcursorgen` — user-local binary (from `xorg-xcursorgen 1.0.9-1`), needs
  `libx11 libxcursor libpng glibc`. Lives at `~/.local/bin/xcursorgen`.
- `REAPPLY.md` — this file.
- `install.sh` + `plugin/` + `INSTALL.txt` — the **offline installer** for a fresh
  Omarchy box. Usage (from its header):
  ```
  bash install.sh            # install everything, size 16
  CURSOR_SIZE=20 bash install.sh
  ```
  It checks its preconditions (`omarchy`, `python3`, `rsvg-convert`), copies the
  bundled `plugin/` into `~/.config/omarchy/plugins/io.github.smoothpixels.cursor-accent`,
  writes the patched `recolor.py`, runs `tools/install-cursor-hook.sh`, wires
  `envs.lua` / `autostart.lua` / gsettings, installs the embedded `xcursorgen`,
  and does the final build. Idempotent and re-runnable.

## Why recolor.py is patched (4 changes vs the plugin's tracked original)
1. Prepends `~/.local/bin` to `PATH` (so `xcursorgen` is found from hooks/services).
2. Builds `--hypr --x11 --x11-symlink adwaita` in one pass (both cursor sets).
3. Fingerprint cache (`~/.local/state/cursor-accent/fingerprint`): the `post-boot`
   hook runs on EVERY Hyprland start and a full build is ~52s (XCursor PNGs at
   11 sizes). When inputs are unchanged it just re-applies (~0.15s). Keeps login
   cheap on this 3.3GB / 0.8GHz-clamped box.
4. **Atomic install** (2026-10-10): the original does `rmtree(install_dir)` then
   `copytree`, leaving a window where the theme is empty/half-written. A running
   Hyprland reading a shape then gets a NULL cairo surface and **segfaults** in
   `CCursorBuffer` (crash report 2026-10-09, matched the rebuild). The patch
   builds `.Omarchy-Accent.new`, then `rename()` swaps it in (atomic on the same
   fs) with the old one moved aside, so the theme dir is never absent/partial.

**All 4 were re-verified as still missing upstream on 2026-10-13 at `97e001c`
("Release 1.1.0")** — upstream still runs `--hypr` only, still does
`shutil.rmtree` + `copytree`, and still has no fingerprint cache. Re-check
before assuming any of them landed:
```bash
cd ~/.config/omarchy/plugins/io.github.smoothpixels.cursor-acment
git show HEAD:recolor.py | grep -nE '"\-\-x11"|rmtree\(install_dir|fingerprint'
```

## After `omarchy plugin update` / `plugin add` (it overwrites recolor.py)
```bash
cp /mnt/media/Dots/cursor-accent/recolor.py \
   ~/.config/omarchy/plugins/io.github.smoothpixels.cursor-accent/recolor.py
python3 -m py_compile ~/.config/omarchy/plugins/io.github.smoothpixels.cursor-accent/recolor.py
bash ~/.config/omarchy/plugins/io.github.smoothpixels.cursor-accent/tools/install-cursor-hook.sh
```
The hooks in `~/.config/omarchy/hooks/{theme-set,post-boot}.d/cursor-accent.sh`
are user hooks, NOT touched by plugin updates — they keep calling recolor.py.
Re-run `install-cursor-hook.sh` only if the plugin's install path changes.

To force a rebuild (e.g. the `cursors/` set is missing or stale), delete the
cache file — it is NOT general cleanup, it only forces a full rebuild:
```bash
rm -f ~/.local/state/cursor-accent/fingerprint
bash ~/.config/omarchy/hooks/post-boot.d/cursor-accent.sh
```

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
