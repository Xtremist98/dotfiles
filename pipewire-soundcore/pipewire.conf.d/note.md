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
| `cheapbuds.txt` (wired / cheap-bud baseline) | `~/.config/pipewire/` |
| `cheapbuds-hd800s.txt` (same driver, warm / bass-forward) | `~/.config/pipewire/` |
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

## Caveats on what is stored here

The copies in this tree are the **Soundcore-era** versions:

- `01-paramatric-eq.conf` points `equalizer.filepath` at `soundcore.txt`, which
  is the right default for a restore (the buds are the normal output). **On this
  box it currently points somewhere else** — at
  `~/.config/pipewire/cheapbuds-hd800s.txt`, because the buds are swapped out for
  the wired earbuds. Do not "sync" that one line back: the EQ node is global, not
  per-device, so whichever file is named applies to buds and wired jack alike.
  Repointing is a one-line change to `equalizer.filepath` (line 4) followed by a
  full `pipewire`/`pipewire-pulse`/`wireplumber` restart; do it only
  deliberately.
- `cheapbuds.txt` is a **7-band curve built for a small cheap driver**, not for
  the Soundcore buds: `Preamp: -6.0 dB`, `PK 120 Hz +4.5 Q0.90`,
  `PK 200 Hz +2.0 Q0.90`, `PK 480 Hz -1.0 Q1.40`, `PK 1900 Hz +1.0 Q1.20`,
  `PK 3100 Hz +1.2 Q1.60`, `PK 6800 Hz -2.0 Q2.50`, `HSC 9000 Hz -1.0 Q0.70`.
  Peak +5.59 dB raw at 129 Hz, so `-6.0` lands the peak at -0.41 dBFS — 0.41 dB
  of sample-peak headroom, nothing clips. Do not raise the preamp above -5.6:
  that is the point where the peak crosses full scale, and loudness belongs to
  the sink, not the preamp. It is the **baseline** wired-earbud curve (the
  warmer variant below is what is live now), and it is kept as the
  alternative to the handmade AKG curve, which cuts 6 dB of preamp, scoops the
  low mids with a Q 0.30 filter at 142 Hz, and dips 3 dB at 5.7 kHz — that
  combination is what made the little earbuds sound thin. Bass lives at
  120-250 Hz here on purpose: a driver that size makes no 30 Hz, so a sub-bass
  shelf only costs headroom. Because the EQ node is global, this file and the
  others can never be active at the same time.
- `cheapbuds-hd800s.txt` is the same driver with a **warm, bass-forward shape**:
  6 bands, `Preamp: -5.9 dB`, `PK 100 Hz +4.8 Q0.70`, `PK 200 Hz +1.6 Q0.90`,
  `PK 400 Hz +0.2 Q0.85`, `PK 2000 Hz +1.0 Q1.20`, `PK 3400 Hz +1.5 Q1.60`,
  `PK 6500 Hz -1.5 Q2.20`. Raw peak +5.43 dB at 108 Hz, floor -1.21 dB at
  6576 Hz; with the preamp the peak is -0.47 dB and the minimum -7.11 dB, so
  0.47 dB of headroom and no clipping. Levelled against `cheapbuds.txt` it is
  about +2.0 dB at 100-250 Hz (the punch band sits ~0.3 dB above the mud band,
  which is the point) and about +1 dB at 2-4 kHz.
  It has no sub-bass shelf and no shelf anywhere: the lift is three peaking
  filters standing next to each other at 100 / 200 / 400 Hz, so the response
  falls monotonically from the peak and never sags in between. That
  continuity is the whole design. A low **shelf** was measured against it and
  cannot do the job — an LSC always tilts mud-ward (e.g. `LSC 250 Hz +5.0`
  gives bass +1.67 / punch +1.32 / mud +1.23), so punch can never exceed mud.
  **History, because the shape changed twice:** the first version was an
  8-band "HD 800S" tilt with `PK 9000 +2.5` and `HSC 12000 +2.0` on top of the
  bands above. It was too airy on a small closed driver, so both air bands
  were dropped (6 bands, `Preamp: -3.9 dB`) — that base was approved. It then
  read as *bass-eaten*: `PK 450 Hz -1.5` had put a saddle in the response, a
  narrow 110 Hz bump followed by a dip whose skirt reached back into ~200 Hz,
  and every dB of bass also costs a dB of preamp. The fix was not more gain but
  **one continuous 70-500 Hz lift**: the 450 Hz cut is gone, the +0.2 dB band at
  400 Hz is kept deliberately (it joins the 200 Hz bell to the flat region
  without a step), and the preamp went -3.9 -> -5.9 to pay for it.
  **Normalisation, stated plainly:** with `preamp = -(raw peak + 0.5)` the
  cascade tops out at -0.47 dBFS, so this curve is a *shape*, not a loudness
  change. The "boost + deep preamp" form and a "cut the mids + shallow preamp"
  form of the same shape are identical to ~0.03 dB; the tilt is cashed in at the
  volume knob, and no curve can raise absolute bass at a fixed knob without
  clipping. **This is the file currently live on this box.**
- `02-hesuvi-surround.conf` contains exactly **one** `node.target`, and it is
  the logical `node.target = "eq_input"` (HeSuVi output -> EQ input). That is
  correct and expected; no device name is hardcoded there.

**Do not restore `Dots/pipewire/pipewire.conf.d/01-paramatric-eq.conf`.** That
older copy pins `node.target = "alsa_output.pci-0000_00_1b.0.analog-stereo"`,
which welds the chain to the built-in analog sink and breaks routing to the
Bluetooth buds. Use the copy in this tree.

Restore from here first, then decide per-device routing on the new machine.
