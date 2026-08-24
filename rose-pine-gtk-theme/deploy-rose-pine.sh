#!/usr/bin/env bash
# deploy-rose-pine.sh - one-shot rose-pine-dark deployment for Omarchy.
#
# What it does (idempotent, re-runnable):
#   1. Installs the FULL rose-pine-dark GTK theme to /usr/share/themes/rose-pine-dark
#      (this single directory fixes both user AND root GTK3/GTK4 apps; neither
#      depends on the missing Adwaita-dark GTK3 theme anymore).
#   2. Installs the Kvantum theme to /usr/share/Kvantum/rose-pine-dark.
#   3. Writes the qt6ct color scheme for the user (root copy handled by kvswitch-root).
#   4. Drops the 95-rose-pine-gtk hook so `omarchy theme set` uses the full theme.
#   5. Patches /usr/bin/omarchy-theme-set-gnome so `thpm run`/`reconcile` don't
#      reset to the broken Adwaita-dark.
#   6. Installs ~/kvswitch-root and applies the root theme.
#   7. Applies the theme: `omarchy theme set rose-pine-dark` + root switch.
#
# Usage (as your normal user; it calls sudo internally):
#   DOTS=/mnt/media/Dots bash /mnt/media/Dots/rose-pine-gtk-theme/deploy-rose-pine.sh
set -euo pipefail

DOTS="${DOTS:-/mnt/media/Dots}"
GTK_SRC="$DOTS/rose-pine-gtk-theme/rose-pine-dark"
KV_SRC="$DOTS/kvantum/rose-pine-dark"
THEME="rose-pine-dark"

echo "==> Deploying $THEME from DOTS=$DOTS"

if [[ ! -d "$GTK_SRC" ]]; then
  echo "ERROR: GTK theme source not found: $GTK_SRC" >&2; exit 1
fi
if [[ ! -d "$KV_SRC" ]]; then
  echo "ERROR: Kvantum source not found: $KV_SRC" >&2; exit 1
fi

# ---------------------------------------------------------------------------
# 1. Full GTK theme (user + root both read /usr/share/themes/rose-pine-dark)
# ---------------------------------------------------------------------------
echo "==> Installing GTK theme -> /usr/share/themes/$THEME"
sudo rm -rf "/usr/share/themes/$THEME"
sudo mkdir -p "/usr/share/themes/$THEME"
sudo cp -a "$GTK_SRC/." "/usr/share/themes/$THEME/"
# remove any stale user-level copy that would shadow the system one
rm -rf "$HOME/.local/share/themes/$THEME"

# ---------------------------------------------------------------------------
# 2. Kvantum (read by user + root)
# ---------------------------------------------------------------------------
echo "==> Installing Kvantum -> /usr/share/Kvantum/$THEME"
sudo rm -rf "/usr/share/Kvantum/$THEME"
sudo mkdir -p "/usr/share/Kvantum/$THEME"
sudo cp -a "$KV_SRC/." "/usr/share/Kvantum/$THEME/"

# ---------------------------------------------------------------------------
# 3. qt6ct color scheme (user copy; kvswitch-root copies it to root)
# ---------------------------------------------------------------------------
echo "==> Writing qt6ct scheme (user)"
mkdir -p "$HOME/.config/qt6ct/colors"
cat > "$HOME/.config/qt6ct/colors/rosepine-dark.conf" <<'QT6CT_EOF'
[ColorScheme]
active_colors=#e0def4, #26233a, #312f45, #6e6a86, #1f1d2e, #e0def4, #e0def4, #e0def4, #e0def4, #191724, #26233a, #6e6a86, #eb6f92, #191724, #9ccfd8, #c4a7e7, #1f1d2e, #e0def4, #191724, #e0def4, #6e6a86
disabled_colors=#6e6a86, #26233a, #1f1d2e, #6e6a86, #1f1d2e, #6e6a86, #6e6a86, #6e6a86, #6e6a86, #191724, #26233a, #6e6a86, #6e6a86, #191724, #6e6a86, #6e6a86, #1f1d2e, #6e6a86, #191724, #6e6a86, #6e6a86
inactive_colors=#e0def4, #26233a, #312f45, #6e6a86, #1f1d2e, #e0def4, #e0def4, #e0def4, #e0def4, #191724, #26233a, #6e6a86, #eb6f92, #191724, #9ccfd8, #c4a7e7, #1f1d2e, #e0def4, #191724, #e0def4, #6e6a86
QT6CT_EOF

