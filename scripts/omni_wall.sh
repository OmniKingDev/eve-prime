#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  omni-wall — EVE-PRIME Wallpaper Picker                      ║
# ║  Scans ~/Videos/Wallpapers/, shows wofi picker,              ║
# ║  switches mpvpaper live via IPC socket                       ║
# ║  Remembers last choice across reboots                        ║
# ║  Color engine hook — fires omni_colors.sh on every switch    ║
# ║                                                              ║
# ║  GPU BALANCE MODE — vaapi pipeline                           ║
# ║  GPU decodes all frames, CPU coordinates timing buffer       ║
# ║  = extreme graphics + zero latency + living OS feel          ║
# ╚══════════════════════════════════════════════════════════════╝

WALLPAPER_DIR="/home/omniking/Videos/Wallpapers"
SOCKET="/tmp/mpvpaper.sock"
LAST_WALL="/home/omniking/.config/hypr/last-wallpaper"
WOFI_STYLE="/home/omniking/.config/wofi/wallpaper-picker.css"
COLOR_ENGINE="/home/omniking/.config/hypr/scripts/omni_colors.sh"

# ═══════════════════════════════════════════════════════════════
# MPV OPTIONS — Balanced GPU/CPU Pipeline
# ═══════════════════════════════════════════════════════════════
MPV_OPTS="no-audio \
--loop-file=inf \
--hwdec=vaapi \
--vo=gpu \
--gpu-api=vulkan \
--video-sync=audio \
--demuxer-max-bytes=128M \
--cache=yes \
--vd-lavc-threads=1 \
--profile=fast \
--input-ipc-server=${SOCKET}"

# -----------------------------------------------
# Clean display name — strips ugly hash prefixes
# -----------------------------------------------
clean_name() {
    local filename="$1"
    local name="${filename%.*}"
    name=$(echo "$name" | sed 's/^[A-Za-z0-9_-]\{8,\}-//')
    name=$(echo "$name" | tr '_' ' ')
    name=$(echo "$name" | sed 's/ [0-9] prob[0-9].*//I')
    name=$(echo "$name" | sed 's/ [0-9] hyp[0-9].*//I')
    name=$(echo "$name" | sed 's/ Prob[0-9].*//I')
    name=$(echo "$name" | sed 's/^ //;s/ $//')
    echo "$name"
}

# -----------------------------------------------
# Build wofi list
# -----------------------------------------------
build_list() {
    find "$WALLPAPER_DIR" -maxdepth 1 -name "*.mp4" | sort | while read -r filepath; do
        filename=$(basename "$filepath")
        display=$(clean_name "$filename")
        echo "$display|$filepath"
    done
}

# -----------------------------------------------
# Send command to mpvpaper IPC socket
# -----------------------------------------------
mpv_cmd() {
    local json="$1"
    if [[ -S "$SOCKET" ]]; then
        echo "$json" | /usr/bin/socat - "UNIX-CONNECT:${SOCKET}" >/dev/null 2>&1
    fi
}

# -----------------------------------------------
# Launch mpvpaper with balanced pipeline
# -----------------------------------------------
launch_mpvpaper() {
    local filepath="$1"
    /usr/bin/pkill -9 mpvpaper 2>/dev/null
    sleep 0.4
    rm -f "$SOCKET"

    /usr/local/bin/mpvpaper -o "$MPV_OPTS" '*' "$filepath" > /dev/null 2>&1 &

    # Wait for socket to come alive before returning
    local retries=0
    while [[ ! -S "$SOCKET" && $retries -lt 20 ]]; do
        sleep 0.1
        ((retries++))
    done
}

