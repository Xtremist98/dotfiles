#!/usr/bin/env bash
# Apply catpine Qt theming to /root (root/pkexec Qt apps).
# Run: sudo bash /home/linuxer/apply-catpine-root.sh
# Idempotent. Mirrors what was synced to /mnt/media/Dots/root/.config/.
set -u

# 1. Root qt6ct + qt5ct color schemes (catpine = thpm output, md5 cb5e08ac...)
for ct in qt6ct qt5ct; do
  SRCDIR="/root/.config/$ct/colors"
  SRC="$SRCDIR/catpine.conf"
  install -Dm644 /home/linuxer/.config/qt6ct/colors/catpine.conf "$SRC"
  sed -i 's|color_scheme_path=.*|color_scheme_path=/root/.config/'"$ct"'/colors/catpine.conf|' "/root/.config/$ct/$ct.conf"
done

# 2. Root Kvantum theme name -> catpine (theme files live in /usr/share/Kvantum/catpine/)
KROOT="/root/.config/Kvantum/kvantum.kvconfig"
mkdir -p "$(dirname "$KROOT")"
printf '[General]\ntheme=catpine\n' > "$KROOT"

# 3. Verify
echo "=== root qt6ct/qt5ct schemes ==="
ls -l /root/.config/qt6ct/colors/catpine.conf /root/.config/qt5ct/colors/catpine.conf
echo "=== color_scheme_path ==="
grep color_scheme_path /root/.config/qt6ct/qt6ct.conf /root/.config/qt5ct/qt5ct.conf
echo "=== root kvantum.kvconfig ==="
cat /root/.config/Kvantum/kvantum.kvconfig
echo "=== system Kvantum catpine present? ==="
ls -l /usr/share/Kvantum/catpine/catpine.kvconfig /usr/share/Kvantum/catpine/catpine.svg
echo "=== md5 check (should be 0455c5b7 / 98456dfb) ==="
md5sum /usr/share/Kvantum/catpine/*.kvconfig /usr/share/Kvantum/catpine/*.svg