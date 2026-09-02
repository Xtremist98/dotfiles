#!/bin/bash
# stremio-service v0.1.22 manual installer (payload extracted from official .deb)
# Usage: cd /path/to/stremio-service && sudo bash install.sh
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"

echo "==> Payload: $SRC/usr"

if pacman -Q stremio-service-bin >/dev/null 2>&1; then
    echo "==> Removing old stremio-service-bin package..."
    pacman -R --noconfirm stremio-service-bin
fi

echo "==> Installing stremio-service 0.1.22 files (tar preserves modes)..."
(cd "$SRC/usr" && tar -cf - .) | (cd / && tar -xf -)

echo "==> Refreshing desktop databases..."
update-desktop-database /usr/share/applications 2>/dev/null || true
gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true

echo "==> Done. Version check:"
/usr/bin/stremio-service --version