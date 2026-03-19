#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  navbar-hover — EVE-PRIME Dock Hover Daemon                  ║
# ║  Top edge (Y < 5)       → show bars (80ms confirm)           ║
# ║  Bottom edge (Y > 1035) → show bars (80ms confirm + gap seq) ║
# ║  Middle (Y 40–1000)     → hide bars                          ║
# ║  True fullscreen        → force hide always                  ║
# ║  Both bars share one waybar PID — signalled together         ║
# ╚══════════════════════════════════════════════════════════════╝

TOP_SHOW=5        # Y < 5    → top edge show zone
TOP_HIDE=40       # Y > 40   → start of middle hide zone
BOT_SHOW=1035     # Y > 1035 → bottom edge show zone
BOT_HIDE=1000     # Y < 1000 → end of middle hide zone
SHOW_DELAY=0.08   # 80ms: cursor must stay in zone or show is cancelled
POLL_INTERVAL=0.1 # 100ms poll — fast enough to feel immediate

# Check if the active window is in true fullscreen (mode 2)
is_fullscreen() {
    local fs
    fs=$(hyprctl activewindow -j 2>/dev/null | python3 -c "
import json, sys
try:
    w = json.load(sys.stdin)
    print(w.get('fullscreen', 0))
except:
    print(0)
" 2>/dev/null)
    [[ "$fs" == "2" ]]
}

ensure_waybar() {
    pgrep -x waybar > /dev/null || (bash ~/.config/hypr/scripts/waybar-launch.sh & sleep 1)
}

BARS_STATE="hidden"

# Top bar: show immediately — no window reflow on top edge
show_top_bar() {
    [[ "$BARS_STATE" == "shown" ]] && return
    ensure_waybar
    WAYBAR_PID=$(pgrep -x waybar)
    kill -SIGUSR2 "$WAYBAR_PID" 2>/dev/null
    BARS_STATE="shown"
}

# Bottom bar: show bar, let exclusive zone handle window repositioning
show_bottom_bar() {
    [[ "$BARS_STATE" == "shown" ]] && return
    ensure_waybar
    WAYBAR_PID=$(pgrep -x waybar)
    kill -SIGUSR2 "$WAYBAR_PID" 2>/dev/null
    sleep 0.05
    BARS_STATE="shown"
}

hide_bars() {
    [[ "$BARS_STATE" == "hidden" ]] && return
    WAYBAR_PID=$(pgrep -x waybar)
    kill -SIGUSR1 "$WAYBAR_PID" 2>/dev/null
    BARS_STATE="hidden"
}

# Startup: assume hidden — avoids sending SIGUSR1 into caller's process tree
BARS_STATE="hidden"

while sleep $POLL_INTERVAL; do
    # Fullscreen always wins — force hide, bypass state guard
    if is_fullscreen; then
        WAYBAR_PID=$(pgrep -x waybar)
        kill -SIGUSR1 "$WAYBAR_PID" 2>/dev/null
        BARS_STATE="hidden"
        continue
    fi

    CURSOR_Y=$(hyprctl cursorpos 2>/dev/null | awk -F'[, ]+' '{print int($2)}')
    [[ -z "$CURSOR_Y" ]] && continue

    if (( CURSOR_Y < TOP_SHOW )); then
        # Top edge — wait 80ms, recheck: cancel if cursor moved away
        sleep $SHOW_DELAY
        CONFIRM_Y=$(hyprctl cursorpos 2>/dev/null | awk -F'[, ]+' '{print int($2)}')
        [[ -n "$CONFIRM_Y" ]] && (( CONFIRM_Y < TOP_SHOW )) && show_top_bar

    elif (( CURSOR_Y > BOT_SHOW )); then
        # Bottom edge — wait 80ms, recheck: cancel if cursor moved away
        sleep $SHOW_DELAY
        CONFIRM_Y=$(hyprctl cursorpos 2>/dev/null | awk -F'[, ]+' '{print int($2)}')
        [[ -n "$CONFIRM_Y" ]] && (( CONFIRM_Y > BOT_SHOW )) && show_bottom_bar

    elif (( CURSOR_Y > TOP_HIDE && CURSOR_Y < BOT_HIDE )); then
        # Middle zone — hide both bars
        hide_bars
    fi
done
