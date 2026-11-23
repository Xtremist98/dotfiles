#!/usr/bin/env bash
# Restore the custom Papercraft icon overlays on a fresh Omarchy install.
# Usage: bash /path/to/icon-backup/restore.sh
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TPL_DIR="$HOME/.config/omarchy/icons/papercraft"
APPS_DIR="$HOME/.local/share/applications"

mkdir -p "$TPL_DIR" "$APPS_DIR"

echo "==> Installing icon templates"
cp -v "$HERE"/templates/*.svg.tpl "$TPL_DIR"/

echo "==> Installing mpv launcher entry"
cp -v "$HERE/mpv-player.desktop" "$APPS_DIR"/mpv-player.desktop

echo "==> Selecting Papercraft and redrawing icons"
omarchy icons set papercraft
# The command above already redraws; this forces a fresh revision bump too.
omarchy-theme-set-icons

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$APPS_DIR" >/dev/null 2>&1 || true
fi

echo
echo "Done. Open the launcher with Super + Space."
echo "If icons look stale: omarchy restart shell"
