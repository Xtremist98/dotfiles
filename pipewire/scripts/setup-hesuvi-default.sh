#!/usr/bin/env bash
#
# setup-hesuvi-default.sh
# -----------------------
# Provision the HeSuVi -> parametric EQ -> device audio chain and make
# HeSuVi the persistent default output in WirePlumber.
#
# WHY THIS EXISTS
#   An earlier version of this script wrongly sourced Dots/pipewire/ (the wired
#   3.5mm profile) and pushed soundcore-only files into it. pipewire-soundcore/
#   is the correct source and has been left untouched.
#
#
#   This script is deliberately hardware-agnostic. It never hardcodes a
#   Bluetooth MAC or an ALSA device id; it resolves both at runtime and
#   patches them in.
#
# USAGE
#   bash setup-hesuvi-default.sh     # uses Dots/pipewire-soundcore
#   DOTS=/path/to/pipewire-soundcore bash setup-hesuvi-default.sh   # override source
#
# IDEMPOTENT
#   Safe to re-run any number of times.
#
set -uo pipefail

# SOURCE: pipewire-soundcore is the Bluetooth-buds profile (it carries the
# priority guards, the 2048/48000 quantum locks, the memlock config and the
# soundcore*.txt EQ presets). The sibling pipewire/ folder is the simpler
# 3.5mm-jack wired variant and must NOT be used here.
DOTS="${DOTS:-/mnt/media/Dots/pipewire-soundcore}"
PIPECONFDIR="$HOME/.config/pipewire/pipewire.conf.d"
PIPEDIR="$HOME/.config/pipewire"
STATEDIR="$HOME/.local/state/wireplumber"
HESUVI="effect_input.virtual-surround-7.1-hesuvi"

say()  { printf '\n\033[1;33m==> %s\033[0m\n' "$*"; }
ok()   { printf '    \033[32mok\033[0m   %s\n' "$*"; }
warn() { printf '    \033[33mwarn\033[0m %s\n' "$*"; }
die()  { printf '    \033[31mfail\033[0m %s\n' "$*" >&2; exit 1; }

[ -d "$DOTS" ] || die "source dir not found: $DOTS (override with DOTS=...)"

# ---------------------------------------------------------------- 1. copy
say "Copying pipewire config from $DOTS"
mkdir -p "$PIPECONFDIR"
for f in atmos.wav eq.txt soundcore.txt soundcore-honey.txt; do
    [ -f "$DOTS/$f" ] && cp -p "$DOTS/$f" "$PIPEDIR/$f" && ok "pipewire/$f"
