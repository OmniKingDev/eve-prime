#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  EVE-PRIME — Audio Info Popup                               ║
# ║  Shows current audio device and volume info via notify-send ║
# ╚══════════════════════════════════════════════════════════════╝

SINK=$(wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep "node.description" | cut -d'"' -f2 | head -1)
VOL_RAW=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
VOL=$(echo "$VOL_RAW" | awk '{printf "%d", $2 * 100}')
MUTED=$(echo "$VOL_RAW" | grep -c "MUTED" || true)

SOURCE=$(wpctl inspect @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep "node.description" | cut -d'"' -f2 | head -1)

if [ "$MUTED" -gt 0 ]; then
    VOL_STR="󰖁  Muted"
else
    VOL_STR="󰕾  ${VOL}%"
fi

notify-send "󰓃  Audio" \
    "Output: ${SINK:-default}\n${VOL_STR}\nInput: ${SOURCE:-default}" \
    --expire-time=4000 \
    2>/dev/null
