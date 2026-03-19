#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  omni-colors — EVE-PRIME Color Engine                        ║
# ║  Extracts a 6-color palette from the active wallpaper        ║
# ║  Fires ONCE per wallpaper change — never during playback     ║
# ║  Propagates colors to: Hyprland borders, Waybar, Mako        ║
# ╚══════════════════════════════════════════════════════════════╝

LAST_WALL="/home/omniking/.config/hypr/last-wallpaper"
COLORS_FILE="/home/omniking/.config/hypr/colors.conf"
FRAME_TMP="/tmp/omni_wall_frame.png"
LOCK_FILE="/tmp/omni_colors.lock"

# ── Fallback palette (Nord-inspired) used if extraction fails ──
FALLBACK_PRIMARY="88c0d0"
FALLBACK_SECONDARY="b48ead"
FALLBACK_ACCENT="a3be8c"
FALLBACK_BG="1a1a2e"
FALLBACK_FG="e0e0f0"
FALLBACK_INACTIVE="2e3440"

# ═══════════════════════════════════════════════════════════════
# LOCK — Prevent double-firing during wallpaper switch
# ═══════════════════════════════════════════════════════════════
acquire_lock() {
    if [[ -f "$LOCK_FILE" ]]; then
        local pid
        pid=$(cat "$LOCK_FILE" 2>/dev/null)
        if kill -0 "$pid" 2>/dev/null; then
            exit 0
        fi
    fi
    echo $$ > "$LOCK_FILE"
}

release_lock() {
    rm -f "$LOCK_FILE"
}

trap release_lock EXIT

# ═══════════════════════════════════════════════════════════════
# EXTRACT — Grab frame from video
# ═══════════════════════════════════════════════════════════════
extract_frame() {
    local video="$1"

    [[ ! -f "$video" ]] && return 1

    /usr/bin/ffmpeg -y \
        -ss 00:00:02 \
        -i "$video" \
        -frames:v 1 \
        -update 1 \
        -q:v 2 \
        "$FRAME_TMP" \
        >/dev/null 2>&1

    [[ -f "$FRAME_TMP" ]] && return 0 || return 1
}

# ═══════════════════════════════════════════════════════════════
# PALETTE — Extract dominant colors using ImageMagick
# ═══════════════════════════════════════════════════════════════
extract_palette() {
    local frame="$1"

    /usr/bin/magick "$frame" \
        -resize 150x150! \
        +dither \
        -colors 6 \
        txt:- 2>/dev/null | \
    grep -oP '#[0-9A-Fa-f]{6}' | \
    sort -u | \
    head -6 | \
    sed 's/#//'
}

