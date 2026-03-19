#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  EVE-PRIME — Update Hyprlock Skin                            ║
# ║  Reads last-wallpaper — preserves screenshot path guard      ║
# ║  Injects extracted palette into clock, border, date colors   ║
# ║  Called by omni_colors.sh on every wallpaper change          ║
# ╚══════════════════════════════════════════════════════════════╝

LAST_WALL="$HOME/.config/hypr/last-wallpaper"
COLORS_FILE="$HOME/.config/hypr/colors.conf"
HYPRLOCK_CONF="$HOME/.config/hypr/hyprlock.conf"

[[ ! -f "$LAST_WALL" ]] && exit 0

WALLPAPER=$(cat "$LAST_WALL")

[[ ! -f "$WALLPAPER" ]] && exit 0

# ── Resolve active skin path ──────────────────────────────────
TARGET_SKIN=$(grep "^source" "$HYPRLOCK_CONF" 2>/dev/null | cut -d '=' -f2 | tr -d ' ' | head -n 1)

# Fall back to hyprlock.conf itself if no skin sourced
[[ -z "$TARGET_SKIN" || ! -f "$TARGET_SKIN" ]] && TARGET_SKIN="$HYPRLOCK_CONF"

# ── Screenshot path guard (Phase 7) ──────────────────────────
# Never overwrite 'path = screenshot' — lock screen uses blurred desktop
CURRENT_PATH=$(sed -n '/^background {/,/^}/p' "$TARGET_SKIN" | grep -oP '(?<=path = ).*' | head -1 | tr -d ' ')
if [[ "$CURRENT_PATH" != "screenshot" ]]; then
    sed -i "/^background {/,/^}/{s|^[[:space:]]*path =.*|    path = $WALLPAPER|}" "$TARGET_SKIN"
fi

# ── Color injection ───────────────────────────────────────────
# Bail cleanly if colors.conf missing — do not corrupt skin
[[ ! -f "$COLORS_FILE" ]] && exit 0

parse_hex() {
    grep "^# ${1}:" "$COLORS_FILE" | grep -oP '#[0-9A-Fa-f]{6}' | head -1 | tr -d '#'
}

PRIMARY=$(parse_hex "PRIMARY")
SECONDARY=$(parse_hex "SECONDARY")

[[ -z "$PRIMARY" || -z "$SECONDARY" ]] && exit 0

# Midtone between primary and secondary for date label
mid_channel() {
    printf "%02X" $(( (16#${1:$2:2} + 16#${3:$2:2}) / 2 ))
}
MIDTONE="$(mid_channel $PRIMARY 0 $SECONDARY)$(mid_channel $PRIMARY 2 $SECONDARY)$(mid_channel $PRIMARY 4 $SECONDARY)"

# Darkened primary (20% brightness) for password inner background
dark_channel() {
    printf "%02X" $(( 16#${1:$2:2} * 20 / 100 ))
}
DARK="$(dark_channel $PRIMARY 0)$(dark_channel $PRIMARY 2)$(dark_channel $PRIMARY 4)"

# ── Apply colors to skin sections via block-scoped sed ────────

# Clock → PRIMARY (full opacity)
sed -i "/^# ── CLOCK/,/^}/{s/    color = rgba([0-9A-Fa-f]\{6\}\(ff\|cc\|99\|aa\))/    color = rgba(${PRIMARY}ff)/}" "$TARGET_SKIN"

# Date → MIDTONE (medium opacity)
sed -i "/^# ── DATE/,/^}/{s/    color = rgba([0-9A-Fa-f]\{6\}\(ff\|cc\|99\|aa\))/    color = rgba(${MIDTONE}cc)/}" "$TARGET_SKIN"

# Identity → SECONDARY (medium opacity)
sed -i "/^# ── IDENTITY/,/^}/{s/    color = rgba([0-9A-Fa-f]\{6\}\(ff\|cc\|99\|aa\))/    color = rgba(${SECONDARY}cc)/}" "$TARGET_SKIN"

# Password field: outer border → SECONDARY, check → PRIMARY, inner bg → DARK
sed -i "/^# ── PASSWORD FIELD/,/^}/{s/    outer_color = rgba([0-9A-Fa-f]\{6\}\(ff\|cc\|99\|aa\))/    outer_color = rgba(${SECONDARY}cc)/}" "$TARGET_SKIN"
sed -i "/^# ── PASSWORD FIELD/,/^}/{s/    check_color = rgba([0-9A-Fa-f]\{6\}\(ff\|cc\|99\|aa\))/    check_color = rgba(${PRIMARY}ff)/}" "$TARGET_SKIN"
sed -i "/^# ── PASSWORD FIELD/,/^}/{s/    inner_color = rgba([0-9A-Fa-f]\{6\}\(ff\|cc\|99\|aa\))/    inner_color = rgba(${DARK}99)/}" "$TARGET_SKIN"

# Suspend power button → SECONDARY (matches identity label tone)
sed -i "/^# Suspend/,/^}/{s/    color = rgba([0-9A-Fa-f]\{6\}\(ff\|cc\|99\|aa\))/    color = rgba(${SECONDARY}cc)/}" "$TARGET_SKIN"
