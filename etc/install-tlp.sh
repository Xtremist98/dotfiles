#!/bin/bash
# install-tlp.sh — Replace power-profiles-daemon with TLP + tlp-pd on Omarchy
# Use on a FRESH install so the Omarchy bar power panel keeps working.
# Run as user (elevates sudo internally). Idempotent / re-runnable.

set -euo pipefail

DOTS="${DOTS:-/mnt/media/Dots}"

echo "==> 1/5 Removing conflicting profile-daemon packages (ppd + omarchy-ppd)"
sudo systemctl stop power-profiles-daemon.service 2>/dev/null || true
sudo systemctl disable power-profiles-daemon.service 2>/dev/null || true
sudo pacman -Rns --noconfirm power-profiles-daemon 2>/dev/null || true
sudo pacman -Rns --noconfirm omarchy-power-profiles-daemon 2>/dev/null || true
sudo systemctl mask power-profiles-daemon.service 2>/dev/null || true
sudo kill $(pidof power-profiles-daemon) 2>/dev/null || true

echo "==> 2/5 Installing tlp + tlp-pd"
sudo pacman -S --noconfirm tlp tlp-pd

# Deploy tuned config
if [[ -f "$DOTS/etc/tlp.conf" ]]; then
  echo "==> 2b/5 Applying tuned /etc/tlp.conf"
  sudo cp "$DOTS/etc/tlp.conf" /etc/tlp.conf
fi

echo "==> 3/5 Enabling services"
sudo systemctl enable tlp.service
sudo systemctl enable --now tlp-pd.service

echo "==> 4/5 Symlinking powerprofilesctl -> tlpctl (panel needs the binary name)"
if command -v tlpctl >/dev/null 2>&1; then
  sudo ln -sf /usr/bin/tlpctl /usr/local/bin/powerprofilesctl
  echo "    symlink /usr/local/bin/powerprofilesctl -> /usr/bin/tlpctl OK"
else
  echo "    WARNING: tlpctl not found — check 'tlp' package installed (provides /usr/bin/tlpctl)"
  sudo rm -f /usr/local/bin/powerprofilesctl
fi

echo "==> 5/5 Applying TLP now"
sudo tlp start

echo ""
echo "Done. Verify:"
echo "  systemctl status tlp tlp-pd"
echo "  busctl --system list | grep -E 'PowerProfiles|UPower.PowerProfiles'"
echo "  powerprofilesctl list"
echo "  omarchy-powerprofiles-list --active-state"
echo "  tlp-stat -s  # AC / bat settings"
echo "  tlp-stat -p  # tuned limits active"
