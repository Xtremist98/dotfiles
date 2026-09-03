#!/usr/bin/env bash
set -euo pipefail

CONFIG="$HOME/.config/omarchy/shell.json"
PROFILES="$HOME/.config/omarchy/profiles"

if [[ ! -f "$CONFIG" ]]; then
  echo "error: $CONFIG not found" >&2
  exit 1
fi

current=$(python3 -c 'import json,sys
try:
    d=json.load(open(sys.argv[1]))
    print(d.get("bar",{}).get("id","") or "omarchy.bar")
except Exception:
    print("omarchy.bar")' "$CONFIG")

if [[ "$current" == "local.bar" ]]; then
  src="$PROFILES/shell.omarchy.json"
  next="omarchy.bar"
else
  src="$PROFILES/shell.localbar.json"
  next="local.bar"
fi

if [[ ! -f "$src" ]]; then
  echo "error: profile $src not found" >&2
  exit 1
fi

backup="$CONFIG.bak.$(date +%s)"
cp "$CONFIG" "$backup"
cp "$src" "$CONFIG"

echo "bar: $current -> $next  (backup: $backup)"
