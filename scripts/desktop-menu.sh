#!/usr/bin/env bash
# Only launch nwg-menu if right-clicking on empty desktop (no window under cursor)
WINDOW=$(hyprctl activewindow -j | python3 -c "
import json, sys
try:
    w = json.load(sys.stdin)
    print(w.get('address', ''))
except:
    print('')
")

if [[ -z "$WINDOW" ]]; then
    nwg-menu -k -wm hyprland \
        -cmd-lock "hyprlock" \
        -cmd-logout "hyprctl dispatch exit 0" \
        -cmd-restart "systemctl reboot" \
        -cmd-shutdown "systemctl poweroff" \
        -term "kitty"
fi
