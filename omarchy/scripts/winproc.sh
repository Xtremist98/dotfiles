#!/usr/bin/env bash
# Resolve the foreground process of a terminal window from the terminal's PID.
# Prints the executable name (comm) of the process in the foreground process
# group of the terminal's pty, or nothing if it can't be determined.
# Used by plugins/local.bar/panels/window/Panel.qml to show the app running
# inside a terminal (foot, alacritty, kitty, ...) instead of just the terminal.

pid="${1:-}"
[ -n "$pid" ] || exit 0

# Collect the process tree rooted at the terminal PID.
all="$pid"
frontier="$pid"
while :; do
  children="$(ps --ppid "$frontier" -o pid= 2>/dev/null | tr '\n' ' ')"
  children="${children// /}"
  [ -z "$children" ] && break
  frontier="$children"
  all="$all $children"
done

# Find the pty a descendant is attached to (the terminal's child shell).
tty=""
for p in $all; do
  t="$(ps -o tty= -p "$p" 2>/dev/null | tr -d ' ')"
  if [ -n "$t" ] && [ "$t" != "?" ]; then
    tty="$t"
    break
  fi
done
[ -n "$tty" ] || exit 0

# The foreground process group on that pty is marked with '+' in STAT.
# Pick the first foreground non-shell process.
ps -t "$tty" -o stat=,comm=,args= 2>/dev/null |
  awk '$1 ~ /\+/ {
    if ($2 == "bash" || $2 == "zsh" || $2 == "fish" || $2 == "sh" ||
        $2 == "dash" || $2 == "ksh" || $2 == "tmux") next
    # Codex runs in a bwrap sandbox, so its foreground executable can be
    # reported as bwrap. Its command line still carries the codex binary.
    if (tolower($0) ~ /codex/) {
      print "codex"
      exit
    }
    print $2
    exit
  }'
