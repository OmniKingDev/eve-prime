#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  EVE-PRIME — Daemon Watchdog                                ║
# ║  Monitors waybar, swaync, hypridle                          ║
# ║  Sends notification and restarts on crash                   ║
# ║  Started in Stage 6 of autostart.conf                      ║
# ╚══════════════════════════════════════════════════════════════╝

WATCH=("waybar" "swaync" "hypridle")
while true; do
    for proc in "${WATCH[@]}"; do
        if ! pgrep -x "$proc" > /dev/null; then
            notify-send "EVE-PRIME" "󰀨 $proc stopped — restarting" --urgency=normal
            case "$proc" in
                waybar)   ~/.config/hypr/scripts/waybar-launch.sh & ;;
                swaync)   swaync & ;;
                hypridle) hypridle & ;;
            esac
        fi
    done
    sleep 15
done
