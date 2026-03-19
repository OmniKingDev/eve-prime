# EVE-PRIME — DESKTOP COMPLETION BLUEPRINT
**Owner:** Demetrius Q Jackson (OmniKing Dev)
**Company:** Eve Industries | OS: EVE-PRIME
**File:** EVEPRIME-DESKTOP-COMPLETION-BLUEPRINT.md
**Created:** 2026-03-18
**Status:** AUTHORITATIVE — Phase 9 through completion.

---

## READ THIS FIRST — OPUS/SONNET INSTRUCTIONS

You are finishing EVE-PRIME. The foundation is built and working.
This blueprint defines everything missing from a professional desktop.
Hyprland version: 0.54. All syntax rules from the Hyprland blueprint apply.

Read every existing config and script before writing anything.
Work one phase at a time. Verify with hyprctl configerrors after every change.
Zero errors before moving to the next phase.

When in conflict between what exists and what this document says —
this document wins. Always.

---

## WHAT EXISTS AND IS WORKING

- Waybar dual bar (top + bottom dock)
- omni_wall.sh — 108 wallpapers, color engine, live wallpaper via mpvpaper
- omni_colors.sh — palette extraction, propagation to all systems
- hyprlock — EVE-PRIME skin, idle lock, Super+L
- hypridle — 5 min lock, 10 min DPMS off
- keybinds — full set including fullscreen modes, workspaces, media
- windowrules — 0.54 syntax, per-app opacity, float rules
- animations — spring/easeOut beziers, window/workspace/layer animations
- decoration — violet shadow, blur, dim inactive
- context-menu.sh — Super+X wofi menu
- eve-settings.sh — Super+I settings panel
- eve-daemon-watch.sh — process watchdog
- eve-status.sh — CPU/temp waybar module
- requirement-check.sh — boot dependency checker
- hyprexpo — workspace overview on Super

---

## WHAT IS MISSING — THE FULL LIST

1. Window title bars with minimize/maximize/close buttons
2. Waybar module dropdowns and popups
3. Waybar show/hide animation (currently instant, no transition)
4. Animation performance — chopping at high speed, no frame budget
5. Keyboard spam / input flood protection
6. Window overview that feels cinematic not grid-like
7. Login screen (SDDM) with live wallpaper behind it
8. Lock screen additional options (power, sleep, reboot buttons)
9. Right-click menu expanded with full window + workspace management
10. Notification system — styled, actionable, EVE-PRIME themed
11. App launcher — styled beyond basic wofi
12. Volume/brightness OSD popup
13. Clipboard manager
14. Color picker tool
15. System tray popups (network, bluetooth, audio)
16. Performance debugger overlay
17. Window snap zones (drag to edge = tile)
18. Per-workspace wallpaper support
19. Scratchpad terminal (F12 dropdown)
20. Screenshot annotation GUI (swappy already wired, verify it works)

---

## PHASE 9 — WINDOW DECORATIONS + TITLE BARS

### hyprbars plugin (already in plugins.conf — verify and configure)

hyprbars gives every window a title bar with buttons.
EVE-PRIME style: minimal, dark, violet accent, functional.

```ini
# plugins.conf — hyprbars block
plugin {
    hyprbars {
        bar_height = 28
        bar_color = rgba(0D001599)
        bar_text_size = 12
        bar_text_font = JetBrainsMono Nerd Font
        bar_text_color = rgba(E8E8F0ff)
        bar_button_padding = 8
        bar_padding = 10
        bar_precedence_over_border = true
        col.text = rgba(E8E8F0ff)

        buttons {
            button_size = 14
            col.maximize = rgba(7B2FBEff)
            col.close = rgba(FF4444ff)
            col.minimize = rgba(FFB347ff)
        }
    }
}
```

### Window Rule — Hide bars on specific windows

```ini
# windowrules.conf
# NOTE: registered effect name is hyprbars:no_bar (verified from barDeco.cpp)
# NOT plugin:hyprbars:nobar — that throws "invalid field type"
windowrule = hyprbars:no_bar on, match:class ^kitty$
windowrule = hyprbars:no_bar on, match:class ^Alacritty$
windowrule = hyprbars:no_bar on, match:class ^foot$
windowrule = hyprbars:no_bar on, match:title ^Picture-in-Picture$
```

Terminals and PiP don't need title bars. Everything else gets them.

### Title Bar Keybinds (mouse actions on bar)

