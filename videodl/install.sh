#!/bin/bash
# Install the Video Grabber extension + its native messaging host.
#
#   ./install.sh            install / refresh everything
#   ./uninstall.sh          remove browser wiring (files here are kept)
#
# Nothing outside $HOME is touched: the native host lives in this directory and
# the browser manifests are per-user, so no sudo is needed.

set -euo pipefail

BASE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
HOST="$BASE/host/videodl-host"
EXT_DIR="$BASE/extension"
EXT_ID_FILE="$BASE/key/extension-id.txt"
NM_SRC="$BASE/native-messaging/com.linuxer.videodl.json"
HOST_NAME="com.linuxer.videodl"
FLAGS_STAMP=$(date +%s)

# The three extensions Omarchy ships, used when a flags file needs a fresh line.
STOCK_EXT="/usr/share/omarchy/default/chromium/extensions/copy-url,\
/usr/share/omarchy/default/chromium/extensions/yt-dlp,\
/usr/share/omarchy/default/chromium/extensions/whatsapp-slim"

say() { printf '%s\n' "$*"; }

# ------------------------------------------------------------------ dependencies
# jq/python3 are needed by this script; yt-dlp/ffmpeg by the host at download time.
missing=0
for cmd in python3 jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    pkg=$cmd; [[ $cmd == python3 ]] && pkg=python
    echo "error: '$cmd' is required — sudo pacman -S $pkg" >&2
    missing=1
  fi
done
((missing == 0)) || exit 1

for cmd in yt-dlp ffmpeg ffprobe; do
  command -v "$cmd" >/dev/null 2>&1 || say "warning: '$cmd' not found — the extension will load but downloads will fail (sudo pacman -S yt-dlp ffmpeg)"
done

# ---------------------------------------------------------------- sanity checks
[[ -x $HOST ]] || chmod 755 "$HOST"
python3 -m py_compile "$HOST" 2>/dev/null || {
  echo "error: $HOST does not compile" >&2
  exit 1
}

[[ -f $EXT_DIR/manifest.json ]] || { echo "error: missing $EXT_DIR/manifest.json" >&2; exit 1; }
grep -q '"key"' "$EXT_DIR/manifest.json" || { echo "error: extension manifest has no pinned key" >&2; exit 1; }

