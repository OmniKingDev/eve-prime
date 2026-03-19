#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  EVE-PRIME — Settings Panel (Super+I)                       ║
# ║  Quick access to display, audio, network, system info       ║
# ╚══════════════════════════════════════════════════════════════╝

CHOICE=$(printf \
"󰍹  Display\n󰓃  Audio\n󰤨  Network\n󰟩  Bluetooth\n󰖩  Theme\n󰏔  Packages\n󱁤  System Info\n󰊠  About EVE-PRIME" \
    | wofi --dmenu --prompt "EVE Settings" --width 300 --height 380)

case "$CHOICE" in
    *"Display"*)    notify-send "Display" "$(hyprctl monitors | grep -E 'Monitor|resolution|at|scale')" ;;
    *"Audio"*)      pavucontrol & ;;
    *"Network"*)    nm-connection-editor & ;;
    *"Bluetooth"*)  blueman-manager & ;;
    *"Theme"*)      notify-send "Theme" "Wallpaper: $(cat ~/.config/hypr/last-wallpaper 2>/dev/null || echo default)" ;;
    *"Packages"*)
        COUNT=$(dpkg -l | grep -c "^ii")
        notify-send "Packages" "󰏔 $COUNT installed" ;;
    *"System Info"*)
        notify-send "System" "Kernel: $(uname -r)\nUptime: $(uptime -p)\nRAM: $(free -h | awk '/^Mem/{print $3"/"$2}')" ;;
    *"About"*)
        notify-send "EVE-PRIME" "󱄑 OmniKing Dev\nEve Industries\nBuilt different." ;;
esac
