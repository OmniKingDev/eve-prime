#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  EVE-PRIME — SPECTRUM PICKER                                ║
# ║  Live wallpaper selector via wofi + mpvpaper                ║
# ║  Triggers heartbeat/pywal color pipeline on switch          ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

# ═══════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════
readonly VIDEO_DIR="${HOME}/Videos/Hidamari"
readonly HEARTBEAT="${HOME}/.config/hypr/scripts/heartbeat.sh"
readonly MPVPAPER_FLAGS="--loop=inf --no-audio --no-osc --no-input-default-bindings --panscan=1.0 --hwdec=vaapi-copy --vo=gpu-next --keepaspect=no"
readonly WOFI_PROMPT="Spectrum:"

# ═══════════════════════════════════════════
# SCAN VIDEOS
# ═══════════════════════════════════════════
_get_videos() {
    local -a videos=()
    while IFS= read -r -d '' file; do
        videos+=("$file")
    done < <(find "$VIDEO_DIR" -maxdepth 2 \
        \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" \) \
        -print0 2>/dev/null | sort -z)

    if [[ ${#videos[@]} -eq 0 ]]; then
        notify-send "EVE-PRIME" "No videos found in ${VIDEO_DIR}" \
            --icon=dialog-warning 2>/dev/null || true
        exit 0
    fi

    printf '%s\n' "${videos[@]}"
}

# ═══════════════════════════════════════════
# WOFI PICKER
# ═══════════════════════════════════════════
_pick_video() {
    local videos_list="$1"
    local selection

    selection=$(echo "$videos_list" \
        | awk -F'/' '{print $NF}' \
        | sed 's/\.[^.]*$//' \
        | wofi \
            --show dmenu \
            --prompt "$WOFI_PROMPT" \
            --insensitive \
            --allow-markup \
            --width 500 \
            --height 350 \
            --no-actions \
        2>/dev/null) || exit 0

    [[ -z "$selection" ]] && exit 0

    local full_path=""

    # Match filename (without extension) back to full path
    while IFS= read -r f; do
        local base
        base="$(basename "$f")"
        base="${base%.*}"
        if [[ "$base" == "$selection" ]]; then
            full_path="$f"
            break
        fi
    done <<< "$videos_list"

    if [[ -z "$full_path" ]]; then
        notify-send "EVE-PRIME" "Could not resolve video: ${selection}" \
            --icon=dialog-error 2>/dev/null || true
        exit 1
    fi

    echo "$full_path"
}

# ═══════════════════════════════════════════
# SWITCH BACKGROUND
# ═══════════════════════════════════════════
_switch_background() {
    local video="$1"

    pkill -x mpvpaper 2>/dev/null && sleep 0.3

    nohup mpvpaper \
        -o "$MPVPAPER_FLAGS" \
        "*" "$video" \
        >/dev/null 2>&1 &
    disown

    sleep 1.5

    if [[ -x "$HEARTBEAT" ]]; then
        "$HEARTBEAT" "$video"
    else
        notify-send "EVE-PRIME" "heartbeat.sh not found: ${HEARTBEAT}" \
            --icon=dialog-warning 2>/dev/null || true
    fi
}

# ═══════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════
main() {
    local videos
    videos=$(_get_videos)

    local selected
    selected=$(_pick_video "$videos")

    _switch_background "$selected"

    notify-send "EVE-PRIME" "Spectrum locked: $(basename "$selected")" \
        --icon=preferences-desktop-wallpaper 2>/dev/null || true
}

main "$@"