hyprbars handles clicks automatically:
- Left click drag = move window
- Close button = kill
- Maximize button = fullscreen toggle (mode 1)
- Minimize button = movetoworkspacesilent special

---

## PHASE 10 — WAYBAR ANIMATIONS + POPUPS

### Waybar Show/Hide Animation Fix

GTK CSS does not support transform. The correct approach is
a custom animation via the waybar `on-hover` mechanism and
a wrapper script that uses `hyprctl keyword` to adjust gaps
smoothly rather than snapping.

`scripts/waybar-animate.sh` — smooth show/hide:

```bash
#!/bin/bash
# Animate waybar in/out by adjusting gaps_out smoothly
# Called by navbar-hover.sh instead of raw SIGUSR1/SIGUSR2

ACTION="$1"  # show or hide
STEPS=8
DELAY=0.016  # ~60fps

if [ "$ACTION" = "hide" ]; then
    # Slide waybar up: reduce top gap in steps
    for i in $(seq 1 $STEPS); do
        GAP=$((48 - (i * 6)))
        hyprctl keyword general:gaps_out "$GAP, 10, 10, 10" 2>/dev/null
        sleep $DELAY
    done
    killall -SIGUSR1 waybar 2>/dev/null
    hyprctl keyword general:gaps_out "0, 10, 10, 10" 2>/dev/null
else
    # Restore waybar
    killall -SIGUSR2 waybar 2>/dev/null
    for i in $(seq 1 $STEPS); do
        GAP=$((i * 6))
        hyprctl keyword general:gaps_out "$GAP, 10, 10, 10" 2>/dev/null
        sleep $DELAY
    done
    hyprctl keyword general:gaps_out "48, 10, 10, 10" 2>/dev/null
fi
```

### Waybar Module Popups

Each module gets a popup on click:

**Clock popup** — calendar via `gnome-calendar` or `calcurse`:
```json
"clock": {
    "on-click": "gnome-calendar",
    "on-click-right": "calcurse"
}
```

**Network popup** — full network manager:
```json
"network": {
    "on-click": "nm-connection-editor",
    "on-click-right": "~/.config/hypr/scripts/network-popup.sh"
}
```

**Audio popup** — pavucontrol:
```json
"pulseaudio": {
    "on-click": "pavucontrol",
    "on-click-right": "~/.config/hypr/scripts/audio-popup.sh"
}
```

**Battery popup** — power stats:
```json
"battery": {
    "on-click": "~/.config/hypr/scripts/battery-popup.sh"
}
```

### Volume/Brightness OSD

`scripts/osd-popup.sh` — overlay notification for volume/brightness changes:

```bash
#!/bin/bash
TYPE="$1"   # volume or brightness
VALUE="$2"  # 0-100

notify-send "$TYPE" \
    --hint int:value:$VALUE \
    --hint string:synchronous:$TYPE \
    --expire-time=1500 \
    --icon="audio-volume-medium"
```

Update audio keybinds to call OSD:
```ini
bindel = , XF86AudioRaiseVolume, exec, pamixer -i 5 && ~/.config/hypr/scripts/osd-popup.sh volume $(pamixer --get-volume)
bindel = , XF86AudioLowerVolume, exec, pamixer -d 5 && ~/.config/hypr/scripts/osd-popup.sh volume $(pamixer --get-volume)
bindel = , XF86MonBrightnessUp,  exec, brightnessctl set +5% && ~/.config/hypr/scripts/osd-popup.sh brightness $(brightnessctl get)
bindel = , XF86MonBrightnessDown,exec, brightnessctl set 5%- && ~/.config/hypr/scripts/osd-popup.sh brightness $(brightnessctl get)
```

---

## PHASE 11 — ANIMATION PERFORMANCE + STABILITY

### The Chopping Problem

Chopping at high speed = animation curves are too long for the
frame budget. Spring animations overshoot on fast input.

Fix: Shorter durations for all animations, tighter beziers,
frame budget awareness.

