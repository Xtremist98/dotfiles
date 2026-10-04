---
name: soundcore-eq
description: Tune, maintain, and troubleshoot the parametric EQ for the Soundcore R60i NC Bluetooth buds on this machine (PipeWire/EasyEffects format), plus the measured transport/codec facts behind it. Use when editing ~/.config/pipewire/soundcore.txt, dialing the EQ toward a target signature (e.g. an HD 800S-like neutral-spacious sound), checking the negotiated Bluetooth codec (must be sbc_xq, ~546 kbps dual channel), or diagnosing muddy/hollow/sibilant sound, the ~3-5s thin CVSD window on connect, or any "should we enable LDAC?" question. Do not re-derive the codec or LDAC decisions — they are settled.
---

# Soundcore R60i NC — parametric EQ tuning (PipeWire)

## Context (hard facts, don't re-derive)
- Device: soundcore R60i NC buds, BT `34:09:C9:96:82:0C`, adapter Intel `8087:07dc`.
- Stack: PipeWire 1.6.8, WirePlumber 0.5.17, BlueZ 5.87. **SBC-XQ codec is FORCED always** (see `~/.config/wireplumber/wireplumber.conf.d/50-bluez-sbcxq.conf`; restrict codec pool to `sbc_xq`). The EQ is tuned against SBC-XQ's response — if the codec ever reverts to AAC, sound balance changes and may sound hollow/congested. **Verify codec live:** `wpctl inspect <sink-id> | grep codec` must show `api.bluez5.codec = "sbc_xq"`. If it flips: `systemctl --user restart wireplumber` and reconnect.
- EQ file location: **`~/.config/pipewire/soundcore.txt`** (EasyEffects "Parametric EQ" text format: `Preamp:` + `Filter N: ON <LSC|PK|HSC> Fc <Hz> Gain <dB> Q <Q>`). This is how the user loads it (pavucontrol / EasyEffects / eq preset converter). Do not use symbols in feeder spans.
- The buds are **naturally bassy and muddy** (this is the documented baseline). Any tuning must subtract boom, not add it. An alternative preset existed at `~/.config/pipewire/eq.txt` (+5.5 dB bass shelf @ 105 Hz, -8 dB preamp) — it was REJECTED because it adds bass to a bassy bud and lacks any 240 Hz de-mud cut.

