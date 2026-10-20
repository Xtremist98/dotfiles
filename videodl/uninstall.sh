#!/bin/bash
# Remove the Video Grabber browser wiring (flags entry + native host manifests).
# The extension and host files in this directory are left untouched, so
# ./install.sh brings it back.

set -euo pipefail

BASE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
EXT_DIR="$BASE/extension"
HOST_NAME="com.linuxer.videodl"
STAMP=$(date +%s)

say() { printf '%s\n' "$*"; }

BROWSER_ROOTS=(
  "$HOME/.config/chromium"
  "$HOME/.config/google-chrome"
  "$HOME/.config/google-chrome-beta"
  "$HOME/.config/google-chrome-unstable"
  "$HOME/.config/BraveSoftware/Brave-Browser"
  "$HOME/.config/BraveSoftware/Brave-Browser-Beta"
  "$HOME/.config/BraveSoftware/Brave-Browser-Nightly"
  "$HOME/.config/BraveSoftware/Brave-Origin"
  "$HOME/.config/BraveSoftware/Brave-Origin-Beta"
  "$HOME/.config/BraveSoftware/Brave-Origin-Nightly"
  "$HOME/.config/microsoft-edge"
  "$HOME/.config/microsoft-edge-dev"
)

say "[1/2] native messaging host manifests"
for root in "${BROWSER_ROOTS[@]}"; do
  f="$root/NativeMessagingHosts/$HOST_NAME.json"
  if [[ -f $f ]]; then
    rm -f "$f"
    say "      removed: $f"
  fi
done

say "[2/2] browser flags"
unpatch_flags() {
  local file=$1
  [[ -f $file ]] || return 0
  grep -qF "$EXT_DIR" "$file" || { say "      clean:   $file"; return 0; }

  cp -a "$file" "$file.bak.$STAMP"

  # Drop our path from the comma list; delete the line if nothing is left.
  python3 - "$file" "$EXT_DIR" <<'PY'
import sys
path, ext = sys.argv[1], sys.argv[2]
out = []
for line in open(path, encoding="utf-8").read().splitlines(True):
    if line.startswith("--load-extension=") and ext in line:
        value = line.split("=", 1)[1].strip()
        items = [p for p in value.split(",") if p and p != ext]
        # stock Omarchy paths are kept; only our entry is stripped
        if not items:
            continue
        line = "--load-extension=" + ",".join(items) + "\n"
    out.append(line)
open(path, "w", encoding="utf-8").writelines(out)
PY
  say "      cleaned: $file"
}

for f in "$HOME/.config/chromium-flags.conf" \
         "$HOME/.config/brave-origin-flags.conf" \
         "$HOME/.config/brave-flags.conf"; do
  unpatch_flags "$f"
done

say ""
say "Done. Restart the browser to unload the extension."
say "Files were kept in $BASE — run ./install.sh to reinstate."
