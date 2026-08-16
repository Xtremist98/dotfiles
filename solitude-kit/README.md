# Solitude Theme Kit

A self-contained, reproducible **solitude** desktop theme for Omarchy.
Everything needed (GTK theme, Kvantum style, qt6ct/qt5ct color schemes, a KDE
color scheme, vencord theme) is pre-rendered in this kit, so no external
theming engine is required to apply a full solitude desktop. The GTK theme
(`solitude-gtk-theme`) replaces `adw-gtk3`; the kit installs it but no longer
force-removes `adw-gtk-theme-git` (both can coexist).

## What's inside
- `solitude-gtk-theme/` — standalone GTK2/3/4 solitude theme (PKGBUILD + source
  + built `solitude-gtk-theme-*.pkg.tar.gz`). Replaces `adw-gtk3`.
- `Kvantum/solitude/` — hand-made Kvantum `solitude` Qt style.
- `qt6ct/`, `qt5ct/` — pre-rendered color schemes.
- `kde/Solitude.colors` — a KDE color scheme. qt6ct only sets the Qt widget
  style + QPalette; it does NOT populate KDE's `KColorScheme`, which KDE apps
  (e.g. Dolphin's "Acting as administrator" banner) read. Without this the
  banner falls back to white, so the kit installs it into kdeglobals.
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
- install the KDE `Solitude` color scheme into `kdeglobals` (fixes Dolphin's
  admin banner / KColorScheme roles)
- install the vencord theme
- set `gsettings` `gtk-theme=solitude` + `color-scheme=prefer-dark`
- copy qt6ct/Kvantum/gtk configs to `/root/.config` so root `pkexec` GUI apps
  (GParted, btrfs-assistant, …) are themed via `gtk-3.0/settings.ini`. NOTE: we
  do NOT copy the user's `kdeglobals` to `/root` nor force the Qt platform theme
  globally via `/etc/xdg/qt*.conf` — either loads qt6ct/Kvantum into the root
  `kio-admin-helper` and crashes Dolphin's "Open as Administrator" (shows
  "unknown error, loading canceled").

## Notes
- No `adw-gtk3` required for a solitude desktop.
- `QT_QPA_PLATFORMTHEME=qt6ct` must be set (Omarchy `envs.lua` already does this).
- libadwaita GTK4 apps (e.g. Nautilus) follow the system dark style; they pick up
  `solitude` the same way `adw-gtk3-dark` did (via `gtk-theme-name` + `prefer-dark`;
  `GTK_THEME=solitude` forces it).
- GTK2 support is best-effort (legacy).
