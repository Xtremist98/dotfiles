# Solitude Theme Kit

A self-contained, reproducible **solitude** desktop theme for Omarchy.
Eliminates the `adw-gtk3` AUR dependency. `thpm` (actively developed:
https://github.com/oldjobobo/thpm) stays required — it re-renders the qt6ct
color scheme + app themes (cava, Discord/vencord, firefox, fish, fzf,
qutebrowser, spicetify, superfile, zen, heroic, nwg-dock, hermes) live from
the solitude palette whenever the Omarchy theme is set to solitude.

## What's inside
- `solitude-gtk-theme/` — standalone GTK2/3/4 solitude theme (PKGBUILD + source
  + built `solitude-gtk-theme-*.pkg.tar.gz`). Replaces `adw-gtk3`.
- `Kvantum/solitude/` — hand-made Kvantum `solitude` Qt style (`thpm` does NOT
  generate this, so it lives here).

## Fresh-install steps
1. Install `thpm` (AUR): `yay -S thpm`
2. In Omarchy, select the **solitude** theme (this makes `thpm` render the qt6ct
   color scheme + all app themes).
3. Run the installer:
   ```bash
   ~/Dropbox/dotfiles/solitude-kit/install.sh
   ```
   It will:
   - install `solitude-gtk-theme` (GTK2/3/4) via `pacman -U`
   - ensure `thpm` is present
   - install the Kvantum `solitude` style and set it active
   - set `gsettings` `gtk-theme=solitude` + `color-scheme=prefer-dark`
   - copy qt6ct / Kvantum / gtk configs to `/root/.config` so root `pkexec`
     GUI apps (GParted, btrfs-assistant, …) are also themed

## Notes
- No `adw-gtk3` needed anymore.
- `QT_QPA_PLATFORMTHEME=qt6ct` must be set (Omarchy `envs.lua` already does this).
- libadwaita GTK4 apps (e.g. Nautilus) follow the system dark style; they pick up
  `solitude` the same way `adw-gtk3-dark` did (via `gtk-theme-name` + `prefer-dark`;
  `GTK_THEME=solitude` forces it).
- GTK2 support is best-effort (legacy).
