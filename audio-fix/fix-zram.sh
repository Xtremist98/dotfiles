#!/bin/bash
# Override Omarchy's zstd zram with lzo-rle, then recreate the device.
# .conf.d/ files override the main config; a file named LATER than 90-omarchy.conf wins.
set -e
echo "[1/4] Write override .conf.d (beats /usr/lib/.../90-omarchy.conf zstd)..."
mkdir -p /etc/systemd/zram-generator.conf.d
cat > /etc/systemd/zram-generator.conf.d/99-audio-lzo.conf <<'EOF'
# Override omarchy's zstd with lzo-rle: zstd does ~3:1 but costs far more CPU
# on this 0.8-2.1GHz Haswell, and every decompress happens in the faulting
# process - the exact stall that made the audio glitch under memory pressure.
# Revert: sudo rm /etc/systemd/zram-generator.conf.d/99-audio-lzo.conf && reboot
[zram0]
compression-algorithm = lzo-rle
EOF
echo "--- merged effective config is now (should show lzo-rle): ---"
cat /etc/systemd/zram-generator.conf.d/99-audio-lzo.conf

echo "[2/4] Tear down zram completely..."
swapoff /dev/zram0 2>/dev/null || true
zramctl -r /dev/zram0 2>/dev/null || echo 1 > /sys/block/zram0/reset
sleep 2
systemctl daemon-reload

echo "[3/4] Recreate zram from the merged config..."
systemctl restart systemd-zram-setup@zram0.service
sleep 3

echo "[4/4] Verify: active algorithm MUST be [lzo-rle] and swap on..."
zramctl