#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  EVE-PRIME — Boot Requirement Check                          ║
# ║  Verifies all required tools are installed                   ║
# ║  Sends desktop notification for any missing dependencies     ║
# ╚══════════════════════════════════════════════════════════════╝

REQUIRED=(
    "waybar" "swaync" "hypridle" "hyprlock"
    "wofi" "rofi" "playerctl" "nm-applet"
    "blueman-applet" "pamixer" "brightnessctl"
    "grim" "slurp" "wl-clipboard" "mpvpaper"
    "python3" "convert"
)
MISSING=()
for tool in "${REQUIRED[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
        MISSING+=("$tool")
    fi
done
if [ ${#MISSING[@]} -gt 0 ]; then
    notify-send "EVE-PRIME — Missing Tools" \
        "󰀨 Install: ${MISSING[*]}" \
        --urgency=critical --expire-time=10000
fi
