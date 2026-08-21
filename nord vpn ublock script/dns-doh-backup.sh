#!/usr/bin/env bash
#
# dns-doh-backup.sh
# Restores the DNS-over-HTTPS (doh) setup that bypasses the ZONG hotspot
# port-53 DNS hijack. Apply this on a fresh Omarchy install (as root).
#
# What it does:
#   1. Installs dnscrypt-proxy (if missing)
#   2. Writes /etc/dnscrypt-proxy/dnscrypt-proxy.toml  (Cloudflare DoH on 127.0.0.1:53)
#   3. Writes /etc/systemd/resolved.conf               (use 127.0.0.1 as DNS)
#   4. If the ZONG WiFi connection exists, sets its DNS to 127.0.0.1
#   5. Restarts dnscrypt-proxy + systemd-resolved
#
# The Cloudflare stamp uses the raw IP 1.1.1.1 as BOTH address and SNI,
# because the carrier intercepts by SNI too. Do NOT change it to a hostname.
#
set -u

STAMP='sdns://AgcAAAAAAAAABzEuMS4xLjEABzEuMS4xLjEKL2Rucy1xdWVyeQ'
ZONG_CON="ZONG MBB-E5573-0B68"

echo "==> Installing dnscrypt-proxy"
sudo pacman -S --noconfirm dnscrypt-proxy || sudo pacman -S --needed --noconfirm dnscrypt-proxy

echo "==> Writing /etc/dnscrypt-proxy/dnscrypt-proxy.toml"
sudo tee /etc/dnscrypt-proxy/dnscrypt-proxy.toml >/dev/null <<EOF
listen_addresses = ['127.0.0.1:53']
server_names = ['cf']
max_clients = 64
timeout = 5000
keepalive = 30
cert_refresh_delay = 240

# Cloudflare DoH, address AND SNI both set to 1.1.1.1 (raw IP).
# The ZONG hotspot hijacks DNS by hostname/SNI; a raw-IP connection passes.
[static.'cf']
stamp = '${STAMP}'
EOF

echo "==> Writing /etc/systemd/resolved.conf"
sudo tee /etc/systemd/resolved.conf >/dev/null <<EOF
[Resolve]
DNS=127.0.0.1
FallbackDNS=9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net 2620:fe::fe#dns.quad9.net 2620:fe::9#dns.quad9.net
EOF

if nmcli -t -f NAME con show 2>/dev/null | grep -qFx "${ZONG_CON}"; then
    echo "==> Configuring '${ZONG_CON}' DNS"
    sudo nmcli con mod "${ZONG_CON}" \
        ipv4.ignore-auto-dns yes ipv4.dns 127.0.0.1 \
        ipv6.ignore-auto-dns yes
    sudo nmcli con up "${ZONG_CON}" >/dev/null 2>&1 || true
else
    echo "==> '${ZONG_CON}' not found; skipping NM DNS override"
fi

echo "==> Restarting services"
sudo systemctl restart dnscrypt-proxy systemd-resolved

echo "==> Done. Verify: resolvectl status | grep '127.0.0.1'; curl https://google.com"
