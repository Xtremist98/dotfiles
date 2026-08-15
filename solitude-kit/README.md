# Solitude Theme Kit

A self-contained, reproducible **solitude** desktop theme for Omarchy.
**`thpm` is OPTIONAL** — the qt6ct/qt5ct color schemes and the vencord (Discord)
theme are pre-rendered in this kit, so install needs no `thpm`. This also
eliminates the `adw-gtk3` AUR dependency (replaced by `solitude-gtk-theme`).

You can still install `thpm` (https://github.com/oldjobobo/thpm) later if you
want it to live-render themes for other apps (cava, firefox, fish, fzf,
qutebrowser, spicetify, superfile, zen, heroic, nwg-dock, hermes), but it is
not required for the desktop to be solitude.

## What's inside
- `solitude-gtk-theme/` — standalone GTK2/3/4 solitude theme (PKGBUILD + source
  + built `solitude-gtk-theme-*.pkg.tar.gz`). Replaces `adw-gtk3`.
- `Kvantum/solitude/` — hand-made Kvantum `solitude` Qt style (`thpm` does NOT
  generate this, so it lives here).
- `qt6ct/`, `qt5ct/` — pre-rendered color schemes (no `thpm` needed).
- `vencord/vencord.theme.css` — pre-rendered Discord theme (no `thpm` needed).

## Fresh-install steps
1. In Omarchy, select the **solitude** theme (for hyprland/bar theming).
2. Run the installer:
   ```bash
   ~/Dropbox/dotfiles/solitude-kit/install.sh
   ```
   It will:
   - install `solitude-gtk-theme` (GTK2/3/4) via `pacman -U`
   - install the Kvantum `solitude` style and set it active
   - install the pre-rendered qt6ct/qt5ct color schemes
   - install the vencord theme
   - set `gsettings` `gtk-theme=solitude` + `color-scheme=prefer-dark`
   - copy qt6ct/Kvantum/gtk configs to `/root/.config` so root `pkexec` GUI
     apps (GParted, btrfs-assistant, …) are also themed

## Notes
- No `adw-gtk3` and no `thpm` required for a solitude desktop.
- `QT_QPA_PLATFORMTHEME=qt6ct` must be set (Omarchy `envs.lua` already does this).
- libadwaita GTK4 apps (e.g. Nautilus) follow the system dark style; they pick up
  `solitude` the same way `adw-gtk3-dark` did (via `gtk-theme-name` + `prefer-dark`;
  `GTK_THEME=solitude` forces it).
- GTK2 support is best-effort (legacy).