EXT_ID=$(tr -d '[:space:]' <"$EXT_ID_FILE")
[[ ${#EXT_ID} -eq 32 ]] || { echo "error: bad extension id in $EXT_ID_FILE" >&2; exit 1; }

say "extension id : $EXT_ID"
say "extension dir: $EXT_DIR"
say "host binary  : $HOST"
say ""

# ------------------------------------------------ native messaging host manifests
# Same browser roots Omarchy uses for its own yt-dlp host, as "profile-root|binaries".
# A root is used when the profile directory already exists, OR when one of its
# binaries is installed — that covers a browser that was installed but not yet
# launched (the directory is then created, which is harmless).
BROWSER_ROOTS=(
  "$HOME/.config/chromium|chromium"
  "$HOME/.config/google-chrome|google-chrome google-chrome-stable"
  "$HOME/.config/google-chrome-beta|google-chrome-beta"
  "$HOME/.config/google-chrome-unstable|google-chrome-unstable"
  "$HOME/.config/BraveSoftware/Brave-Browser|brave-browser brave"
  "$HOME/.config/BraveSoftware/Brave-Browser-Beta|brave-browser-beta brave-beta"
  "$HOME/.config/BraveSoftware/Brave-Browser-Nightly|brave-browser-nightly"
  "$HOME/.config/BraveSoftware/Brave-Origin|brave-origin"
  "$HOME/.config/BraveSoftware/Brave-Origin-Beta|brave-origin-beta"
  "$HOME/.config/BraveSoftware/Brave-Origin-Nightly|brave-origin-nightly"
  "$HOME/.config/microsoft-edge|microsoft-edge-stable microsoft-edge"
  "$HOME/.config/microsoft-edge-dev|microsoft-edge-dev"
)

has_bin() { command -v "$1" >/dev/null 2>&1; }

say "[1/2] native messaging host"
# Always rewrite path + allowed_origins from this directory, so the manifest is
# correct even if the tree was moved or the key regenerated.
manifest=$(jq --arg p "$HOST" --arg o "chrome-extension://$EXT_ID/" \
  '.path = $p | .allowed_origins = [$o]' "$NM_SRC")

installed=0
for entry in "${BROWSER_ROOTS[@]}"; do
  root=${entry%%|*}
  bins=${entry#*|}

  if [[ ! -d $root ]]; then
    found=""
    for b in $bins; do
      has_bin "$b" && { found=$b; break; }
    done
    [[ -n $found ]] || continue
    mkdir -p "$root"
    say "      (new profile dir for $found: $root)"
  fi

  mkdir -p "$root/NativeMessagingHosts"
  printf '%s\n' "$manifest" >"$root/NativeMessagingHosts/$HOST_NAME.json"
  say "      $root/NativeMessagingHosts/$HOST_NAME.json"
  installed=$((installed + 1))
done
((installed > 0)) || { echo "error: no browser profile directories found" >&2; exit 1; }

# ------------------------------------------------------------- --load-extension
# Extend the existing list when the browser already loads unpacked extensions,
# otherwise write a line that keeps Omarchy's three stock ones.
#
# On a fresh machine the flags file usually does not exist at all (Omarchy ships
# it only as /usr/share/omarchy/config/chromium-flags.conf), so create a minimal
# one — without it the browser would never see the extension.
patch_flags() {
  local file=$1
  local bin=$2

  if [[ ! -f $file ]]; then
    if ! command -v "$bin" >/dev/null 2>&1; then
      return 0
    fi
    mkdir -p "$(dirname "$file")"
    printf -- '--ozone-platform=wayland\n--ozone-platform-hint=wayland\n--no-default-browser-check\n' >"$file"
    say "      created:    $file"
  fi

  if grep -qF "$EXT_DIR" "$file"; then
    say "      up to date: $file"
    return 0
  fi

  cp -a "$file" "$file.bak.$FLAGS_STAMP"

  if grep -q '^--load-extension=' "$file"; then
    sed -i "\|^--load-extension=| s|$|,$EXT_DIR|" "$file"
    say "      extended:   $file"
  else
    printf -- '--load-extension=%s,%s\n' "$STOCK_EXT" "$EXT_DIR" >>"$file"
    say "      added line: $file"
  fi
}

say "  [2/2] browser flags"

# Only touch browsers that are actually installed, plus any flags file that is
# already loading unpacked extensions.
CHROMIUM_FLAGS="$HOME/.config/chromium-flags.conf"
BRAVE_ORIGIN_FLAGS="$HOME/.config/brave-origin-flags.conf"
BRAVE_FLAGS="$HOME/.config/brave-flags.conf"

if has_bin chromium || grep -q '^--load-extension=' "$CHROMIUM_FLAGS" 2>/dev/null; then
  patch_flags "$CHROMIUM_FLAGS" chromium
fi
if has_bin brave-origin || grep -q '^--load-extension=' "$BRAVE_ORIGIN_FLAGS" 2>/dev/null; then
  patch_flags "$BRAVE_ORIGIN_FLAGS" brave-origin
fi
if has_bin brave || has_bin brave-browser || grep -q '^--load-extension=' "$BRAVE_FLAGS" 2>/dev/null; then
  patch_flags "$BRAVE_FLAGS" "$(has_bin brave && echo brave || echo brave-browser)"
fi

say ""
say "Done. Restart Chromium / Brave Origin completely, then open any video:"
say "  a small arrow appears at the top-right of the player."
say ""
say "If a browser was already running, close every window (or 'pkill chromium')."
