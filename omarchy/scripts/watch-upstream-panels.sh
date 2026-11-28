#!/bin/bash
# Detect upstream Omarchy changes to the panel/widget sources we have cloned
# or copied into local.bar. Runs unattended from an Omarchy automation.

set -u

state_dir="$HOME/.local/state/omarchy/upstream-watch"
mkdir -p "$state_dir"
manifest="$state_dir/manifest.sha256"
previous="$state_dir/manifest.previous.sha256"
report="$state_dir/report.txt"
current="$state_dir/manifest.current.sha256"

watch_paths=(
  /usr/share/omarchy/shell/plugins/bar/Bar.qml
  /usr/share/omarchy/shell/plugins/bar/BarModel.js
  /usr/share/omarchy/shell/plugins/panels/power
  /usr/share/omarchy/shell/plugins/panels/audio
  /usr/share/omarchy/shell/plugins/panels/monitor
  /usr/share/omarchy/shell/plugins/panels/network
  /usr/share/omarchy/shell/plugins/panels/bluetooth
  /usr/share/omarchy/shell/plugins/panels/clock
  /usr/share/omarchy/shell/plugins/panels/tailscale
  /usr/share/omarchy/shell/plugins/panels/agents
  /usr/share/omarchy/shell/plugins/bar/widgets/Workspaces.qml
)

find "${watch_paths[@]}" -type f -print0 2>/dev/null \
  | sort -z \
  | xargs -0 -r sha256sum > "$current"

if [[ ! -f "$manifest" ]]; then
  cp "$current" "$manifest"
  {
    echo "Baseline written $(date '+%F %T')"
    echo "Watching: ${watch_paths[*]}"
  } > "$report"
  exit 0
fi

if cmp -s "$current" "$manifest"; then
  exit 0
fi

cp "$manifest" "$previous"
cp "$current" "$manifest"

changed=$(diff -u "$previous" "$manifest" \
  | grep -E '^[+-][0-9a-f]' \
  | sed -E 's/^[+-][0-9a-f]+[[:space:]]+//' \
  | sort -u)

{
  echo "Upstream panel changes detected $(date '+%F %T')"
  echo "Changed files:"
  echo "$changed"
  echo
  echo "Please merge upstream into the local clones/copies, preserving local theming."
} > "$report"

message=$(printf '%s\n' "$changed" | head -12)
if command -v notify-send >/dev/null 2>&1; then
  notify-send -u critical -a "Omarchy upstream watch" \
    "Upstream panel changes detected" \
    "$message"$'\n\n'"See $report" 2>/dev/null || true
fi
if command -v logger >/dev/null 2>&1; then
  logger -t omarchy-upstream-watch "Upstream panel changes detected; see $report" 2>/dev/null || true
fi
