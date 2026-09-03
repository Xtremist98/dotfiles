#!/bin/bash
# install-tlp.sh - Replace power-profiles-daemon with TLP + tlp-pd on Omarchy
# Use on a FRESH install so the Omarchy bar power panel keeps working
# while getting TLP's aggressive AC/battery power savings.
# Run as user (elevates sudo internally). Idempotent / re-runnable.

set -euo pipefail

DOTS="${DOTS:-/mnt/media/Dots}"

echo "==> 1/5 Removing power-profiles-daemon (conflicts with TLP)"
sudo systemctl stop power-profiles-daemon.service 2>/dev/null || true
sudo systemctl disable power-profiles-daemon.service 2>/dev/null || true
sudo pacman -Rns --noconfirm power-profiles-daemon 2>/dev/null || true
sudo systemctl mask power-profiles-daemon.service 2>/dev/null || true
sudo kill $(pidof power-profiles-daemon) 2>/dev/null || true

echo "==> 2/5 Installing tlp + tlp-pd"
sudo pacman -S --noconfirm tlp tlp-pd

# Deploy the tuned config (AC=max performance, BAT=max power saving)
if [[ -f "$DOTS/etc/tlp.conf" ]]; then
  echo "==> 2b/5 Applying tuned /etc/tlp.conf"
  sudo cp "$DOTS/etc/tlp.conf" /etc/tlp.conf
fi

echo "==> 3/5 Enabling services"
sudo systemctl enable tlp.service
sudo systemctl enable --now tlp-pd.service

echo "==> 4/5 Symlinking powerprofilesctl -> tlpctl (omarchy bar panel needs it)"
sudo ln -sf /usr/bin/tlpctl /usr/local/bin/powerprofilesctl

echo "==> 5/5 Applying TLP now"
sudo tlp start

echo ""
echo "Done. Verify:"
echo "  systemctl status tlp tlp-pd"
echo "  powerprofilesctl list"
echo "  tlp-stat -s"
echo "  tlp-stat -p   # AC: governor=performance / battery: powersave"