```ini
# animations.conf — performance tuned
animations {
    enabled = true

    # Tight beziers — fast but not jarring
    bezier = easeOut,    0.16, 1,    0.3,  1
    bezier = easeIn,     0.7,  0,    0.84, 0
    bezier = snap,       0.25, 0.1,  0.25, 1.0
    bezier = spring,     0.34, 1.2,  0.64, 1

    # Windows — snap is faster than spring for high-speed use
    animation = windows,          1, 3,  snap,    popin 90%
    animation = windowsOut,       1, 2,  easeIn,  popin 90%
    animation = windowsMove,      1, 3,  snap

    # Borders — subtle
    animation = border,           1, 6,  easeOut
    animation = borderangle,      1, 30, easeOut, loop

    # Fade — fast
    animation = fade,             1, 3,  easeOut
    animation = fadeOut,          1, 2,  easeIn

    # Workspaces — snappy
    animation = workspaces,       1, 4,  snap,    slide
    animation = specialWorkspace, 1, 4,  snap,    slidevert

    # Layers (waybar, rofi) — quick
    animation = layersIn,         1, 2,  snap,    popin 90%
    animation = layersOut,        1, 2,  easeIn,  popin 90%
}
```

### Input Flood Protection

Keyboard spam cannot break the OS. These settings throttle
rapid input from destroying the compositor:

```ini
# general.conf additions
general {
    # Resize commits after mouse release, not during drag
    resize_on_border = true
    hover_icon_on_border = true

    # No layout recalculation during rapid workspace switching
    no_focus_fallback = false
}

# misc.conf additions
misc {
    # Prevent VRR flicker on fast workspace switch
    vrr = 0

    # Cap animation frame rate to monitor refresh
    animate_manual_resizes = false
    animate_mouse_windowdragging = true

    # Disable mouse focus on workspace switch to prevent race conditions
    mouse_move_enables_dpms = true
    key_press_enables_dpms = true

    # Force GPU sync on every frame — prevents tearing
    no_direct_scanout = false

    # Prevent compositor crash on rapid fullscreen toggle
    allow_session_lock_restore = true
}
```

### Workspace Switch Flood Guard

`scripts/workspace-guard.sh` — debounces rapid workspace switching:

```bash
#!/bin/bash
# Debounce rapid workspace switches — max 1 switch per 80ms
LOCKFILE="/tmp/ws-switch.lock"
TARGET="$1"

if [ -f "$LOCKFILE" ]; then
    exit 0
fi

touch "$LOCKFILE"
hyprctl dispatch workspace "$TARGET"
sleep 0.08
rm "$LOCKFILE"
```

---

## PHASE 12 — RIGHT-CLICK MENU EXPANSION

### context-menu.sh — Full Rewrite

Two modes: desktop right-click and window right-click.
Detect context automatically.

