#!/bin/bash
# ~/.config/hypr/scripts/context-handler.sh
# Reads selection from omni-menu and executes the right command

read -r SELECTION

case "$SELECTION" in
    " Terminal")
        kitty &
        ;;
    " Files")
        thunar &
        ;;
    " App Launcher")
        wofi --show drun &
        ;;
    " Code Editor")
        code . &
        ;;
    " Firefox")
        firefox &
        ;;
    " Wallpaper Pick")
        ~/.config/hypr/scripts/wallpaper-pick.sh &
        ;;
    " Color Picker")
        hyprpicker -a &
        ;;
    " Screenshot Area")
        grimblast copysave area &
        ;;
    " System Monitor")
        kitty --title btop -e btop &
        ;;
    " Audio Mixer")
        pavucontrol &
        ;;
    " Reload Hyprland")
        hyprctl reload && notify-send "Hyprland" "Config reloaded ✓"
        ;;
    " Hyprland Settings")
        kitty --title "Hyprland Config" -e nano ~/.config/hypr/hyprland.conf &
        ;;
    " Lock Screen")
        hyprlock &
        ;;
    " Sleep")
        systemctl suspend
        ;;
    " Reboot")
        systemctl reboot
        ;;
    " Shutdown")
        systemctl poweroff
        ;;
esac
