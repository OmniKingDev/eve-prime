#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  EVE-PRIME — Context Menu                                    ║
# ║  Desktop right-click: desktop menu                           ║
# ║  Super+X with window focused: window menu                    ║
# ╚══════════════════════════════════════════════════════════════╝

ACTIVE=$(hyprctl activewindow -j 2>/dev/null)
HAS_WINDOW=$(echo "$ACTIVE" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print('yes' if d.get('class', '') != '' else 'no')
except:
    print('no')
")

if [ "$HAS_WINDOW" = "yes" ]; then
    # Window context menu
    CLASS=$(echo "$ACTIVE" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('class',''))")
    FLOATING=$(echo "$ACTIVE" | python3 -c "import sys,json;d=json.load(sys.stdin);print('yes' if d.get('floating') else 'no')")

    if [ "$FLOATING" = "yes" ]; then
        FLOAT_LABEL="󰕰  Tile Window"
    else
        FLOAT_LABEL="󰖲  Float Window"
    fi

    CHOICE=$(printf \
"$FLOAT_LABEL\n󰆾  Center Window\n󰻿  Pin Window\n─────────────\n󰖯  Opacity 100%%\n󰖯  Opacity 90%%\n󰖯  Opacity 80%%\n󰖯  Opacity 70%%\n─────────────\n󰊓  Move to WS 1\n󰊓  Move to WS 2\n󰊓  Move to WS 3\n󰊓  Move to WS 4\n󰊓  Move to WS 5\n─────────────\n󰮘  Fullscreen\n󰮘  Fake Fullscreen\n─────────────\n󰅖  Close Window" \
        | wofi --dmenu --prompt "$CLASS" --width 300 --height 500)
else
    # Desktop context menu
    CHOICE=$(printf \
"󰃭  Wallpaper Picker\n󰑓  Reload Config\n─────────────\n󰍹  Display Settings\n󰓃  Audio Settings\n󰤨  Network\n─────────────\n  App Launcher\n󰆍  Terminal\n─────────────\n  Eve Settings\n󰐦  System Info" \
        | wofi --dmenu --prompt "EVE-PRIME" --width 280 --height 450)
fi

ADDR=$(hyprctl activewindow -j 2>/dev/null | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('address',''))" 2>/dev/null)

case "$CHOICE" in
    # Window actions
    *"Float Window"*)     hyprctl dispatch togglefloating ;;
    *"Tile Window"*)      hyprctl dispatch togglefloating ;;
    *"Center Window"*)    hyprctl dispatch centerwindow ;;
    *"Pin Window"*)       hyprctl dispatch pin ;;
    *"Opacity 100%"*)     hyprctl setprop address:$ADDR alpha 1.0 ;;
    *"Opacity 90%"*)      hyprctl setprop address:$ADDR alpha 0.9 ;;
    *"Opacity 80%"*)      hyprctl setprop address:$ADDR alpha 0.8 ;;
    *"Opacity 70%"*)      hyprctl setprop address:$ADDR alpha 0.7 ;;
    *"Move to WS 1"*)     hyprctl dispatch movetoworkspace 1 ;;
    *"Move to WS 2"*)     hyprctl dispatch movetoworkspace 2 ;;
    *"Move to WS 3"*)     hyprctl dispatch movetoworkspace 3 ;;
    *"Move to WS 4"*)     hyprctl dispatch movetoworkspace 4 ;;
    *"Move to WS 5"*)     hyprctl dispatch movetoworkspace 5 ;;
    *"Fullscreen"*)       hyprctl dispatch fullscreen 0 ;;
    *"Fake Fullscreen"*)  hyprctl dispatch fullscreen 1 ;;
    *"Close Window"*)     hyprctl dispatch killactive ;;
    # Desktop actions
    *"Wallpaper Picker"*) ~/.config/hypr/scripts/omni_wall.sh pick ;;
    *"Reload Config"*)    hyprctl reload && notify-send "EVE-PRIME" "󰑓 Config reloaded" ;;
    *"Display Settings"*) notify-send "Display" "$(hyprctl monitors | grep -E 'Monitor|resolution')" ;;
    *"Audio Settings"*)   pavucontrol & ;;
    *"Network"*)          nm-connection-editor & ;;
    *"App Launcher"*)     wofi --show drun & ;;
    *"Terminal"*)         kitty & ;;
    *"Eve Settings"*)     ~/.config/hypr/scripts/eve-settings.sh ;;
    *"System Info"*)      notify-send "System" "Kernel: $(uname -r)\nUptime: $(uptime -p)\nRAM: $(free -h | awk '/^Mem/{print $3"/"$2}')" ;;
esac