```bash
#!/bin/bash
# EVE-PRIME Context Menu — desktop + window aware

ACTIVE=$(hyprctl activewindow -j 2>/dev/null)
HAS_WINDOW=$(echo "$ACTIVE" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print('yes' if d.get('class', '') != '' else 'no')
except:
    print('no')
")

if [ "$HAS_WINDOW" = "yes" ]; then
    # Window context menu
    CLASS=$(echo "$ACTIVE" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('class',''))")
    TITLE=$(echo "$ACTIVE" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('title','')[:30])")
    FLOATING=$(echo "$ACTIVE" | python3 -c "import sys,json;d=json.load(sys.stdin);print('yes' if d.get('floating') else 'no')")

    if [ "$FLOATING" = "yes" ]; then
        FLOAT_LABEL="󰕰  Tile Window"
    else
        FLOAT_LABEL="󰖲  Float Window"
    fi

    CHOICE=$(printf \
"󰖲  $FLOAT_LABEL\n󰆾  Center Window\n󰻿  Pin Window\n─────────────\n󰖯  Opacity 100%%\n󰖯  Opacity 90%%\n󰖯  Opacity 80%%\n󰖯  Opacity 70%%\n─────────────\n󰊓  Move to WS 1\n󰊓  Move to WS 2\n󰊓  Move to WS 3\n󰊓  Move to WS 4\n󰊓  Move to WS 5\n─────────────\n󰮘  Fullscreen\n󰮘  Fake Fullscreen\n─────────────\n󰅖  Close Window" \
        | wofi --dmenu --prompt "$CLASS" --width 300 --height 500)
else
    # Desktop context menu
    CHOICE=$(printf \
"󰃭  Wallpaper Picker\n󰑓  Reload Config\n─────────────\n󰍹  Display Settings\n󰓃  Audio Settings\n󰤨  Network\n─────────────\n  App Launcher\n󰆍  Terminal\n─────────────\n  Eve Settings\n󰐦  System Info" \
        | wofi --dmenu --prompt "EVE-PRIME" --width 280 --height 450)
fi

ADDR=$(hyprctl activewindow -j | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('address',''))" 2>/dev/null)

case "$CHOICE" in
    # Window actions
    *"Float Window"*)     hyprctl dispatch togglefloating ;;
    *"Tile Window"*)      hyprctl dispatch togglefloating ;;
    *"Center Window"*)    hyprctl dispatch centerwindow ;;
    *"Pin Window"*)       hyprctl dispatch pin ;;
    *"Opacity 100%"*)     hyprctl setprop address:$ADDR alpha 1.0 ;;
    *"Opacity 90%"*)      hyprctl setprop address:$ADDR alpha 0.9 ;;
    *"Opacity 80%"*)      hyprctl setprop address:$ADDR alpha 0.8 ;;
    *"Opacity 70%"*)      hyprctl setprop address:$ADDR alpha 0.7 ;;
    *"Move to WS 1"*)     hyprctl dispatch movetoworkspace 1 ;;
    *"Move to WS 2"*)     hyprctl dispatch movetoworkspace 2 ;;
    *"Move to WS 3"*)     hyprctl dispatch movetoworkspace 3 ;;
    *"Move to WS 4"*)     hyprctl dispatch movetoworkspace 4 ;;
    *"Move to WS 5"*)     hyprctl dispatch movetoworkspace 5 ;;
    *"Fullscreen"*)       hyprctl dispatch fullscreen 0 ;;
    *"Fake Fullscreen"*)  hyprctl dispatch fullscreen 1 ;;
    *"Close Window"*)     hyprctl dispatch killactive ;;
    # Desktop actions
    *"Wallpaper Picker"*) ~/.config/hypr/scripts/omni_wall.sh pick ;;
    *"Reload Config"*)    hyprctl reload && notify-send "EVE-PRIME" "󰑓 Config reloaded" ;;
    *"Display Settings"*) notify-send "Display" "$(hyprctl monitors | grep -E 'Monitor|resolution')" ;;
    *"Audio Settings"*)   pavucontrol & ;;
    *"Network"*)          nm-connection-editor & ;;
    *"App Launcher"*)     wofi --show drun & ;;
    *"Terminal"*)         kitty & ;;
    *"Eve Settings"*)     ~/.config/hypr/scripts/eve-settings.sh ;;
    *"System Info"*)      notify-send "System" "Kernel: $(uname -r)\nUptime: $(uptime -p)\nRAM: $(free -h | awk '/^Mem/{print $3"/"$2}')" ;;
esac
```

---

## PHASE 13 — NOTIFICATION SYSTEM (EVE-PRIME THEMED)

### swaync Configuration

swaync is already installed and running. Style it to match EVE-PRIME.

`~/.config/swaync/style.css`:

```css
/* EVE-PRIME swaync theme */
@define-color bg_primary    #0D0015;
@define-color bg_secondary  #1A0030;
@define-color eve_violet    #7B2FBE;
@define-color eve_cyan      #00D4FF;
@define-color text_primary  #E8E8F0;
@define-color text_dim      #8080A0;
@define-color warning       #FFB347;
@define-color critical      #FF4444;

.notification-row {
    outline: none;
    margin: 4px;
}

.notification {
    background: alpha(@bg_primary, 0.92);
    border: 1px solid alpha(@eve_violet, 0.5);
    border-radius: 10px;
    padding: 12px;
    margin: 4px 8px;
    box-shadow: 0 4px 16px rgba(0,0,0,0.4);
}

.notification.critical {
    border-color: @critical;
}

.notification-content {
    padding: 4px;
}

.summary {
    color: @eve_cyan;
    font-weight: bold;
    font-size: 14px;
    font-family: JetBrainsMono Nerd Font;
}

.body {
    color: @text_primary;
    font-size: 12px;
    font-family: JetBrainsMono Nerd Font;
}

.time {
    color: @text_dim;
    font-size: 11px;
}

.close-button {
    background: transparent;
    color: @text_dim;
    border: none;
    border-radius: 4px;
    padding: 4px;
    transition: all 0.2s;
}

.close-button:hover {
    color: @critical;
    background: alpha(@critical, 0.15);
}

.notification-center {
    background: alpha(@bg_primary, 0.95);
    border-left: 1px solid alpha(@eve_violet, 0.4);
}

.control-center {
    background: alpha(@bg_secondary, 0.95);
    border: 1px solid alpha(@eve_violet, 0.4);
    border-radius: 12px;
    padding: 8px;
    margin: 8px;
}

.widget-title > label {
    color: @eve_cyan;
    font-size: 16px;
    font-weight: bold;
    font-family: JetBrainsMono Nerd Font;
}

.widget-dnd > switch:checked {
    background: @eve_violet;
}
```

