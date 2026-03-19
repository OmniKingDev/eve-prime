#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  EVE-PRIME — Network Info Popup                             ║
# ║  Shows current connection status via notify-send            ║
# ╚══════════════════════════════════════════════════════════════╝

WIFI=$(iwgetid -r 2>/dev/null)
IP=$(ip route get 1.1.1.1 2>/dev/null | awk 'NR==1{for(i=1;i<=NF;i++) if($i=="src") {print $(i+1); exit}}')
ETH=$(ip link show | awk -F': ' '/^[0-9]+: (en|eth)/{print $2}' | head -1)

if [ -n "$WIFI" ]; then
    SIGNAL=$(awk 'NR==3{printf "%d", $3*10/7}' /proc/net/wireless 2>/dev/null)
    MSG="󰤨  WiFi: ${WIFI}\nIP: ${IP:-unknown}\nSignal: ${SIGNAL:-?}%"
elif [ -n "$ETH" ]; then
    MSG="󰈀  Ethernet: ${ETH}\nIP: ${IP:-unknown}"
else
    MSG="󰤭  No network connection"
fi

notify-send "󰤨  Network" "$MSG" --expire-time=4000 2>/dev/null