# ---------------------------------------------------------------------------
# 4. 95-rose-pine-gtk hook (user-level; survives omarchy updates)
# ---------------------------------------------------------------------------
echo "==> Installing 95-rose-pine-gtk hook"
HOOK_DIR="$HOME/.config/omarchy/hooks/theme-set.d"
mkdir -p "$HOOK_DIR"
cat > "$HOOK_DIR/95-rose-pine-gtk" <<'HOOK_EOF'
#!/usr/bin/env bash
# rose-pine-dark: force the FULL GTK theme (not thpm's Adwaita-dark base).
#
# Omarchy/thpm set gtk-theme="Adwaita-dark" for dark mode, but no Adwaita-dark
# GTK3 theme is installed on this machine, so GTK3 apps (xed, pavucontrol) and
# Chromium (reads GTK3) fall back to the light default -> white/brown toolbars.
# The full /usr/share/themes/rose-pine-dark theme is correct (root apps prove
# it), so we re-assert it here, running AFTER the 90-thpm hook.
#
# Conditional on the active theme so it never interferes with other themes.

NAME_FILE="$HOME/.local/state/omarchy/current/theme.name"
THEME="$(cat "$NAME_FILE" 2>/dev/null | tr -d '[:space:]')"

if [[ "$THEME" == "rose-pine-dark" ]]; then
  gsettings set org.gnome.desktop.interface gtk-theme 'rose-pine-dark' 2>/dev/null
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null
fi
HOOK_EOF
chmod +x "$HOOK_DIR/95-rose-pine-gtk"

# ---------------------------------------------------------------------------
# 5. Patch /usr/bin/omarchy-theme-set-gnome (sudo)
# ---------------------------------------------------------------------------
echo "==> Patching /usr/bin/omarchy-theme-set-gnome"
sudo cp -n /usr/bin/omarchy-theme-set-gnome /usr/bin/omarchy-theme-set-gnome.orig 2>/dev/null || true
sudo tee /usr/bin/omarchy-theme-set-gnome >/dev/null <<'SETTER_EOF'
#!/bin/bash

# omarchy:summary=Apply the current theme to GNOME color mode and icon settings
# omarchy:hidden=true

# gsettings needs a user DBus session. During ISO installs this command can be
# reached from arch-chroot while applying the initial Omarchy theme; defer until
# the user has a real session instead of emitting dconf warnings.
if [[ -z ${DBUS_SESSION_BUS_ADDRESS:-} ]]; then
  exit 0
fi

THEME_DIR=$HOME/.local/state/omarchy/current/theme
COLORS_FILE="$THEME_DIR/colors.toml"
THEME_NAME="$(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null | tr -d '[:space:]')"

# omarchy-theme-color resolves mode from colors.toml (`mode = "light"`), a
# legacy light.mode marker beside it, or background luminance for user themes.
mode=$(omarchy-theme-color --file "$COLORS_FILE" mode)

if [[ $mode == "light" ]]; then
  gsettings set org.gnome.desktop.interface color-scheme "prefer-light"
  GTK_THEME="Adwaita"
else
  gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
  GTK_THEME="Adwaita-dark"
fi

# Use the theme's own shipped GTK theme when one exists (e.g. rose-pine-dark,
# solitude). On this machine Adwaita-dark has no GTK3 theme installed, so the
# fallback above breaks GTK3 apps (xed, pavucontrol) and Chromium (reads GTK3);
# the full theme directory is correct instead.
if [[ -n "$THEME_NAME" && -d "/usr/share/themes/$THEME_NAME" ]]; then
  GTK_THEME="$THEME_NAME"
fi

gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME"

# Change gnome icon theme color
GNOME_ICONS_THEME=$HOME/.local/state/omarchy/current/theme/icons.theme
if [[ -f $GNOME_ICONS_THEME ]]; then
  gsettings set org.gnome.desktop.interface icon-theme "$(<$GNOME_ICONS_THEME)"
else
  gsettings set org.gnome.desktop.interface icon-theme "Yaru-blue"
fi
SETTER_EOF
sudo chmod 755 /usr/bin/omarchy-theme-set-gnome

# ---------------------------------------------------------------------------
# 6. Install ~/kvswitch-root
# ---------------------------------------------------------------------------
echo "==> Installing ~/kvswitch-root"
cat > "$HOME/kvswitch-root" <<'KSW_EOF'
#!/usr/bin/env bash
# kvswitch-root - switch ROOT Qt/Kvantum + GTK theme (gparted, btrfs-assistant).
# Run with sudo:  sudo bash /home/linuxer/kvswitch-root {rose-pine-dark|solitude}
set -euo pipefail

