#!/bin/bash
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print int($2+$4)}')
TEMP=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -n | tail -1)
TEMP=$((TEMP/1000))
if   [ "$TEMP" -ge 80 ]; then CLASS="critical"
elif [ "$TEMP" -ge 65 ]; then CLASS="warning"
else CLASS="normal"
fi
echo "{\"text\": \"󱄑 ${CPU}% ${TEMP}°\", \"class\": \"$CLASS\", \"tooltip\": \"CPU: ${CPU}% | Temp: ${TEMP}°C\"}"
