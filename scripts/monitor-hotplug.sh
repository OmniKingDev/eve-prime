#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  EVE-PRIME — MONITOR HOTPLUG HANDLER                        ║
# ║  Detects port names dynamically from hyprctl JSON output     ║
# ║  Switches resolution, scale, and restarts mpvpaper          ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

# ═══════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════
readonly TV_MODEL="50S450R"
readonly MONITOR_MODEL="Sceptre F24"
readonly WALLPAPER="/home/omniking/Videos/Hidamari/TRIAL 1.mp4"
readonly MPVPAPER_FLAGS="--loop=inf --no-audio --no-osc --no-input-default-bindings --panscan=1.0 --hwdec=vaapi-copy --vo=gpu-next --keepaspect=no"

# ═══════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════
_restart_mpvpaper() {
    pkill -x mpvpaper 2>/dev/null || true
    sleep 0.5
    nohup mpvpaper -o "$MPVPAPER_FLAGS" "*" "$WALLPAPER" >/dev/null 2>&1 &
    disown
}

# _port_for_model <substring>
# Reads hyprctl monitors -j and returns the port name (e.g. "HDMI-A-1")
# for the first monitor whose description contains the given substring.
_port_for_model() {
    local model="$1" json="$2"
    echo "$json" | python3 -c "
import json, sys
needle = sys.argv[1]
for m in json.load(sys.stdin):
    if needle in m.get('description', ''):
        print(m['name'])
        sys.exit(0)
sys.exit(1)
" "$model" 2>/dev/null || true
}

# ═══════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════
main() {
    sleep 1

    # Fetch live JSON once — port names come from here, not from config
    local monitors_json
    monitors_json=$(hyprctl monitors -j 2>/dev/null || true)

    if [[ -z "$monitors_json" ]] || [[ "$monitors_json" == "[]" ]]; then
        notify-send "EVE-PRIME" "No monitors detected by hyprctl" \
            --icon=dialog-error 2>/dev/null || true
        exit 1
    fi

    local tv_port monitor_port
    tv_port=$(_port_for_model "$TV_MODEL"      "$monitors_json")
    monitor_port=$(_port_for_model "$MONITOR_MODEL" "$monitors_json")

    if [[ -n "$tv_port" ]]; then
        hyprctl keyword monitor "${tv_port}, 3840x2160@59.94, 0x-2160, 1.25"
        _restart_mpvpaper
        notify-send "Display" "TCL 4K on ${tv_port} — 3840x2160@59.94 | Scale 1.25" \
            --icon=display 2>/dev/null || true

    elif [[ -n "$monitor_port" ]]; then
        hyprctl keyword monitor "${monitor_port}, 1920x1080@100, 0x0, 1"
        _restart_mpvpaper
        notify-send "Display" "Sceptre F24 on ${monitor_port} — 1920x1080@100Hz" \
            --icon=display 2>/dev/null || true

    else
        notify-send "EVE-PRIME" "Unknown display connected — no profile matched" \
            --icon=dialog-warning 2>/dev/null || true
    fi
}

main "$@"