# -----------------------------------------------
# Switch wallpaper live
# -----------------------------------------------
switch_wallpaper() {
    local filepath="$1"

    if [[ ! -f "$filepath" ]]; then
        /usr/bin/notify-send "omni-wall" \
            "File not found: $(basename "$filepath")" \
            --urgency=critical
        return 1
    fi

    # Try live IPC switch first — no restart needed
    if [[ -S "$SOCKET" ]]; then
        mpv_cmd "{\"command\":[\"loadfile\",\"$filepath\",\"replace\"]}"
        sleep 0.3
        mpv_cmd '{"command":["set_property","pause",false]}'
        mpv_cmd '{"command":["set_property","loop-file","inf"]}'
        /usr/bin/notify-send "omni-wall" \
            "▶  $(basename "$filepath" .mp4)" \
            --expire-time=2000

        # Save last choice for restore on reboot
        echo "$filepath" > "$LAST_WALL"

        # Fire color engine — runs in background, won't block switch
        [[ -x "$COLOR_ENGINE" ]] && bash "$COLOR_ENGINE" "$filepath" &

    else
        # IPC not available — full balanced pipeline restart
        launch_mpvpaper "$filepath"
        /usr/bin/notify-send "omni-wall" \
            "⚡ Pipeline Restarted: $(basename "$filepath" .mp4)" \
            --expire-time=2000

        # Save last choice for restore on reboot
        echo "$filepath" > "$LAST_WALL"

        # Fire color engine — runs in background, won't block switch
        [[ -x "$COLOR_ENGINE" ]] && bash "$COLOR_ENGINE" "$filepath" &
    fi
}

# -----------------------------------------------
# Show wofi picker
# -----------------------------------------------
show_picker() {
    local list
    list=$(build_list)

    if [[ -z "$list" ]]; then
        /usr/bin/notify-send "omni-wall" \
            "No wallpapers found in $WALLPAPER_DIR" \
            --urgency=critical
        return 1
    fi

    local selected
    selected=$(echo "$list" | cut -d'|' -f1 | /usr/bin/wofi \
        --dmenu \
        --prompt "  Wallpaper" \
        --width 500 \
        --height 600 \
        --style "$WOFI_STYLE" \
        --cache-file /dev/null \
        --no-actions \
        --insensitive)

    [[ -z "$selected" ]] && return 0

    local filepath
    filepath=$(echo "$list" | grep "^${selected}|" | cut -d'|' -f2 | head -1)

    if [[ -z "$filepath" ]]; then
        filepath=$(echo "$list" | grep -i "$(echo "$selected" | cut -c1-10)" \
            | cut -d'|' -f2 | head -1)
    fi

    [[ -n "$filepath" ]] && switch_wallpaper "$filepath"
}

# -----------------------------------------------
# MAIN
# -----------------------------------------------
case "${1:-pick}" in
    pick)
        show_picker
        ;;
    switch)
        switch_wallpaper "$2"
        ;;
    restore)
        if [[ -f "$LAST_WALL" ]]; then
            filepath=$(cat "$LAST_WALL")
            launch_mpvpaper "$filepath"
            /usr/bin/notify-send "omni-wall" \
                "▶ Restored: $(basename "$filepath" .mp4)" \
                --expire-time=2000
            # Fire color engine on restore too
            [[ -x "$COLOR_ENGINE" ]] && bash "$COLOR_ENGINE" "$filepath" &
        fi
        ;;
    list)
        build_list | cut -d'|' -f1
        ;;
    restart)
        if [[ -f "$LAST_WALL" ]]; then
            filepath=$(cat "$LAST_WALL")
            launch_mpvpaper "$filepath"
            /usr/bin/notify-send "omni-wall" \
                "⚡ Pipeline Hard Reset: $(basename "$filepath" .mp4)" \
                --expire-time=2000
            # Fire color engine on restart too
            [[ -x "$COLOR_ENGINE" ]] && bash "$COLOR_ENGINE" "$filepath" &
        fi
        ;;
    random)
        mapfile -t files < <(find "$WALLPAPER_DIR" -maxdepth 1 -name "*.mp4" | sort)
        if [[ ${#files[@]} -gt 0 ]]; then
            filepath="${files[$RANDOM % ${#files[@]}]}"
            switch_wallpaper "$filepath"
        fi
        ;;
    next)
        mapfile -t files < <(find "$WALLPAPER_DIR" -maxdepth 1 -name "*.mp4" | sort)
        if [[ ${#files[@]} -eq 0 ]]; then exit 0; fi
        next_idx=0
        if [[ -f "$LAST_WALL" ]]; then
            current=$(cat "$LAST_WALL")
            for i in "${!files[@]}"; do
                if [[ "${files[$i]}" == "$current" ]]; then
                    next_idx=$(( (i + 1) % ${#files[@]} ))
                    break
                fi
            done
        fi
        switch_wallpaper "${files[$next_idx]}"
        ;;
    *)
        echo "Usage: omni-wall [pick|switch <file>|restore|restart|random|next|list]"
        ;;
esac
