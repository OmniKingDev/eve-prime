#!/bin/bash
# Debounce rapid workspace switches — max 1 switch per 80ms
# Prevents compositor race conditions on keyboard spam
LOCKFILE="/tmp/ws-switch.lock"
TARGET="$1"

if [ -f "$LOCKFILE" ]; then
    exit 0
fi

touch "$LOCKFILE"
hyprctl dispatch workspace "$TARGET"
sleep 0.08
rm "$LOCKFILE"
