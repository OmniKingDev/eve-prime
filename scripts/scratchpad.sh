#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  EVE-PRIME — Scratchpad Terminal Toggle                      ║
# ║  F12: show/hide dropdown terminal                            ║
# ║  First call spawns kitty with class=scratchpad               ║
# ║  Subsequent calls toggle special workspace visibility        ║
# ╚══════════════════════════════════════════════════════════════╝

RUNNING=$(hyprctl clients -j | python3 -c "
import sys, json
clients = json.load(sys.stdin)
print('yes' if any(c.get('class') == 'scratchpad' for c in clients) else 'no'
)" 2>/dev/null)

if [[ "$RUNNING" == "yes" ]]; then
    hyprctl dispatch togglespecialworkspace scratchpad
else
    kitty --class scratchpad &
fi
