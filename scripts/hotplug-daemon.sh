#!/bin/bash
# Listens to Hyprland socket for monitor connect/disconnect events
socat - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | \
while read -r line; do
    if echo "$line" | grep -q "monitorAdded\|monitorRemoved"; then
        ~/.config/hypr/scripts/monitor-hotplug.sh
    fi
done