# ═══════════════════════════════════════════════════════════════
# SORT — Assign colors by luminance to roles
# ═══════════════════════════════════════════════════════════════
assign_colors() {
    local colors=("$@")

    # Pad with fallbacks if fewer than 6 colors extracted
    while [[ ${#colors[@]} -lt 6 ]]; do
        colors+=("$FALLBACK_FG")
    done

    # Sort by luminance — darkest to brightest
    local sorted
    sorted=$(for c in "${colors[@]}"; do
        r=$((16#${c:0:2}))
        g=$((16#${c:2:2}))
        b=$((16#${c:4:2}))
        lum=$(echo "scale=0; ($r * 299 + $g * 587 + $b * 114) / 1000" | bc)
        echo "$lum $c"
    done | sort -n | awk '{print $2}')

    mapfile -t sorted_colors <<< "$sorted"

    COLOR_BG="${sorted_colors[0]:-$FALLBACK_BG}"
    COLOR_INACTIVE="${sorted_colors[1]:-$FALLBACK_INACTIVE}"
    COLOR_ACCENT="${sorted_colors[2]:-$FALLBACK_ACCENT}"
    COLOR_SECONDARY="${sorted_colors[3]:-$FALLBACK_SECONDARY}"
    COLOR_PRIMARY="${sorted_colors[4]:-$FALLBACK_PRIMARY}"
    COLOR_FG="${sorted_colors[5]:-$FALLBACK_FG}"
}

# ═══════════════════════════════════════════════════════════════
# WRITE — Output colors.conf
# ═══════════════════════════════════════════════════════════════
write_colors() {
    cat > "$COLORS_FILE" << EOF
# ╔══════════════════════════════════════════════════════╗
# ║  EVE-PRIME Auto Color Palette                        ║
# ║  Generated: $(date '+%Y-%m-%d %H:%M:%S')
# ║  Source: $(basename "${1:-unknown}")
# ╚══════════════════════════════════════════════════════╝

# Hyprland border colors
\$COLOR_PRIMARY   = rgb(${COLOR_PRIMARY})
\$COLOR_SECONDARY = rgb(${COLOR_SECONDARY})
\$COLOR_ACCENT    = rgb(${COLOR_ACCENT})
\$COLOR_BG        = rgb(${COLOR_BG})
\$COLOR_FG        = rgb(${COLOR_FG})
\$COLOR_INACTIVE  = rgb(${COLOR_INACTIVE})

# Hex values for Waybar CSS injection
# PRIMARY:   #${COLOR_PRIMARY}
# SECONDARY: #${COLOR_SECONDARY}
# ACCENT:    #${COLOR_ACCENT}
# BG:        #${COLOR_BG}
# FG:        #${COLOR_FG}
# INACTIVE:  #${COLOR_INACTIVE}
EOF
}

# ═══════════════════════════════════════════════════════════════
# APPLY — Push colors live to Hyprland borders
# ═══════════════════════════════════════════════════════════════
apply_hyprland() {
    /usr/bin/hyprctl keyword \
        general:col.active_border \
        "0xff${COLOR_PRIMARY} 0xff${COLOR_SECONDARY} 45deg" \
        >/dev/null 2>&1

    /usr/bin/hyprctl keyword \
        general:col.inactive_border \
        "0xaa${COLOR_INACTIVE}" \
        >/dev/null 2>&1

    /usr/bin/hyprctl keyword \
        decoration:shadow:color \
        "0x55${COLOR_PRIMARY}" \
        >/dev/null 2>&1
}

# ═══════════════════════════════════════════════════════════════
# APPLY — Regenerate Waybar CSS with new colors
# ═══════════════════════════════════════════════════════════════
apply_waybar() {
    local css_template="/home/omniking/.config/waybar/style.template.css"
    local css_top="/home/omniking/.config/waybar/skins/eve-top/style.css"
    local css_bottom="/home/omniking/.config/waybar/skins/eve-bottom/style.css"

    [[ ! -f "$css_template" ]] && return 0

    sed \
        -e "s/VAR_PRIMARY/#${COLOR_PRIMARY}/g" \
        -e "s/VAR_SECONDARY/#${COLOR_SECONDARY}/g" \
        -e "s/VAR_ACCENT/#${COLOR_ACCENT}/g" \
        -e "s/VAR_BG/#${COLOR_BG}/g" \
        -e "s/VAR_FG/#${COLOR_FG}/g" \
        -e "s/VAR_INACTIVE/#${COLOR_INACTIVE}/g" \
        "$css_template" > "$css_top"

    cp "$css_top" "$css_bottom"

    pkill -SIGUSR2 waybar 2>/dev/null
}

# ═══════════════════════════════════════════════════════════════
# APPLY — Update Mako notification colors
# ═══════════════════════════════════════════════════════════════
apply_mako() {
    local mako_conf="/home/omniking/.config/mako/config"

    [[ ! -f "$mako_conf" ]] && return 0

    sed -i \
        -e "s/^border-color=.*/border-color=#${COLOR_PRIMARY}ff/" \
        -e "s/^background-color=.*/background-color=#${COLOR_BG}ee/" \
        -e "s/^text-color=.*/text-color=#${COLOR_FG}ff/" \
        "$mako_conf"

    /usr/bin/makoctl reload 2>/dev/null
}

# ═══════════════════════════════════════════════════════════════
# APPLY — Regenerate Cava color theme with new colors
# ═══════════════════════════════════════════════════════════════
apply_cava() {
    local cava_template="/home/omniking/.config/cava/themes/eve-prime"
    local cava_config="/home/omniking/.config/cava/config"

    [[ ! -f "$cava_template" ]] && return 0
    [[ ! -f "$cava_config" ]] && return 0

     local cava_base
    cava_base=$(grep -v "^\[color\]\|^background\|^foreground\|^gradient" "$cava_config")

    local color_block
    color_block=$(sed \
        -e "s/VAR_PRIMARY/#${COLOR_PRIMARY}/g" \
        -e "s/VAR_SECONDARY/#${COLOR_SECONDARY}/g" \
        -e "s/VAR_ACCENT/#${COLOR_ACCENT}/g" \
        -e "s/VAR_BG/#${COLOR_BG}/g" \
        -e "s/VAR_FG/#${COLOR_FG}/g" \
        -e "s/VAR_INACTIVE/#${COLOR_INACTIVE}/g" \
        "$cava_template")

    printf "%s\n\n%s\n" "$cava_base" "$color_block" > "$cava_config"

    pkill -SIGUSR2 cava 2>/dev/null
}

# ═══════════════════════════════════════════════════════════════
# UPDATE — Sync hyprlock wallpaper with current wall
# ═══════════════════════════════════════════════════════════════
update_hyprlock() {
    bash "$HOME/.config/hypr/scripts/update-hyprlock.sh" 2>/dev/null
}

# ═══════════════════════════════════════════════════════════════
# APPLY — Regenerate Wofi launcher CSS with new colors
# ═══════════════════════════════════════════════════════════════
apply_wofi() {
    local template="$HOME/.config/wofi/style.template.css"
    local output="$HOME/.config/wofi/style.css"

    [[ ! -f "$template" ]] && return 0

    sed \
        -e "s/VAR_PRIMARY/#${COLOR_PRIMARY}/g" \
        -e "s/VAR_SECONDARY/#${COLOR_SECONDARY}/g" \
        -e "s/VAR_FG/#${COLOR_FG}/g" \
        -e "s/VAR_INACTIVE/#${COLOR_INACTIVE}/g" \
        "$template" > "$output"
}

# ═══════════════════════════════════════════════════════════════
# APPLY — Regenerate Swaync notification CSS with new colors
# CSS takes effect on next swaync launch — never restart daemon
# ═══════════════════════════════════════════════════════════════
apply_swaync() {
    local template="$HOME/.config/swaync/style.template.css"
    local output="$HOME/.config/swaync/style.css"

    [[ ! -f "$template" ]] && return 0

    sed \
        -e "s/VAR_PRIMARY/#${COLOR_PRIMARY}/g" \
        -e "s/VAR_SECONDARY/#${COLOR_SECONDARY}/g" \
        -e "s/VAR_FG/#${COLOR_FG}/g" \
        -e "s/VAR_INACTIVE/#${COLOR_INACTIVE}/g" \
        "$template" > "$output"
}

# ═══════════════════════════════════════════════════════════════
# APPLY — Regenerate Kitty tab bar colors with new palette
# No daemon restart — kitty reads fresh config on next open
# ═══════════════════════════════════════════════════════════════
apply_kitty() {
    local template="$HOME/.config/kitty/kitty.template.conf"
    local output="$HOME/.config/kitty/kitty.conf"

    [[ ! -f "$template" ]] && return 0

    sed \
        -e "s/VAR_PRIMARY/#${COLOR_PRIMARY}/g" \
        -e "s/VAR_INACTIVE/#${COLOR_INACTIVE}/g" \
        "$template" > "$output"
}

# ═══════════════════════════════════════════════════════════════
# APPLY — Regenerate Rofi style with new colors
# ═══════════════════════════════════════════════════════════════
apply_rofi() {
    local rofi_style="/home/omniking/.config/rofi/skins/eve-prime/style.rasi"

    [[ ! -f "$rofi_style" ]] && return 0

    sed -i \
        -e "s|VAR_PRIMARY;|#${COLOR_PRIMARY};|g" \
        -e "s|VAR_SECONDARY;|#${COLOR_SECONDARY};|g" \
        -e "s|VAR_ACCENT;|#${COLOR_ACCENT};|g" \
        -e "s|VAR_BG;|#${COLOR_BG};|g" \
        -e "s|VAR_FG;|#${COLOR_FG};|g" \
        -e "s|VAR_INACTIVE;|#${COLOR_INACTIVE};|g" \
        "$rofi_style"
}

# ═══════════════════════════════════════════════════════════════
# NOTIFY
# ═══════════════════════════════════════════════════════════════
notify_palette() {
    /usr/bin/notify-send \
        "EVE-PRIME Color Engine" \
        "🎨 Palette locked\n● #${COLOR_PRIMARY}\n● #${COLOR_SECONDARY}\n● #${COLOR_ACCENT}" \
        --expire-time=3000 \
        2>/dev/null
}

# ═══════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════
main() {
    acquire_lock

    local video="${1:-}"
    if [[ -z "$video" && -f "$LAST_WALL" ]]; then
        video=$(cat "$LAST_WALL")
    fi

    if [[ -z "$video" || ! -f "$video" ]]; then
        COLOR_PRIMARY="$FALLBACK_PRIMARY"
        COLOR_SECONDARY="$FALLBACK_SECONDARY"
        COLOR_ACCENT="$FALLBACK_ACCENT"
        COLOR_BG="$FALLBACK_BG"
        COLOR_FG="$FALLBACK_FG"
        COLOR_INACTIVE="$FALLBACK_INACTIVE"
    else
        if extract_frame "$video"; then
            mapfile -t raw_colors <<< "$(extract_palette "$FRAME_TMP")"
            if [[ ${#raw_colors[@]} -ge 3 ]]; then
                assign_colors "${raw_colors[@]}"
            else
                COLOR_PRIMARY="$FALLBACK_PRIMARY"
                COLOR_SECONDARY="$FALLBACK_SECONDARY"
                COLOR_ACCENT="$FALLBACK_ACCENT"
                COLOR_BG="$FALLBACK_BG"
                COLOR_FG="$FALLBACK_FG"
                COLOR_INACTIVE="$FALLBACK_INACTIVE"
            fi
        else
            COLOR_PRIMARY="$FALLBACK_PRIMARY"
            COLOR_SECONDARY="$FALLBACK_SECONDARY"
            COLOR_ACCENT="$FALLBACK_ACCENT"
            COLOR_BG="$FALLBACK_BG"
            COLOR_FG="$FALLBACK_FG"
            COLOR_INACTIVE="$FALLBACK_INACTIVE"
        fi
    fi

    write_colors "$video"
    # Keep themes/colors.conf in sync — hyprland.conf sources this on reload
    cp "$COLORS_FILE" "$HOME/.config/hypr/themes/colors.conf"
    apply_hyprland
    apply_waybar
    apply_mako
    apply_cava
    update_hyprlock
    apply_rofi
    apply_wofi
    apply_swaync
    apply_kitty
    notify_palette

    rm -f "$FRAME_TMP"
    release_lock
}

main "$@"
