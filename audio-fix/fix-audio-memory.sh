#!/bin/bash
# Audio-stability under memory pressure on the 3.3GB zram box. Idempotent. v3.
# Run: sudo bash /tmp/fix-audio-memory.sh
set -e

echo "[1/5] Raise the running user-manager memlock so pipewire can mlock its buffers..."
MGR=$(pgrep -u 1000 -x systemd | head -1)
if [ -n "$MGR" ]; then
    prlimit --pid "$MGR" --memlock=unlimited:unlimited
    prlimit --pid "$MGR" --memlock | tail -1
else
    echo "  WARNING: no user manager found; skipping"
fi

echo "[2/5] Durable pam_limits for all future logins..."
mkdir -p /etc/security/limits.d
printf 'linuxer soft memlock unlimited\nlinuxer hard memlock unlimited\n' > /etc/security/limits.d/99-audio-memlock.conf
systemctl set-property user@.service LimitMEMLOCK=infinity 2>/dev/null || echo "  (user@.service property applies at next login)"

echo "[3/5] zram-generator: use lzo-rle instead of zstd (much lower CPU per swap page)..."
ZGC=/etc/systemd/zram-generator.conf
if [ ! -f "$ZGC" ]; then printf '[zram0]\n' > "$ZGC"; fi
grep -q "compression-algorithm" "$ZGC" || printf 'compression-algorithm = lzo-rle\n' >> "$ZGC"
systemctl daemon-reload
swapoff /dev/zram0 2>/dev/null || true
systemctl restart systemd-zram-setup@zram0.service
zramctl | head -2

echo "[4/5] swappiness 150 -> 60 (stop eager anon rotation that forces constant zstd spikes)..."
printf 'vm.swappiness=60\n' > /etc/sysctl.d/100-audio-tuning.conf
sysctl -w vm.swappiness=60

echo "[5/5] Remove the now-pointless file capability (it is masked by the unit's NNP anyway)..."
setcap -r /usr/bin/pipewire 2>/dev/null || true

echo
echo "DONE. Tell the assistant to restart the audio stack and verify."
echo "Expected: pipewire memlock limit = infinity";