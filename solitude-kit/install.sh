#!/usr/bin/env bash
#
# Solitude Theme Kit installer
# Installs a fully self-contained solitude desktop. Everything needed
# (GTK theme, Kvantum style, qt6ct/qt5ct color schemes, vencord theme) is
# pre-rendered in this kit -- no external theming engine is required.
#
# The kit is fetched from the GitHub dotfiles repo if it is not already present
# next to this script. So you can run this straight from a curl'd copy:
#   bash <(curl -fsSL https://raw.githubusercontent.com/Xtremist98/dotfiles/main/solitude-kit/install.sh)
# or after cloning:  bash solitude-kit/install.sh
#
# Run AFTER selecting the solitude theme in Omarchy (for hyprland/bar theming).

set -euo pipefail

REPO="https://github.com/Xtremist98/dotfiles.git"
BRANCH="main"
KIT_SUBDIR="solitude-kit"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Use the kit next to this script if present; otherwise clone it from GitHub.
if [[ -d "$SCRIPT_DIR/solitude-gtk-theme" ]]; then
  KIT="$SCRIPT_DIR"
else
  echo "==> solitude-kit not found beside this script; cloning from GitHub ($REPO)..."
  TMP="$(mktemp -d)"
  git clone --depth 1 --filter=blob:none --sparse --branch "$BRANCH" "$REPO" "$TMP/dotfiles"
  git -C "$TMP/dotfiles" sparse-checkout set "$KIT_SUBDIR"
  KIT="$TMP/dotfiles/$KIT_SUBDIR"
  CLEANUP_TMP="$TMP"
fi

echo "==> Solitude Theme Kit installer"
echo "    kit: $KIT"

# 1. GTK theme (GTK2/3/4) — replaces adw-gtk3
GTK_PKG="$(ls "$KIT"/solitude-gtk-theme/solitude-gtk-theme-*.pkg.tar.gz 2>/dev/null | head -n1)"
if [[ -z "${GTK_PKG:-}" ]]; then
  echo "!! solitude-gtk-theme package not found; building from source..."
  ( cd "$KIT/solitude-gtk-theme" && PKGEXT='.pkg.tar.gz' makepkg -f )
  GTK_PKG="$(ls "$KIT"/solitude-gtk-theme/solitude-gtk-theme-*.pkg.tar.gz | head -n1)"
fi
echo "==> Installing solitude-gtk-theme (GTK2/3/4)..."
sudo pacman -U --needed "$GTK_PKG"

# 2. Kvantum solitude (hand-made style)
echo "==> Installing Kvantum solitude..."
mkdir -p "$HOME/.config/Kvantum/solitude"
cp -r "$KIT/Kvantum/solitude/." "$HOME/.config/Kvantum/solitude/"
printf '[General]\ntheme=solitude\n' > "$HOME/.config/Kvantum/kvantum.kvconfig"

# 3. qt6ct + qt5ct color schemes (pre-rendered)
echo "==> Installing qt6ct / qt5ct..."
mkdir -p "$HOME/.config/qt6ct" "$HOME/.config/qt5ct"
cp -r "$KIT/qt6ct/." "$HOME/.config/qt6ct/"
cp -r "$KIT/qt5ct/." "$HOME/.config/qt5ct/"

# 4. vencord (Discord) theme (pre-rendered)
echo "==> Installing vencord theme..."
mkdir -p "$HOME/.config/vesktop/themes"
cp "$KIT/vencord/vencord.theme.css" "$HOME/.config/vesktop/themes/vencord.theme.css"

# 5. GTK theme setting
echo "==> Setting GTK theme to solitude..."
gsettings set org.gnome.desktop.interface gtk-theme solitude
gsettings set org.gnome.desktop.interface color-scheme prefer-dark

# 6. Root theming for pkexec GUI apps (GParted, btrfs-assistant, ...)
echo "==> Installing root theming for pkexec apps..."
sudo mkdir -p /root/.config/gtk-3.0 /root/.config/qt6ct/colors /root/.config/qt5ct/colors /root/.config/Kvantum/solitude
sudo bash -c 'cat > /root/.config/gtk-3.0/settings.ini' <<'EOF'
[Settings]
gtk-theme-name=solitude
gtk-icon-theme-name=Papirus-Dark
gtk-color-scheme=prefer-dark
EOF
sudo cp -r "$KIT/Kvantum/solitude/." /root/.config/Kvantum/solitude/
sudo bash -c 'printf "[General]\ntheme=solitude\n" > /root/.config/Kvantum/kvantum.kvconfig'
sudo cp -r "$KIT/qt6ct/." /root/.config/qt6ct/
sudo cp -r "$KIT/qt5ct/." /root/.config/qt5ct/
# point root's qt6ct/qt5ct color scheme at /root, not /home/linuxer
sudo sed -i "s#/home/linuxer#/root#g" /root/.config/qt6ct/qt6ct.conf /root/.config/qt5ct/qt5ct.conf 2>/dev/null || true
if [[ -f "$HOME/.config/gtk-3.0/gtk.css" ]]; then
  sudo cp "$HOME/.config/gtk-3.0/gtk.css" /root/.config/gtk-3.0/gtk.css
fi

# clean up temp clone if we made one
[[ -n "${CLEANUP_TMP:-}" ]] && rm -rf "$CLEANUP_TMP"

echo
echo "==> Done. Solitude is installed:"
echo "   - GTK theme : solitude (GTK2/3/4)"
echo "   - Qt style  : Kvantum solitude"
echo "   - qt6ct/qt5ct color schemes : installed from kit"
echo "   - vencord theme : installed"
echo "   - root apps : themed via /root/.config"
echo "   Re-login (or restart the shell) so qt6ct + Kvantum fully apply."
