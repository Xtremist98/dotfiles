#!/usr/bin/env bash
# deploy-catpine.sh — install the full catpine GTK theme + repoint every GTK name
#                    (user gsettings, /etc/gtk-*, /root/.config/gtk-*, looknfeel.lua).
# Idempotent / re-runnable. Run as the USER (elevates sudo internally).
# Package: /mnt/media/Dots/gtk-themes/catpine-gtk-theme-1.0-1-any.pkg.tar.zst
set -euo pipefail

PKG=/mnt/media/Dots/gtk-themes/catpine-gtk/catpine-gtk-theme-1.0-1-any.pkg.tar.zst
[ -f "$PKG" ] || { echo "Missing package: $PKG"; exit 1; }

echo "[1/5] Installing catpine-gtk-theme (pacman -U) ..."
sudo pacman -U --noconfirm "$PKG"

echo "[2/5] Writing /etc/gtk-3.0 & /etc/gtk-4.0 settings.ini -> catpine ..."
for v in 3.0 4.0; do
  sudo install -dm755 /etc/gtk-$v
  sudo tee /etc/gtk-$v/settings.ini >/dev/null <<'EOF'
[Settings]
gtk-theme-name=catpine
gtk-application-prefer-dark-theme=true
gtk-icon-theme-name=Papirus-Dark
EOF
done

echo "[3/5] Creating /root/.config/gtk-3.0 & /root/.config/gtk-4.0 (root apps: gparted) ..."
for v in 3.0 4.0; do
  sudo install -dm755 /root/.config/gtk-$v
  sudo tee /root/.config/gtk-$v/settings.ini >/dev/null <<'EOF'
[Settings]
gtk-theme-name=catpine
gtk-application-prefer-dark-theme=true
EOF
done

echo "[4/5] Repointing looknfeel.lua:124 gtk-theme -> 'catpine' ..."
LF="$HOME/.config/hypr/looknfeel.lua"
if [ -f "$LF" ]; then
  sed -i "s/gtk-theme '[^']*'/gtk-theme 'catpine'/" "$LF"
  echo "  looknfeel.lua patched to catpine"
else
  echo "  WARN: $LF not found"
fi

echo "[5/5] Applying gsettings + reloading ..."
gsettings set org.gnome.desktop.interface gtk-theme 'catpine' 2>/dev/null || true
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
hyprctl reload >/dev/null 2>&1 || true

echo
echo "DONE. Log out + back in (or reboot) so root (pkexec) GTK apps pick up catpine."
echo "Verify:  gsettings get org.gnome.desktop.interface gtk-theme   -> 'catpine'"
echo "         ls /usr/share/themes/catpine"
