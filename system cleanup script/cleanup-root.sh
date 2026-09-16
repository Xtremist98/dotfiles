#!/usr/bin/env bash
# Root-required cleanup: journal logs + coredumps + pacman cache
# Run as: sudo bash ~/cleanup-root.sh

echo "=== systemd journal vacuum (target 100M) ==="
journalctl --vacuum-size=100M
journalctl --disk-usage

echo
echo "=== coredumps (keep 0) ==="
journalctl --vacuum-time=1d
coredumpctl list 2>/dev/null | tail -3
coredumpctl --vacuum=0 2>/dev/null || rm -rf /var/lib/systemd/coredump/
du -sh /var/lib/systemd/coredump 2>/dev/null

echo
echo "=== pacman cache cleanup ==="
paccache -rk1 2>/dev/null || true
pacman -Sc --noconfirm 2>/dev/null | tail -2

echo
echo "=== btrfs balance (return freed extents) ==="
sync
btrfs balance start -musage=20 -dusage=30 / 2>&1 | head -3

echo
echo "=== dnscrypt + resolved tmp ==="
rm -rf /var/tmp/* 2>/dev/null
rm -f /etc/systemd/resolved.conf.pacnew /etc/pacman.d/mirrorlist.pacnew 2>/dev/null

echo
echo "=== Done. Disk usage: ==="
df -h /home | tail -1