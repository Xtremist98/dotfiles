# Omarchy Rescue — briefing for THIS machine

Paste this to the rescue agent (or read it out) before it starts diagnosing.
The stock rescue `AGENTS.md` makes at least two assumptions that are WRONG here.

## Hardware / firmware
- HP EliteBook 840 G1. UEFI boot, **Secure Boot disabled** (Limine, hash_mismatch_panic: no).
- 3.3 GiB RAM. Was on AC at time of writing; TLP clamps to **0.8 GHz on battery** —
  keep it on AC or the agent will crawl.

## Disks — CRITICAL DEVIATION FROM RESCUE DOCS
The rescue `AGENTS.md` says the LUKS container opens as `/dev/mapper/omarchy_root`.
**On this machine it is `/dev/mapper/root`.** Do not conclude "the disk isn't found"
if `omarchy_root` is absent — look for `root`.

```
sda    238.5G   internal SSD (2.5" SATA)
├─sda1     2G   vfat, label "boot"          -> mounted at /boot on the installed system (ESP)
├─sda2    50G   crypto_LUKS, label "Root"  -> /dev/mapper/root -> btrfs
│ └─root  50G                              -> mounted at /home  (i.e. Btrfs subvolume @home)
└─sda3 186.5G  ext4, label "My Space"      -> mounted at /mnt/media
zram0   3.3G   swap only
```

- **No swap partition exists.** It was merged into `sda3` on 2026-09-27; swap is `zram0` only.
- Btrfs subvolumes: `@` (=/), `@home` (=/home), `@log` (=/var/log), `@pkg` (=/var/cache/pacman/pkg).
  Root filesystem is mounted at `/` from `@`; `/home` is a **separate subvolume**, which is why
  `lsblk` shows `sda2`/`root` appearing to hang off `/home`.
- `omarchy-rescue-mount` reads the installed `/etc/fstab`, so it should handle all of this
  itself. If it errors, the expected mapping is above.
- `sda3` (My Space, ~147 GB of the user's data) has **no backup** and the user has explicitly
  decided not to create one. Treat it as read-mostly. Never mkfs/wipe/dd onto `sda`.

## Network — ZONG hotspot hijacks port 53
- Carrier is a ZONG `MBB-E5573-0B68` MiFi hotspot, **2.4 GHz only**.
- It hijacks **all port-53 DNS**, returning bogus `0.4.x.x` / `192.0.0.x`. Raw HTTPS/443 egress is fine.
- On the installed system this is solved by `dnscrypt-proxy` on `127.0.0.1:53` +
  NetworkManager pinned to `127.0.0.1` (`ipv4.ignore-auto-dns yes`). `/etc/systemd/resolved.conf`
  has `DNS=127.0.0.1`.
- **Rescue has none of that** — it uses the ISO's own resolver. So `websearch`/`webfetch`/`pacman -S`
  may fail in rescue even though the agent chat itself works. Quick fix:
  `printf 'nameserver 1.1.1.1\n' > /etc/resolv.conf`
- Wi-Fi tool in rescue is **`impala`**. Ethernet needs no command.

## Boot chain
- Limine with systemd-stub UKIs at `/boot/EFI/Linux/omarchy_linux.efi` (stock `linux`) and
  `omarchy_linux-omarchy.efi`. `default_entry: 2` = stock `linux`.
- `/boot/limine.conf` carries **BLAKE2b-512** (64-byte / 128 hex char) verification hashes —
  verify with `b2sum -l 512`, NOT `sha256sum`, and NOT `grep -oE '#[0-9a-f]{64}'`.
- `limine-mkinitcpio` is deterministic: a re-run prints **no** `Copied:` lines. That is success.

## The big one: read the installed ~/AGENTS.md first
`/home/linuxer/AGENTS.md` is a very long, hard-won record of ~40 custom fixes on this box:
Plymouth/UKI splash chain, espressuccin theme + the whole thpm copy chain, PipeWire/HeSuVi/soundcore
EQ chain (SBC-XQ locked, ~546 kbps, memlock + `vm.swappiness=60` + `zram lzo-rle`),
Dolphin/Kvantum quirks, world clock pinned off, dnscrypt/ZONG, sda3 merge, and the
`omarchy-bar put` wipes-`disabledPlugins` gotcha.

**Mount the disk and read it before proposing changes:**
```bash
omarchy-rescue-mount            # type the LUKS passphrase yourself
cat /mnt/home/linuxer/AGENTS.md  # or: less
```
Then start the agent from inside the chroot so it loads that context automatically:
```bash
arch-chroot /mnt
opencode
```

## House rules that apply here
- Diagnose read-only first: `lsblk -f`, `dmesg`, `smartctl -a`,
  `journalctl -D /mnt/var/log/journal -b -1 -p warning`, `arch-chroot /mnt tail -50 /var/log/pacman.log`.
- Back up any file before editing: `cp FILE FILE.rescue-bak`.
- Unmount with `omarchy-rescue-mount --unmount` before rebooting.
- The live rescue root is a RAM overlay (`cow_spacesize=50%` ~= 1.6 GiB on this box).
  Do not `pacman -S` anything large.