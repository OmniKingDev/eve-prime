#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  EVE-PRIME — Volume/Brightness OSD Popup                    ║
# ║  Usage: osd-popup.sh [volume|brightness]                    ║
# ║  Reads current value internally — no arg needed for value   ║
# ╚══════════════════════════════════════════════════════════════╝

TYPE="$1"  # volume or brightness

case "$TYPE" in
    volume)
        # wpctl get-volume returns "Volume: 0.65" — convert to 0-100
        RAW=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
        MUTED=$(echo "$RAW" | grep -c "MUTED" || true)
        VALUE=$(echo "$RAW" | awk '{printf "%d", $2 * 100}')
        if [ "$MUTED" -gt 0 ]; then
            LABEL="󰖁  Muted"
            VALUE=0
        else
            LABEL="󰕾  Volume: ${VALUE}%"
        fi
        notify-send "$LABEL" \
            --hint "int:value:${VALUE}" \
            --hint "string:synchronous:volume" \
            --expire-time=1500 \
            --icon="audio-volume-medium" \
            2>/dev/null
        ;;
    brightness)
        MAX=$(brightnessctl max 2>/dev/null)
        CUR=$(brightnessctl get 2>/dev/null)
        if [ -n "$MAX" ] && [ "$MAX" -gt 0 ]; then
            VALUE=$(( CUR * 100 / MAX ))
        else
            VALUE=0
        fi
        notify-send "󰃟  Brightness: ${VALUE}%" \
            --hint "int:value:${VALUE}" \
            --hint "string:synchronous:brightness" \
            --expire-time=1500 \
            --icon="display-brightness-symbolic" \
            2>/dev/null
        ;;
    *)
        echo "Usage: osd-popup.sh [volume|brightness]"
        ;;
esac