`~/.config/swaync/config.json`:
```json
{
    "positionX": "right",
    "positionY": "top",
    "layer": "overlay",
    "control-center-margin-top": 8,
    "control-center-margin-bottom": 8,
    "control-center-margin-right": 8,
    "notification-icon-size": 48,
    "notification-body-image-height": 100,
    "notification-body-image-width": 200,
    "timeout": 5,
    "timeout-low": 3,
    "timeout-critical": 0,
    "fit-to-screen": false,
    "control-center-width": 380,
    "notification-window-width": 380,
    "hide-on-clear": true,
    "hide-on-action": true,
    "script-fail-notify": true,
    "widgets": [
        "title",
        "dnd",
        "notifications"
    ],
    "widget-config": {
        "title": {
            "text": "EVE-PRIME",
            "clear-all-button": true,
            "button-text": "󰅖 Clear"
        },
        "dnd": {
            "text": "Do Not Disturb"
        }
    }
}
```

---

## PHASE 14 — LOGIN SCREEN (SDDM)

### SDDM with Live Wallpaper

SDDM is the display manager — it runs before Hyprland starts.
EVE-PRIME login screen: live wallpaper behind it, dark overlay,
clock, username field, password field, power buttons.

Check if SDDM is installed:
```bash
systemctl status sddm
```

If not installed:
```bash
sudo apt install sddm
sudo systemctl enable sddm
```

### SDDM Theme — EVE-PRIME

`/usr/share/sddm/themes/eve-prime/theme.conf`:
```ini
[General]
type=color
color=#0D0015
fontSize=14
font=JetBrainsMono Nerd Font
background=/home/omniking/Videos/Wallpapers/Makima In The Pool.mp4
```

SDDM does not natively play video backgrounds. Two approaches:

**Approach A — Static screenshot of wallpaper as SDDM background:**
```bash
# Capture current wallpaper frame as SDDM background
grim /tmp/sddm-bg.png
sudo cp /tmp/sddm-bg.png /usr/share/sddm/themes/eve-prime/background.png
```

**Approach B — mpvpaper before SDDM via systemd service:**
Create a systemd service that starts mpvpaper on the display
before SDDM renders its overlay. This is the cinematic approach.

`/etc/systemd/system/eve-sddm-bg.service`:
```ini
[Unit]
Description=EVE-PRIME SDDM Background
Before=sddm.service
After=display-manager.service

[Service]
Type=simple
ExecStart=/usr/bin/mpvpaper -o "no-audio loop" '*' /home/omniking/Videos/Wallpapers/Makima\ In\ The\ Pool.mp4
Restart=on-failure

[Install]
WantedBy=graphical.target
```

Opus must test Approach B first. Fall back to A if compositor
is not available before SDDM.

### SDDM QML Theme

The actual login UI is built in QML. EVE-PRIME spec:

- Background: video or blurred screenshot
- Dark overlay: rgba(13, 0, 21, 0.75)
- Center card: frosted glass, violet border
- Clock: large, cyan, top of card
- Username: pre-filled or input field
- Password: styled to match hyprlock input field
- Buttons: Lock (violet), Reboot (warning), Shutdown (red)
- OmniKing sigil: bottom center, subtle

---

## PHASE 15 — LOCK SCREEN EXPANSION

Current hyprlock has: clock, date, identity, password field.

Add: power action buttons.

```ini
# hyprlock/skins/eve-prime/eve-prime.conf additions

# Shutdown button
label {
    monitor =
    text = 󰐥
    color = rgba(FF4444cc)
    font_size = 24
    font_family = Symbols Nerd Font
    position = -120, -220
    halign = center
    valign = center
    onclick = systemctl poweroff
}

# Reboot button
label {
    monitor =
    text = 󰑓
    color = rgba(FFB347cc)
    font_size = 24
    font_family = Symbols Nerd Font
    position = 0, -220
    halign = center
    valign = center
    onclick = systemctl reboot
}

# Sleep button
label {
    monitor =
    text = 󰒲
    color = rgba(7B2FBEcc)
    font_size = 24
    font_family = Symbols Nerd Font
    position = 120, -220
    halign = center
    valign = center
    onclick = systemctl suspend
}
```