## Transport: measured codec + bitrate facts (2026-09-25 — hard facts, do not re-derive)
- **SBC-XQ stays forced. LDAC was investigated and deliberately NOT enabled (user decision).** Do NOT add `ldac` to `bluez5.codecs`.
- The earbuds announce SBC with **maximum bitpool 39** — unusually LOW, because standard SBC HQ needs 51-53. All 4 channel modes, both subband counts, all block lengths, both allocation methods.
- **PipeWire negotiates correctly onto the XQ path: 48 kHz, DUAL CHANNEL, 8 subbands, 16 blocks, Loudness, bitpool 39 ≈ 546 kbps** — aptX HD (576) class. This is the sound the EQ below is tuned against.
- **600/630 kbps is NOT reachable on this hardware.** SBC-XQ EDR3 (~600) would need bitpool 47, above the buds' announced max of 39. The 617/630 figures come from pushing bitpool past the standard XQ caps.
- **Correction to older notes in this file / AGENTS.md:** "SBC-XQ ≈ 328 kbps" is WRONG — 328/345 is *standard SBC HQ*, not XQ.
- **The trace contains TWO Set Configurations.** The first is **Joint Stereo** (~273 kbps at bitpool 39) and gets **Closed**; the second is **Dual Channel** and is Opened + Started. The live stream is the dual-channel one. ⚠️ **If the second config ever fails you silently drop to ~half bitrate** — that is the cause to suspect (harsher/veiled cymbals), NOT the EQ.
- **Reproduce the capture:** `sudo bash /tmp/opencode/btmon-a2dp.sh` (forces disconnect/reconnect under capture; script at `/tmp/opencode/`, output `/tmp/opencode/btmon/a2dp.txt`, PSM 25 = AV/DTP). Parse `grep -nE 'AVDTP:' <txt>`, then read the `Get All Capabilities Response` (buds' caps + bitpool) and each `Set Configuration` block (what was actually negotiated). Bitrate model: `bytes = 2*bitpool + 13`, `kbps = bytes*8*(Fs/128)/1000`, doubled for dual channel.
- **LDAC is genuinely available on Linux** (`/usr/lib/spa-0.2/bluez5/libspa-codec-bluez5-ldac.so`) and bud firmware `04.89` accepts it (`03.89` rejected it) — it was still rejected: no real gain over 546 kbps, LDAC 990 is the least reliable mode (SoundGuys), and it costs battery on this 3.3 GB box with a 0.8 GHz TLP clamp. It also needs no latency/quantum change, so there is nothing to gain there either.
- **The Omacore LDAC toggle is a red herring / two-sided split:** `omacore-ldac` only flips the *earbud-side* `ldac` permission setting. PC-side is governed **solely** by `bluez5.codecs`. That is why flipping the toggle never changed the stream.
- **Why transport is not the quality bottleneck:** both the Soundcore app's flat EQ and this parametric EQ are applied **POST-codec**, so codec changes do not alter the EQ's target curve.

## Known cosmetic behavior: ~3-5s "thin" audio on connect — LEAVE IT
- On connecting the buds, audio briefly plays through the **HFP/headset profile (codec `cvsd`)** — thin/telephone quality — for 3-5s, then auto-switches to `sbc_xq` dual channel. Self-corrects every time. **User decision: leave it. Do not re-open.**
- **Cause:** HFP activates first and wins the connect race. A2DP is slower because PipeWire configures it **TWICE** (Joint Stereo → Close → Dual Channel), each step a full BT round trip. The capture interleaves an RFCOMM/HFP handshake (`AT+BRSF`, `AT+CIND`, `AT+CMER`, `AT+VGS`, `AT+CLIP`, `AT+CCWA`, `AT+COPS`, `AT+CMEE`, `AT+XAPL`, `AT+IPHONEACCEV`) with the AVDTP exchange.
- **Config is already correct on every lever — do NOT "fix" these:** `~/.local/state/wireplumber/default-profile` = `bluez_card.34_09_C9_96_82_0C=a2dp-sink-sbc_xq`; `bluetooth.autoswitch-to-headset-profile = false` (in `50-bluez-sbcxq.conf`); `bluez5.auto-connect = [ a2dp_sink a2dp_source ]` (in `bluetooth-a2dp-autoconnect.conf`); no stray conf under `~/.config/wireplumber/` mentions hfp/hsp/headset. `hfp_hf` sits in WirePlumber's **default `bluez5.roles`** — a list separate from `auto-connect` — which is why the headset profile becomes available even though it is never auto-connected.
- **The only clean fix costs the earbud microphone:** `monitor.bluez.properties = { bluez5.roles = [ a2dp_sink a2dp_source ] }` would stop the headset profile ever activating, but removes mic/call support. **NOT applied — user declined. Do not add it.**
- The HeSuVi(42) → eq_input(40) → eq_output(41) → bluez_output chain is unaffected (live check: sink "soundcore R60i NC" is A2DP and hesuvi remains the default sink).

## THE LIVE preset (~/.config/pipewire/soundcore.txt, saved 2026-09-18)
```
Preamp: -4.8 dB

Filter 1: ON LSC Fc 60 Hz     Gain +1.0 dB Q 0.70
Filter 2: ON PK  Fc 110 Hz    Gain +0.5 dB Q 1.20
Filter 3: ON PK  Fc 240 Hz    Gain -3.5 dB Q 1.40
Filter 4: ON PK  Fc 450 Hz    Gain +1.8 dB Q 1.10
Filter 5: ON PK  Fc 750 Hz    Gain +0.5 dB Q 1.00
Filter 6: ON PK  Fc 1600 Hz   Gain +2.2 dB Q 1.40
Filter 7: ON PK  Fc 2800 Hz   Gain +3.2 dB Q 1.30
Filter 8: ON PK  Fc 4200 Hz   Gain -0.5 dB Q 2.00
Filter 9: ON PK  Fc 5600 Hz   Gain -3.5 dB Q 3.50
Filter 10: ON PK Fc 8600 Hz   Gain +2.0 dB Q 2.00
Filter 11: ON HSC Fc 11500 Hz Gain +4.0 dB Q 0.75
```
This is the tuned-up "morning" curve (2026-09-18) — user verdict: **"everything is perfect."** The 2026-09-14 preset was superseded by this (boosts raised across the board). Preamp was raised **-6.0 → -4.8** — the user settled on **-4.8 dB as the final headroom floor**, 0.8 dB below the +4.0 shelf peak, giving enough margin for clipping on loud material. If more volume is ever wanted, use the sink/app volume instead, not the preamp. Do NOT rewrite this file unless the user asks.

## Intent per band (rationale for future tuning)
- **Preamp -4.8 dB:** headroom for the boosts (largest single is the +4.0 shelf). **-4.8 is the floor — never raise it closer to 0.** (User picked -4.8 on 2026-09-18 over -4.5 for "enough headroom".)
- **60 Hz LSC +1.0:** keep bass present on the bud's naturally boomy low end — a slight lift, not a cut. Reintroducing a cut (-1.5) went boom-suppression sitting.
- **110 Hz +0.5:** the "punch pocket" (kick ~100-120 Hz), dialed up for slam. Never past +1.0 — boom returns.
- **240 Hz -3.5 Q1.4:** THE de-mud move, kept shallower than the old -4.0/-5.5 so dialogue never goes hollow (that's what the 450 restore band is for).
- **450 Hz +1.8 Q1.1:** anti-hollow vocal/dialogue body; the main user-facing "dial." (This + 110 Hz are the go-to adjustments.)
- **1600 +2.2 / 2800 +3.2:** presence & instrument separation ("wide stage" illusion). 2800 is the main presence peak.
- **4200 -0.5 / 5600 -3.5 Q3.5:** the HD 800S-style non-fatiguing 6 kHz notch. 5600 IS the sibilance zone on these buds.
- **8600 +2.0:** 8 kHz "air peak" (shimmer without hiss).
- **11500 HSC +4.0:** extended air/sparkle; SBC-XQ can actually resolve this region (AAC rolls it off).

## Target signature
Mini-mental model: HD 800S-ish neutral-spacious — flat-touched bass, gently recessed-but-supported lower-mid (NOT hollow), rising presence 2-4k, deep 6k notch, 8k air, extended top end. Physical caveat (work it into any answer): **no EQ on a close-back IEM recreates real soundstage width** — it only maximizes the perceptual cues.

## Adjustment guide (if user complains)
- "Mud/boom again" → deepen 240 Hz (max ~-5.0) and/or cut 110 Hz to -1.
- "Hollow dialogue/vocals" → raise 450 Hz (+1.2 → +1.8) or flatten 240 Hz to -3. Also re-verify codec is sbc_xq (AAC appearance = apparent hollowness).
- "Sibilant/harsh" → deepen 5600 (-3.5 → -4.5) or narrow Q (3.5 → 4.0). Do NOT touch the 8600 +1.5 (that's the air; cutting it dulls).
- "Not spacious/airy" → raise 8600 or the 11500 shelf modestly; keep 2800 ≥ +2.5.
- "Not enough punch" → 110 Hz to +0.5/+1.0 (bump force sparingly; never past +1.0 — boom returns).
- "Too quiet overall" → raise the SINK/app volume, NOT the preamp. Preamp is pinned at **-4.8 dB (headroom floor)**.

## Format gotchas (from the two files seen)
- Use blank line after `Preamp:`.
- Gains in `-1.5 dB` / `+2.8 dB` form; Q as decimals.
- Number filters sequentially; keep them all `ON`.
- Preamp must leave headroom for the boost sum; **-4.8 dB is this machine's fixed floor** (chosen 2026-09-18 for headroom).