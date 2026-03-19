#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  EVE-PRIME — Performance Debugger Overlay                    ║
# ║  Super+D: wofi menu → opens kitty perf-overlay window        ║
# ╚══════════════════════════════════════════════════════════════╝

CHOICE=$(printf \
"󰍛  System Stats\n󰻠  CPU per Core\n󰾲  GPU Stats\n󰝤  Memory Detail\n󰘚  Compositor Info\n󰅖  Close Overlay" \
    | wofi --dmenu --prompt "Perf Debug" --width 260 --height 260)

case "$CHOICE" in
    *"System Stats"*)
        kitty --title "EVE Debug" --class perf-overlay \
            sh -c "btop; read" &
        ;;
    *"CPU per Core"*)
        kitty --title "CPU Cores" --class perf-overlay \
            sh -c "watch -n 0.5 'grep -E \"^cpu[0-9]\" /proc/stat'; read" &
        ;;
    *"GPU Stats"*)
        kitty --title "GPU Stats" --class perf-overlay \
            sh -c "watch -n 1 'cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null || echo \"GPU stats unavailable\"'; read" &
        ;;
    *"Memory Detail"*)
        kitty --title "Memory" --class perf-overlay \
            sh -c "watch -n 1 free -h; read" &
        ;;
    *"Compositor Info"*)
        notify-send "Hyprland" "$(hyprctl version | head -3)" --expire-time=5000
        ;;
    *"Close Overlay"*)
        hyprctl dispatch killactive
        ;;
esac