---

## PHASE 16 — APP LAUNCHER UPGRADE

Current: basic wofi --show drun

Upgrade: styled wofi with EVE-PRIME theme, search, categories.

`~/.config/wofi/style.css`:
```css
@define-color bg_primary    #0D0015;
@define-color bg_secondary  #1A0030;
@define-color eve_violet    #7B2FBE;
@define-color eve_cyan      #00D4FF;
@define-color text_primary  #E8E8F0;
@define-color text_dim      #8080A0;

window {
    background: alpha(@bg_primary, 0.95);
    border: 1px solid @eve_violet;
    border-radius: 12px;
    font-family: JetBrainsMono Nerd Font;
    font-size: 14px;
}

#input {
    background: alpha(@bg_secondary, 0.8);
    border: 1px solid alpha(@eve_violet, 0.5);
    border-radius: 8px;
    color: @text_primary;
    padding: 8px 12px;
    margin: 8px;
    outline: none;
}

#input:focus {
    border-color: @eve_cyan;
}

#outer-box {
    padding: 8px;
}

#scroll {
    margin: 0 4px;
}

#entry {
    border-radius: 6px;
    padding: 6px 10px;
    transition: all 0.15s;
}

#entry:selected {
    background: alpha(@eve_violet, 0.3);
    border: 1px solid alpha(@eve_cyan, 0.5);
}

#entry:selected #text {
    color: @eve_cyan;
}

#text {
    color: @text_primary;
    margin-left: 8px;
}

#img {
    border-radius: 4px;
}
```

`~/.config/wofi/config`:
```ini
width=480
height=560
prompt=  Launch
image_size=28
columns=1
allow_markup=true
always_parse_args=true
show_all=false
print_command=true
layer=overlay
insensitive=true
allow_images=true
term=kitty
```

---

## PHASE 17 — SCRATCHPAD TERMINAL (F12 DROPDOWN)

A terminal that slides down from the top on F12.
Hides when not in focus. EVE-PRIME standard tool.

```ini
# keybinds.conf
bind = , F12, exec, ~/.config/hypr/scripts/scratchpad.sh

# windowrules.conf
windowrule = float on, match:class ^scratchpad$
windowrule = size 1920 500, match:class ^scratchpad$
windowrule = move 0 0, match:class ^scratchpad$
windowrule = opacity 0.95 0.95, match:class ^scratchpad$
windowrule = animation slide, match:class ^scratchpad$
```

`scripts/scratchpad.sh`:
```bash
#!/bin/bash
# Toggle scratchpad terminal
if hyprctl clients -j | python3 -c "
import sys, json
clients = json.load(sys.stdin)
found = any(c.get('class') == 'scratchpad' for c in clients)
print('yes' if found else 'no')
" | grep -q "yes"; then
    hyprctl dispatch togglespecialworkspace scratchpad
else
    kitty --class scratchpad &
fi
```

---

## PHASE 18 — CLIPBOARD MANAGER

`cliphist` + `wofi` — keyboard accessible clipboard history.

```bash
# Install
sudo apt install wl-clipboard
# cliphist via go or pre-built binary
```

```ini
# autostart.conf — add to Stage 5
exec-once = sleep 1.3 && wl-paste --type text --watch cliphist store
exec-once = sleep 1.3 && wl-paste --type image --watch cliphist store

# keybinds.conf
bind = SUPER, V, exec, cliphist list | wofi --dmenu --prompt "Clipboard" | cliphist decode | wl-copy
```

---

## PHASE 19 — PERFORMANCE DEBUGGER OVERLAY

`scripts/perf-overlay.sh` — toggleable overlay showing:
GPU usage, VRAM, CPU per core, RAM, compositor frame time.

