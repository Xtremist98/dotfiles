# Solitude Theme Kit

A self-contained, reproducible **solitude** desktop theme for Omarchy.
Everything needed (GTK theme, Kvantum style, qt6ct/qt5ct color schemes, vencord
theme) is pre-rendered in this kit, so no external theming engine is required to
apply a full solitude desktop. This also eliminates the `adw-gtk3` AUR
dependency (replaced by `solitude-gtk-theme`).

## What's inside
- `solitude-gtk-theme/` — standalone GTK2/3/4 solitude theme (PKGBUILD + source
  + built `solitude-gtk-theme-*.pkg.tar.gz`). Replaces `adw-gtk3`.
- `Kvantum/solitude/` — hand-made Kvantum `solitude` Qt style.
- `qt6ct/`, `qt5ct/` — pre-rendered color schemes.
- `vencord/vencord.theme.css` — pre-rendered Discord theme.

## Fresh-install (kit is fetched from GitHub automatically)
After selecting the **solitude** theme in Omarchy (for hyprland/bar theming), run:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Xtremist98/dotfiles/main/solitude-kit/install.sh)
```

Or clone first:
```bash
git clone --depth 1 --filter=blob:none --sparse --branch main \
  https://github.com/Xtremist98/dotfiles.git /tmp/dots
cd /tmp/dots && git sparse-checkout set solitude-kit
bash solitude-kit/install.sh
```

`install.sh` will:
- install `solitude-gtk-theme` (GTK2/3/4) via `pacman -U`
- install the Kvantum `solitude` style and set it active
- install the pre-rendered qt6ct/qt5ct color schemes
- install the vencord theme
- set `gsettings` `gtk-theme=solitude` + `color-scheme=prefer-dark`
- copy qt6ct/Kvantum/gtk configs to `/root/.config` so root `pkexec` GUI
  apps (GParted, btrfs-assistant, …) are also themed

## Notes
- No `adw-gtk3` required for a solitude desktop.
- `QT_QPA_PLATFORMTHEME=qt6ct` must be set (Omarchy `envs.lua` already does this).
- libadwaita GTK4 apps (e.g. Nautilus) follow the system dark style; they pick up
  `solitude` the same way `adw-gtk3-dark` did (via `gtk-theme-name` + `prefer-dark`;
  `GTK_THEME=solitude` forces it).
- GTK2 support is best-effort (legacy).
