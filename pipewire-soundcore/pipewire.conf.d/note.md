# rtkit — realtime scheduling for PipeWire

**Short answer: install nothing, configure nothing.** There are no post-install
settings for rtkit. Do not create `/etc/rtkit.conf`, do not add a systemd
drop-in, do not add your user to a group, do not `systemctl enable` it.

On a fresh Omarchy install you do not even install it by hand:

- `/usr/share/omarchy/install/omarchy-base.packages` line 132 lists `rtkit`,
  so the base install already pulls it in.
- Migration `1789747667.sh` ("Install rtkit so PipeWire gets realtime
  priority") runs `omarchy-realtime-repair`, which raises hard `RLIMIT_RTTIME=0`
  limits, installs rtkit, then re-checks. It ran on this box 2026-10-30.

So: after a fresh install + dots restore, just confirm it is there with
`pacman -Q rtkit`. Nothing else to do.

## Why it looks "disabled" but is fine

```
systemctl cat rtkit-daemon.service  ->  Type=dbus
                                        BusName=org.freedesktop.RealtimeKit1
```

Because it is D-Bus activated, `systemctl is-enabled rtkit-daemon` reporting
`disabled` **is the correct steady state**. Never "fix" it with
`systemctl enable`.

It starts on demand: pipewire asks for RT, D-Bus spawns the daemon, the daemon
grants the scheduling change, and it goes idle again.

No config file exists on Arch (`pacman -Ql rtkit` shows no `/etc/rtkit.conf`),
and `/etc/systemd/system/rtkit-daemon.service.d/` does not exist. That is stock
and correct. No `realtime-privileges` package and no group membership needed —
authorisation goes through polkit action `org.freedesktop.RealtimeKit1` with
`allow_active=yes` / `allow_any=no` (an active local session is enough).

## What rtkit actually does (it is NOT the mlock half)

Live caps, read from D-Bus:

| Setting | Value |
| --- | --- |
| `MaxRealtimePriority` | 20 |
| `MinNiceLevel` | -15 |
| `RTTimeUSecMax` | 200000 (200 ms) |

`/usr/share/pipewire/pipewire.conf` asks `libpipewire-module-rt` for
`nice.level = -11` and `rt.prio = 88`. rtkit silently clamps `88 -> 20`. Nothing
to change; that is normal and already verified working:

- `data-loop.0` thread: `SCHED_RR | SCHED_RESET_ON_FORK`, priority 20
- pipewire main thread: nice -11
- journal: `rtkit-daemon: Successfully made thread ... RT at priority 20`

One rule: do **not** raise `rt.time.soft` above `200000` anywhere (no local
module-rt override exists today, and none is needed). rtkit refuses a request
above `RTTimeUSecMax`, and without RT the audio graph falls back to
`SCHED_OTHER` and xruns under load — which is the exact bug rtkit exists to
prevent.

Also leave Omarchy's `HYPRLAND_NO_RT=1` alone (exported by
`/usr/share/omarchy/default/uwsm/default:13`). Hyprland 0.57 asks rtkit for RT,
gets the same 200 ms budget, and the kernel SIGKILLs the compositor at the
first watchdog break. Do not set it to 0.

## mlock is a separate thing — three files, all present in this tree

rtkit handles **scheduling**. Pinning the audio graph in RAM is handled
entirely by memlock settings, which have nothing to do with rtkit:

1. `pipewire.conf.d/99-realtime-mlock.conf`

   ```ini
   context.properties = { mem.allow-mlock = true
                          mem.mlock-all  = true }
   ```

2. `systemd/user/pipewire.service.d/limits.conf`
   `systemd/user/pipewire-pulse.service.d/limits.conf`

   ```ini
   [Service]
   LimitMEMLOCK=infinity
   ```

3. `etc/security/limits.d/99-audio-memlock.conf`

   ```
   linuxer soft memlock unlimited
   linuxer hard memlock unlimited
   ```

