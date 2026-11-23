# Custom Papercraft icon overlays — backup & restore

## What this is

A set of 21 custom SVG templates that overlay Omarchy's built-in Papercraft
icon set, plus a fixed mpv launcher entry. Nothing under `/usr/share/omarchy/`
is modified — all changes live in `~/.config/` and `~/.local/`.

## Files

| Path | Purpose |
|---|---|
| `templates/*.svg.tpl` | The 21 hand-authored icon templates — **the only files you really need** |
| `mpv-player.desktop` | Copy of mpv's desktop entry under a name the launcher picks up |
| `theme-colors.toml.reference` | A copy of the Espressuccin palette used when these icons were made |
| `restore.sh` | Installs everything and triggers a redraw |

Strata is intentionally absent — the app was removed from the system.

## How the icon system works

1. `omarchy icons set papercraft` selects the icon set. The active set name is
   stored in `~/.local/state/omarchy/current/icons.name`.
2. `omarchy-theme-set-icons` merges the built-in set
   (`/usr/share/omarchy/icons/papercraft/`) with your overlay
   (`~/.config/omarchy/icons/papercraft/`). **Same filename = your version wins**,
   so each custom template replaces just that one built-in icon.
3. Each `.svg.tpl` is rendered by `omarchy-theme-set-templates --icons` using
   the active theme's palette. Tokens like `{{ accent }}`,
   `{{ icon_body }}`, `{{ icon_edge }}`, `{{ icon_mark }}` come from the
   theme's `colors.toml` (with derived icon roles from `omarchy-theme-icon-palette`).
   That is why the icons follow the theme's sage accent instead of a hardcoded teal.
4. The rendered SVGs are written to
   `~/.local/state/omarchy/current/icons/` and symlinked into
   `~/.local/share/icons/hicolor/scalable/apps/` — **both steps are automatic**.
5. `icons.revision` is bumped; the shell watches it and refreshes the launcher.

If a theme has no `colors.toml`, templates render nothing and the packaged icons
show instead.

## Restore on a fresh Omarchy

```bash
# 1. Copy this folder somewhere on the new machine, then:
bash /path/to/icon-backup/restore.sh

# 2. Open the launcher: Super + Space
#    If icons are stale: omarchy restart shell
```

That is all. The script copies the templates into place, selects Papercraft,
regenerates the SVGs, recreates the symlinks, and bumps `icons.revision`.

**Theme note:** the icons inherit whatever theme is active. To reproduce the
exact sage look, use the Espressuccin theme (or any theme whose `accent` is
`#A7C080`). With a different theme, the shapes stay the same but the accent
and neutral colors follow that theme — which is usually what you want.

## Adding or editing an icon later

1. Copy the built-in template as a starting point:
   `cp /usr/share/omarchy/icons/papercraft/<name>.svg.tpl ~/.config/omarchy/icons/papercraft/`
2. Edit it in `~/.config/omarchy/icons/papercraft/`.
3. Run `omarchy-theme-set-icons`, then reopen the launcher.
4. Remember to copy the changed template back into this backup folder.