THEME="${1:-}"
# Detect the calling user's home (kvswitch-root runs as root via sudo)
USER_HOME="$(getent passwd "${SUDO_USER:-$(logname 2>/dev/null)}" 2>/dev/null | cut -d: -f6)"
USER_HOME="${USER_HOME:-/home/linuxer}"
case "$THEME" in
  rose-pine-dark)
    KV="rose-pine-dark"
    QT_SCHEME="/root/.config/qt6ct/colors/rosepine-dark.conf"
    GTK4_NET=':root {
  --window-bg-color: #191724;
  --view-bg-color: #191724;
  --headerbar-bg-color: #191724;
  --sidebar-bg-color: #191724;
  --secondary-sidebar-bg-color: #191724;
  --dialog-bg-color: #191724;
  --popover-bg-color: #191724;
  --sidebar-backdrop-color: #191724;
  --secondary-sidebar-backdrop-color: #191724;
  --headerbar-backdrop-color: #191724;
}'
    ;;
  solitude)
    KV="solitude"
    QT_SCHEME="/root/.config/qt6ct/colors/solitude.conf"
    GTK4_NET=""
    ;;
  *)
    echo "Usage: sudo bash $0 {rose-pine-dark|solitude}" >&2
    exit 1
    ;;
esac

# Root Qt/Kvantum (btrfs-assistant). Create the configs if missing so the
# script never aborts on a fresh machine (set -e would otherwise kill it).
mkdir -p /root/.config/Kvantum /root/.config/qt6ct/colors
if [ -f /root/.config/Kvantum/kvantum.kvconfig ]; then
  sed -i "s/^theme=.*/theme=$KV/" /root/.config/Kvantum/kvantum.kvconfig
else
  printf '[General]\ntheme=%s\n' "$KV" > /root/.config/Kvantum/kvantum.kvconfig
fi
if [ -f /root/.config/qt6ct/qt6ct.conf ]; then
  sed -i "s|^color_scheme_path=.*|color_scheme_path=$QT_SCHEME|" /root/.config/qt6ct/qt6ct.conf
else
  printf '[Appearance]\ncolor_scheme_path=%s\n' "$QT_SCHEME" > /root/.config/qt6ct/qt6ct.conf
fi
# Ensure the root color scheme file exists (copy from the user session if needed)
if [ ! -f "$QT_SCHEME" ] && [ -f "$USER_HOME/.config/qt6ct/colors/$(basename "$QT_SCHEME")" ]; then
  cp "$USER_HOME/.config/qt6ct/colors/$(basename "$QT_SCHEME")" "$QT_SCHEME"
fi

# gparted's launcher hardcodes GTK_THEME (written by the solitude kit).
# GTK_THEME env overrides settings.ini, so it must be switched too.
if [ -f /usr/bin/gparted ]; then
  sed -i "s/^export GTK_THEME=.*/export GTK_THEME=$KV/" /usr/bin/gparted
fi

# Root GTK (gparted reads the theme from /usr/share; the flat look is baked there)
ROOT_INI="/root/.config/gtk-3.0/settings.ini"
mkdir -p "$(dirname "$ROOT_INI")"
if ! grep -qi '^\s*\[Settings\]' "$ROOT_INI" 2>/dev/null; then
  printf '[Settings]\n' >> "$ROOT_INI"
fi
if grep -qi '^\s*gtk-theme-name' "$ROOT_INI"; then
  sed -i "s/^\s*gtk-theme-name\s*=.*/gtk-theme-name=$KV/" "$ROOT_INI"
else
  printf 'gtk-theme-name=%s\n' "$KV" >> "$ROOT_INI"
fi
if [ -n "$GTK4_NET" ]; then
  printf '%s\n' "$GTK4_NET" > /root/.config/gtk-4.0/gtk.css
else
  rm -f /root/.config/gtk-3.0/gtk.css /root/.config/gtk-4.0/gtk.css
fi

echo "ROOT session -> $KV (restart root Qt/GTK apps to apply)"
KSW_EOF
chmod +x "$HOME/kvswitch-root"

# ---------------------------------------------------------------------------
# 7. Apply
# ---------------------------------------------------------------------------
echo "==> Applying theme (user)"
omarchy theme set "$THEME"

echo "==> Applying root theme"
sudo bash "$HOME/kvswitch-root" "$THEME"

echo "==> DONE. Restart xed / pavucontrol / Chromium / Brave / gparted to see rose-pine."