All three are **required** — file 1 alone is not enough, because the unit-level
MEMLOCK ceiling overrides what the process asks for, and the kernel's per-user
limit from file 3 caps the unit. Skip 2 or 3 and `mlockall` fails with ENOMEM
and the journal logs `could not mlockall`.

> **Watch the username in file 3:** it is hardcoded to `linuxer`. Omarchy's
> installer asks for a username, so if the new install uses a different one,
> edit both lines before copying, or the limit silently applies to nobody.

The user manager also caps children, so on an existing session you may need:

```bash
sudo prlimit --pid $(pgrep -u $USER -x systemd | head -1) --memlock=unlimited:unlimited
```

(use the word `unlimited`; `infinity` fails to parse there).

Verify after restoring: `VmLck` should be ~160 MB and `VmSwap` 0 for the
pipewire process, `systemctl --user show pipewire -p LimitMEMLOCK` = `infinity`,
and zero `could not mlockall` lines since boot.

> **Note:** pinning ~160 MB is a deliberate trade on this 3.2 GiB box — it stops
> memory pressure from stalling the HeSuVi/EQ chain. If RAM ever gets tight,
> this is one of the first knobs to reconsider.

## Tree map — where each file goes on a restore

Paths below are relative to this directory. `systemd/user/` mirrors
`~/.config/systemd/user/` and `etc/` mirrors `/etc/` — nothing is invented.

| In this tree | Goes to |
| --- | --- |
| `pipewire.conf.d/01-paramatric-eq.conf` | `~/.config/pipewire/pipewire.conf.d/` |
| `pipewire.conf.d/02-hesuvi-surround.conf` | `~/.config/pipewire/pipewire.conf.d/` |
| `pipewire.conf.d/99-lock-quantum.conf` | `~/.config/pipewire/pipewire.conf.d/` |
| `pipewire.conf.d/99-realtime-mlock.conf` | `~/.config/pipewire/pipewire.conf.d/` |
| `soundcore.txt` (+ `-honey` / `-spacious`) | `~/.config/pipewire/` |
| `atmos.wav` (HeSuVi IR) | `~/.config/pipewire/` |
| `systemd/user/pipewire.service.d/limits.conf` | `~/.config/systemd/user/pipewire.service.d/` |
| `systemd/user/pipewire-pulse.service.d/limits.conf` | `~/.config/systemd/user/pipewire-pulse.service.d/` |
| `etc/security/limits.d/99-audio-memlock.conf` | `/etc/security/limits.d/` (**ROOT**, edit username) |

`/etc/security/limits.d/` needs `sudo mkdir -p` first if it does not exist yet.

After copying:

```bash
systemctl --user daemon-reload
systemctl --user restart pipewire pipewire-pulse wireplumber
```

Restarting all three together matters — restarting pipewire alone leaves the
session daemons pointing at dead sockets.

## Caveat on the two configs stored here

The copies in this tree are the **Soundcore-era** versions:

- `01-paramatric-eq.conf` points `equalizer.filepath` at `soundcore.txt`.
  **On this box that is still what runs** — `~/.config/pipewire/eq.txt` (the AKG
  curve, `Preamp: -6.0 dB`) exists but is *not* wired in. Repointing is a
  one-line change to `equalizer.filepath` (line 4) followed by a full
  `pipewire`/`pipewire-pulse`/`wireplumber` restart; do it only deliberately,
  and note the EQ node is global, not per-device, so it also applies to any
  wired/other output.
- `02-hesuvi-surround.conf` contains exactly **one** `node.target`, and it is
  the logical `node.target = "eq_input"` (HeSuVi output -> EQ input). That is
  correct and expected; no device name is hardcoded there.

**Do not restore `Dots/pipewire/pipewire.conf.d/01-paramatric-eq.conf`.** That
older copy pins `node.target = "alsa_output.pci-0000_00_1b.0.analog-stereo"`,
which welds the chain to the built-in analog sink and breaks routing to the
Bluetooth buds. Use the copy in this tree.

Restore from here first, then decide per-device routing on the new machine.