done
for f in "$DOTS"/pipewire.conf.d/*.conf; do
    [ -f "$f" ] || continue
    cp -p "$f" "$PIPECONFDIR/$(basename "$f")" && ok "pipewire.conf.d/$(basename "$f")"
done

# --------------------------------------------- 2. make paths portable
# The confs carry an absolute equalizer.filepath; on a new machine the home
# dir differs. Rewrite it rather than shipping a dead path.
say "Making absolute paths portable"
EQCONF="$PIPECONFDIR/01-paramatric-eq.conf"
if [ -f "$EQCONF" ] && grep -q 'equalizer.filepath' "$EQCONF"; then
    sed -i "s|^[[:space:]]*equalizer.filepath[[:space:]]*=.*|          equalizer.filepath = \"$PIPEDIR/soundcore.txt\"|" "$EQCONF"
    grep -q "equalizer.filepath = \"$PIPEDIR/soundcore.txt\"" "$EQCONF" \
        && ok "equalizer.filepath -> $PIPEDIR/soundcore.txt" \
        || warn "could not rewrite equalizer.filepath"
fi

# ------------------------------------------------------- 3. runtime devices
# Resolve the real sink names on THIS machine. Never hardcoded.
say "Resolving this machine's audio devices"
restart_audio() {
    systemctl --user restart wireplumber >/dev/null 2>&1
    sleep 3
}

restart_audio

# NOTE: `wpctl status` prints FRIENDLY names ("Built-in Audio Analog Stereo"),
# not raw node ids, so it cannot be used to discover the real device strings.
# `pactl list short sinks` prints the raw names we actually need to write into
# the config and into WirePlumber's state.
raw_sinks() { pactl list short sinks 2>/dev/null | awk '{print $2}'; }

BT_SINK=$(raw_sinks   | grep '^bluez_output\.' | head -1)
ALSA_SINK=$(raw_sinks | grep '^alsa_output\.'  | head -1)

[ -n "$BT_SINK" ]   && ok "bluetooth sink: $BT_SINK"     || warn "no bluetooth sink right now (buds disconnected?)"
[ -n "$ALSA_SINK" ] && ok "internal sink:  $ALSA_SINK"    || warn "no alsa sink found"

# Patch node.target to the bluetooth device when we can see one. That is the
# port the EQ output rides out to when the buds are connected.
if [ -n "$BT_SINK" ] && [ -f "$EQCONF" ] && grep -q 'node.target' "$EQCONF"; then
    sed -i "s|^[[:space:]]*node.target[[:space:]]*=.*|              node.target = \"$BT_SINK\"|" "$EQCONF"
    grep -q "node.target = \"$BT_SINK\"" "$EQCONF" \
        && ok "node.target -> $BT_SINK" \
        || warn "could not rewrite node.target"
fi

if [ -z "$BT_SINK" ]; then
    warn "EQ output still targets the previous device. Re-run this script"
    warn "with the buds CONNECTED so node.target can be patched correctly."
fi

# ------------------------------------------------------- 4. restart daemons
say "Restarting pipewire stack"
systemctl --user restart wireplumber >/dev/null 2>&1
sleep 5
ok "wireplumber restarted"

# Hesuvi is created by pipewire itself; confirm it is up before we pin it.
HES_ID=$(wpctl status 2>/dev/null \
  | grep -F "$HESUVI" | grep -oE '[0-9]+\.' | head -1 | tr -d '.')
if [ -z "$HES_ID" ]; then
    # pipewire may need its own restart for the filter chain to instantiate
    systemctl --user restart pipewire pipewire-pulse >/dev/null 2>&1
    sleep 6
    HES_ID=$(wpctl status 2>/dev/null \
      | grep -F "$HESUVI" | grep -oE '[0-9]+\.' | head -1 | tr -d '.')
fi

[ -n "$HES_ID" ] || die "HeSuVi node '$HESUVI' not found - is 02-hesuvi-surround.conf installed?"
ok "HeSuVi sink present (node $HES_ID)"

# ------------------------------------------------- 5. pin the default sink
say "Pinning default output to HeSuVi"
wpctl set-default "$HES_ID" >/dev/null 2>&1
ok "wpctl set-default $HES_ID"

# ------------------------------------------------- 6. persist the default
# WirePlumber restores the UNNUMBERED key at login, and slot .0 is the entry
# that receives the +30000 priority boost. Both must be HeSuVi.
# eq_input is a filter stage, not an output device - it must NOT be a
# candidate, or it wins, gets boosted, and keeps winning.
say "Persisting the default in WirePlumber state"
mkdir -p "$STATEDIR"
STATE="$STATEDIR/default-nodes"
if [ -f "$STATE" ]; then
    cp -p "$STATE" "$STATEDIR/default-nodes.bak.$(date +%s)"
fi

# Build the device fallback list: freshly detected sinks first, then any
# previous fallbacks we could not see right now (e.g. the bluetooth device
# while the buds are disconnected). WirePlumber ignores default entries that
# match no live node, so keeping a stale name is harmless - whereas losing the
# fallback entirely is not. eq_input is always dropped: it is a filter stage,
# not an output device, and letting it win is what caused the original bug.
#
# The previous contents are snapshotted BEFORE we overwrite the file.
PREV_FALLBACKS=""
if [ -f "$STATE" ]; then
    PREV_FALLBACKS=$(grep -E '^default\.configured\.audio\.sink\.[0-9]+=' "$STATE" \
        | sed 's/^[^=]*=//' | grep -v '^eq_input$')
fi

FALLBACKS=""
add_dev() {
    local d="${1:-}"
    [ -n "$d" ] || return 0
    [ "$d" = "$HESUVI" ] && return 0
    case " $FALLBACKS " in
        *" $d "*) return 0 ;;
    esac
    FALLBACKS="${FALLBACKS}${FALLBACKS:+ }$d"
    return 0
}

add_dev "$BT_SINK"
add_dev "$ALSA_SINK"
while IFS= read -r d; do add_dev "$d"; done <<< "$PREV_FALLBACKS"

{
    echo "[default-nodes]"
    echo "default.configured.audio.sink=$HESUVI"
    echo "default.configured.audio.sink.0=$HESUVI"
    i=1
    for dev in $FALLBACKS; do
        echo "default.configured.audio.sink.$i=$dev"
        i=$((i + 1))
    done
} > "$STATE"

ok "wrote $STATEDIR/default-nodes ($((i - 1)) device fallback(s))"
sed 's/^/      /' "$STATEDIR/default-nodes"

# ---------------------------------------------- 7. login-simulation check
say "Verifying across a WirePlumber restart (login simulation)"
systemctl --user restart wireplumber >/dev/null 2>&1
sleep 6

FINAL=$(pactl get-default-sink 2>/dev/null)
if [ "$FINAL" = "$HESUVI" ]; then
    ok "default sink = $FINAL"
else
    warn "default sink = ${FINAL:-<unset>} (expected $HESUVI)"
fi

if grep -q '=eq_input' "$STATEDIR/default-nodes"; then
    warn "eq_input is still listed as a default candidate"
else
    ok "eq_input correctly absent from default candidates"
fi

say "Done"
cat <<EOF
    default output : $FINAL
    chain          : app -> hesuvi (surround) -> parametric EQ -> device
    eq presets     : $PIPEDIR/soundcore.txt

    Re-run any time; the script is idempotent.
    If the bluetooth target looks wrong, connect the buds and re-run.
EOF