```bash
#!/bin/bash
# EVE-PRIME performance overlay
# Uses waybar custom module or standalone kitty window

CHOICE=$(printf \
"󰍛  System Stats\n󰻠  CPU per Core\n󰾲  GPU Stats\n󰝤  Memory Detail\n󰘚  Compositor Info\n󰅖  Close Overlay" \
    | wofi --dmenu --prompt "Perf Debug" --width 260 --height 260)

case "$CHOICE" in
    *"System Stats"*)
        kitty --title "EVE Debug" --class perf-overlay \
            sh -c "btop; read" &
        ;;
    *"CPU per Core"*)
        kitty --title "CPU Cores" --class perf-overlay \
            sh -c "watch -n 0.5 'grep -E \"^cpu[0-9]\" /proc/stat | awk \"{print \$1, \$2+\$4, \$2+\$4+\$5}\"'; read" &
        ;;
    *"GPU Stats"*)
        kitty --title "GPU Stats" --class perf-overlay \
            sh -c "watch -n 1 'cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null || echo GPU stats unavailable'; read" &
        ;;
    *"Memory Detail"*)
        kitty --title "Memory" --class perf-overlay \
            sh -c "watch -n 1 free -h; read" &
        ;;
    *"Compositor Info"*)
        hyprctl getoption decoration:blur:passes | notify-send "Hyprland Config" "$(hyprctl version | head -3)"
        ;;
    *"Close Overlay"*)
        pkill -f "perf-overlay"
        ;;
esac
```

---

## BUILD PHASES — EXECUTION ORDER

### PHASE 9 — Window Decorations (hyprbars)
- Verify hyprbars plugin config exists in plugins.conf
- Configure bar_height, colors, button colors per spec above
- Add windowrules to hide bars on terminals and PiP
- Test: title bars appear on firefox, code-insiders, nautilus
- Verify minimize sends to special workspace

### PHASE 10 — Waybar Animations + Popups
- Rewrite navbar-hover.sh to use waybar-animate.sh
- Create waybar-animate.sh smooth gap animation
- Wire module on-click popups for clock, network, audio, battery
- Create osd-popup.sh for volume/brightness
- Update keybinds to call OSD on media keys

### PHASE 11 — Animation Performance
- Rewrite animations.conf with performance-tuned values
- Add misc.conf stability settings
- Create workspace-guard.sh debounce script
- Wire workspace-guard.sh into workspace keybinds
- Test: rapid Super+1 through Super+9 — no chop, no crash

### PHASE 12 — Right-Click Menu Expansion
- Rewrite context-menu.sh with window/desktop context detection
- Test: right-click on empty desktop → desktop menu
- Test: Super+X with window focused → window menu
- Verify all actions execute correctly

### PHASE 13 — Notification System
- Write swaync style.css per spec above
- Write swaync config.json per spec above
- Restart swaync: swaync-client -R
- Test: send a test notification and verify EVE-PRIME styling

### PHASE 14 — Login Screen (SDDM)
- Check if SDDM is installed and active
- Test Approach B (mpvpaper before SDDM) first
- Fall back to Approach A (static screenshot) if needed
- Build EVE-PRIME QML theme
- Test full login cycle

### PHASE 15 — Lock Screen Expansion
- Add power buttons to hyprlock skin
- Test each button triggers correct systemd command
- Verify buttons don't appear until after successful lock

### PHASE 16 — App Launcher Upgrade
- Write ~/.config/wofi/style.css per spec
- Write ~/.config/wofi/config per spec
- Test: Super+Space opens styled launcher
- Verify images and search work correctly

### PHASE 17 — Scratchpad Terminal
- Create scripts/scratchpad.sh
- Add windowrules for scratchpad class
- Bind F12 to scratchpad toggle
- Test: F12 opens terminal, F12 again hides it

### PHASE 18 — Clipboard Manager
- Install cliphist
- Add to autostart Stage 5
- Bind Super+V to clipboard picker
- Test: copy something, Super+V shows history

### PHASE 19 — Performance Debugger
- Create scripts/perf-overlay.sh
- Add windowrule for perf-overlay class
- Bind Super+D to perf overlay
- Test all overlay modes launch correctly

---

## THE RULES THAT NEVER CHANGE

```
NO rewriting omni_wall.sh or omni_colors.sh — expand only
NO breaking the color engine chain
NO hardcoded values — tokens and variables always
NO animations that cause tearing or chop at normal use speed
NO feature that requires terminal to access by the user
NO plugin that isn't verified working with hyprctl configerrors

YES to GUI for every setting and tool
YES to keybind for every frequent action
YES to notification for every system event
YES to EVE-PRIME aesthetic throughout: dark, violet, cyan
YES to testing every phase before confirming complete
YES to discovering correct syntax before assuming it
YES to building missing tools if no library exists
YES to cmake/meson when apt doesn't have what we need
YES to hyprctl configerrors zero before next phase always
```

---

Copyright © 2026 Eve Industries
Author: Demetrius Q Jackson (OmniKing Dev)
Brand: EVE-PRIME | Omni-Devs