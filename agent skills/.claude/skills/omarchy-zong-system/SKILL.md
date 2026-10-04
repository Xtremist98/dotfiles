---
name: omarchy-zong-system
description: Omarchy-on-ZONG system maintenance — where DNS is configured, the dnscrypt-DoH lock, how to safely handle .pacnew files after an update, and the rule to keep Omarchy's Cloudflare-backed mirror. Use when an Omarchy update drops a .pacnew, when DNS or package updates break after an update, or when asked about resolved.conf / mirrorlist / NetworkManager DNS on this ZONG-connected machine.
---

# Omarchy system on ZONG — DNS, mirror & .pacnew

## Machine context
- This is an **Omarchy** (Arch/Hyprland) machine used on the **ZONG** carrier (Pakistan MiFi hotspot). ZONG runs SNI/DPI filtering: it hijacks plaintext port-53 DNS (returns bogus IPs) and resets TLS to some server hostnames, but allows Cloudflare-fronted HTTPS (ECH) and direct egress. The VPN/DNS-hijack deep dive lives in the `nordvpn-zong-nordgui` skill.
- The machine deliberately uses **dnscrypt-proxy on 127.0.0.1:53** as the system resolver to bypass the port-53 hijack. systemd-resolved points at `127.0.0.1`; Cloudflare/DoT defaults are NOT used because ZONG intercepts them.

## Where Omarchy stores DNS (file map)
- **`/etc/systemd/resolved.conf`** — main resolver. Should contain `DNS=127.0.0.1` (+ `FallbackDNS=` Quad9). This is what `omarchy dns` writes.
- **`/etc/NetworkManager/conf.d/20-omarchy-dns.conf`** — NM global DNS drop-in, `servers=127.0.0.1` (header: "Managed by omarchy-dns"). Remove it / run `omarchy dns DHCP` to revert to DHCP DNS.
- **`/etc/systemd/network/20-{ethernet,wlan,wwan}.network`** — each has `UseDNS=no` under `[DHCPv4]` and `[IPv6AcceptRA]` so DHCP can't override the chosen DNS (Omarchy's "lock" when you pick Cloudflare/Custom).
- Command: `omarchy dns` (`/usr/bin/omarchy`); GUI: `Setup > Network > DNS`.
- `/etc/resolv.conf` is a symlink → `../run/systemd/resolve/stub-resolv.conf` (normal).

## The .pacnew rule (critical on ZONG)
After an `omarchy update` / `pacman -Syu`, pacman may drop `.pacnew` files for configs you've modified. **Do NOT merge these two — delete them:**
- **`/etc/systemd/resolved.conf.pacnew`** — stock systemd template with every DNS line commented out. Merging would WIPE `DNS=127.0.0.1` → lose dnscrypt → ZONG hijack. **Delete it; keep your `resolved.conf`.**
- **`/etc/pacman.d/mirrorlist.pacnew`** — stock Arch list with all `Server=` lines commented. Merging would leave `pacman` with NO active mirror → updates break. **Delete it; keep your current mirrorlist.**
- Deleting a `.pacnew` never touches your real config file — it only removes the unused default leftover.

Safe cleanup:
```bash
sudo rm /etc/systemd/resolved.conf.pacnew /etc/pacman.d/mirrorlist.pacnew
```
Other `.pacnew` (`wireless-regdom`, `sddm`, `locale.gen`, `sysctl.d/90-omarchy-file-watchers`, `tpm2-tss`) are not network-critical; handle separately with `sudo pacdiff` if desired. `wireless-regdom.pacnew` is comments-only → safe to ignore.

Verify after:
```bash
grep '^DNS' /etc/systemd/resolved.conf     # DNS=127.0.0.1
grep '^Server' /etc/pacman.d/mirrorlist     # mirror.omarchy.org
```

## The mirror rule (never adopt stock mirrorlist on ZONG)
- The active mirror is **`Server = https://mirror.omarchy.org/$repo/os/$arch`** (Omarchy's own Cloudflare-backed repo/mirror). It works on ZONG (Cloudflare-fronted HTTPS) and is what delivered updates.
- The stock `mirrorlist.pacnew` has every server commented → adopting it kills `pacman`. **Always keep `mirror.omarchy.org`; never replace it with the stock list.** If you add mirrors, append them; don't overwrite the Omarchy line.
- This is separate from DNS (mirror = HTTPS package delivery, not name resolution), but both must stay "Omarchy/Cloudflare-backed, not stock" on ZONG.

## Gotchas
- If DNS breaks after an update: re-check `resolvectl status` and the three files above; an `omarchy dns DHCP`/`Cloudflare` command (or a bad `.pacnew` merge) is the usual cause. Re-run `omarchy dns Custom 127.0.0.1` if needed.
- Never let Omarchy's DNS selector sit on **Cloudflare** on this machine — `1.1.1.1#cloudflare-dns.com` (opportunistic DoT) is hijacked by ZONG. Keep **Custom = 127.0.0.1**.
