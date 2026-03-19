# EVE-PRIME — HYPRLAND COMPLETE REMODEL BLUEPRINT
**Owner:** Demetrius Q Jackson (OmniKing Dev)
**Company:** Eve Industries | OS: EVE-PRIME
**File:** EVEPRIME-HYPRLAND-BLUEPRINT.md
**Created:** 2026-03-17
**Updated:** 2026-03-17 — Syntax verified via hyprctl keyword testing on Hyprland 0.54.0
**Status:** AUTHORITATIVE — All Hyprland configs built from this document.

---

## READ THIS FIRST — OPUS INSTRUCTIONS

You are working on EVE-PRIME, a custom Ubuntu-based Hyprland desktop OS.
**Hyprland version: 0.54. This version matters for every line of config.**
All configs live in: ~/.config/hypr/

Read EVERY .conf file and EVERY script before writing a single line.
Read hyprlock/, scripts/, themes/ completely.

This blueprint defines the complete finished state of EVE-PRIME's desktop.
Work one phase at a time. Report what exists, what is broken, what is
missing BEFORE executing each phase. Wait for confirmation to proceed.

When in conflict between what exists and what this document says —
this document wins. Always.

---

## HYPRLAND 0.54 SYNTAX RULES — VERIFIED AND TESTED

These rules apply to EVERY config file. No exceptions.
Discovered via `hyprctl keyword` testing and confirmed with `hyprctl configerrors`.

### Window Rules — match: prefix required, toggle fields need explicit values
```ini
# CORRECT — Hyprland 0.54 (verified working)
windowrule = float on, match:class ^pavucontrol$
windowrule = opacity 0.95 0.85, match:class ^kitty$
windowrule = workspace 2, match:class ^code-insiders$
windowrule = size 800 500, match:class ^pavucontrol$
windowrule = center 1, match:class ^pavucontrol$
windowrule = float on, match:title ^Picture-in-Picture$
windowrule = pin on, match:title ^Picture-in-Picture$
windowrule = move 100%-490 100%-280, match:title ^Picture-in-Picture$

# WRONG — all of these throw "missing a value" errors in 0.54
windowrulev2 = float, class:(pavucontrol)      # windowrulev2 removed
windowrule = float, class:pavucontrol           # missing "on", missing match: prefix
windowrule = center, class:pavucontrol          # missing "1", missing match: prefix
```

### Layer Rules — also use match: prefix
```ini
# CORRECT
layerrule = blur on, match:namespace ^waybar$
layerrule = xray on, match:namespace ^waybar$

# WRONG — these types do not exist in 0.54
layerrule = ignorealpha 0.1, ...    # invalid type
windowrule = blur, ...               # blur is layerrule only
windowrule = idleinhibit focus, ...  # invalid type in 0.54
```

### Key syntax rules
```
- match:class ^name$    — regex match on window class (required)
- match:title ^name$    — regex match on window title
- match:namespace ^n$   — regex match on layer namespace (layerrule)
- float on              — toggle fields MUST have explicit value
- center 1              — "1" means enabled
- pin on                — same pattern
- opacity X Y           — active inactive (values, no "on" needed)
- size W H              — pixel values (no "on" needed)
- workspace N           — number value (no "on" needed)
```

### Monitor Rules
```ini
# CORRECT
monitor = DP-1, 1920x1080@100, 0x0, 1
monitor = , preferred, auto, 1
```

### Decoration
```ini
# CORRECT — shadow is a nested block in 0.54
decoration {
    rounding = 10
    active_opacity = 1.0
    inactive_opacity = 1.0
    blur {
        enabled = true
        size = 6
        passes = 3
    }
    shadow {
        enabled = true
        range = 20
        color = rgba(7B2FBE55)
    }
}
```

### General — gaps_out directional
```ini
general {
    gaps_in = 4
    gaps_out = 48, 10, 10, 10
    border_size = 2
    col.active_border = rgba(7B2FBEff) rgba(00D4FFff) 45deg
    col.inactive_border = rgba(1A003099)
    layout = dwindle
}
```

### Keybinds
```ini
bind = SUPER, Return, exec, kitty
bind = SUPER SHIFT, Q, exit
bindm = SUPER, mouse:272, movewindow
bindel = , XF86AudioRaiseVolume, exec, pamixer -i 5
bindl = , XF86AudioMute, exec, pamixer -t
```

---

## EVE-PRIME IDENTITY

Developer OS. Opinionated, fast, visually distinct.
Aesthetic: dark, violet/cyan, minimal chrome, maximum information density.
Unicode: Nerd Fonts 3.x throughout. No outdated glyphs.

---

## KNOWN BUGS — PHASE 1 TARGETS

### BUG 1 — Waybar pushes windows
Root cause: exclusive:true in both bar layout.jsonc files.
navbar-hover.sh SIGUSR1/SIGUSR2 toggles the exclusive zone — shoves windows.
Fix: exclusive:false + permanent gaps_out top margin in general.conf.
Windows never move when waybar animates.

### BUG 2 — Waybar ignores fullscreen
Root cause: navbar-hover.sh only polls cursor Y, never checks fullscreen.
Fix: Add hyprctl activewindow -j fullscreen field check in poll loop.
Force hide on fullscreen==1, restore on exit.

### BUG 3 — Opacity panic on workspace switch
Root cause: active_opacity=0.80, inactive_opacity=0.45, fullscreen_opacity=1.0
On fullscreen exit fullscreen_opacity snaps off and all windows jump.
Fix: active_opacity=1.0, inactive_opacity=1.0, remove fullscreen_opacity.
Per-app opacity via windowrule only.

### BUG 4 — Chaotic boot order
Root cause: No stage ordering, kills dunst/mako before starting replacement,
redundant hotplug scripts, mpvpaper launched twice.
Fix: 6-stage ordered autostart.

### BUG 5 — windowrulev2 deprecated syntax
Root cause: windowrulev2 removed in Hyprland 0.45+, errors in 0.54.
Fix: All rules use `windowrule` with `match:class ^name$` prefix.
Toggle fields require explicit values: `float on`, `center 1`, `pin on`.
`blur` and `idleinhibit` are NOT valid windowrule types — blur is `layerrule` only.

---

## SECTION 1 — WINDOW RULES + BEHAVIOR

### windowrules.conf — Complete (verified 0.54 syntax)

```ini
# ============================================================
# EVE-PRIME — windowrules.conf
# Hyprland 0.54 — windowrule + match: prefix, explicit values
# ============================================================

# === FLOATING ===
windowrule = float on, match:class ^pavucontrol$
windowrule = float on, match:class ^nm-connection-editor$
windowrule = float on, match:class ^blueman-manager$
windowrule = float on, match:class ^org.gnome.Calculator$
windowrule = float on, match:class ^file-roller$
windowrule = float on, match:class ^nwg-look$
windowrule = float on, match:class ^qt5ct$
windowrule = float on, match:title ^Picture-in-Picture$
windowrule = float on, match:title ^Open File$
windowrule = float on, match:title ^Save File$
windowrule = float on, match:title ^Confirm$

# === SIZE + POSITION ===
windowrule = size 800 500, match:class ^pavucontrol$
windowrule = center 1, match:class ^pavucontrol$
windowrule = size 900 600, match:class ^nm-connection-editor$
windowrule = center 1, match:class ^nm-connection-editor$
windowrule = size 700 500, match:class ^blueman-manager$
windowrule = center 1, match:class ^blueman-manager$

# === OPACITY — active / inactive ===
windowrule = opacity 0.95 0.85, match:class ^kitty$
windowrule = opacity 0.95 0.85, match:class ^Alacritty$
windowrule = opacity 0.95 0.85, match:class ^foot$
windowrule = opacity 0.98 0.90, match:class ^code-insiders$
windowrule = opacity 0.98 0.90, match:class ^Code$
windowrule = opacity 1.0 0.95, match:class ^firefox$
windowrule = opacity 1.0 0.95, match:class ^chromium$
windowrule = opacity 0.92 0.80, match:class ^thunar$
windowrule = opacity 0.92 0.80, match:class ^nautilus$

# === LAYER RULES (blur is layerrule, not windowrule) ===
layerrule = blur on, match:namespace ^waybar$
layerrule = blur on, match:namespace ^rofi$
layerrule = xray on, match:namespace ^waybar$

# === WORKSPACE ASSIGNMENTS ===
windowrule = workspace 1, match:class ^firefox$
windowrule = workspace 1, match:class ^chromium$
windowrule = workspace 2, match:class ^code-insiders$
windowrule = workspace 2, match:class ^Code$
windowrule = workspace 3, match:class ^kitty$
windowrule = workspace 3, match:class ^Alacritty$

# === PICTURE IN PICTURE ===
windowrule = float on, match:title ^Picture-in-Picture$
windowrule = pin on, match:title ^Picture-in-Picture$
windowrule = size 480 270, match:title ^Picture-in-Picture$
windowrule = move 100%-490 100%-280, match:title ^Picture-in-Picture$
```

### Two Fullscreen Modes

```ini
# keybinds.conf
bind = SUPER, F,       fullscreen, 1    # F1 fakefullscreen — opacity preserved
bind = SUPER SHIFT, F, fullscreen, 0    # F2 true fullscreen — single window
```

### Mouse + Context Menu

```ini
# keybinds.conf
bindm = SUPER, mouse:272,  movewindow
bindm = SUPER, mouse:273,  resizewindow
bind  = SUPER, mouse_down, workspace, e-1
bind  = SUPER, mouse_up,   workspace, e+1
bind  = SUPER, X,          exec, ~/.config/hypr/scripts/context-menu.sh
```

### context-menu.sh

```bash
#!/bin/bash
CHOICE=$(printf \
"󰃭  Wallpaper Picker\n󰖯  Float / Tile\n󰖲  Opacity 100%%\n󰖲  Opacity 90%%\n󰖲  Opacity 80%%\n󰖲  Opacity 70%%\n󰍉  Window Info\n  Settings\n󰐦  Reload Config" \
    | wofi --dmenu --prompt "Desktop Menu" --width 280 --height 320)

case "$CHOICE" in
    *"Wallpaper Picker"*) ~/.config/hypr/scripts/omni_wall.sh pick ;;
    *"Float / Tile"*)     hyprctl dispatch togglefloating ;;
    *"Opacity 100%"*)     hyprctl setprop address:$(hyprctl activewindow -j | python3 -c "import sys,json;print(json.load(sys.stdin)['address'])") alpha 1.0 ;;
    *"Opacity 90%"*)      hyprctl setprop address:$(hyprctl activewindow -j | python3 -c "import sys,json;print(json.load(sys.stdin)['address'])") alpha 0.9 ;;
    *"Opacity 80%"*)      hyprctl setprop address:$(hyprctl activewindow -j | python3 -c "import sys,json;print(json.load(sys.stdin)['address'])") alpha 0.8 ;;
    *"Opacity 70%"*)      hyprctl setprop address:$(hyprctl activewindow -j | python3 -c "import sys,json;print(json.load(sys.stdin)['address'])") alpha 0.7 ;;
    *"Window Info"*)      hyprctl activewindow | notify-send "Window Info" "$(cat)" ;;
    *"Settings"*)         ~/.config/hypr/scripts/eve-settings.sh ;;
    *"Reload Config"*)    hyprctl reload && notify-send "EVE-PRIME" "󰑓 Config reloaded" ;;
esac
```

---

## SECTION 2 — WAYBAR REBUILD

### Auto-Hide Fix — CSS Transform Only

Both bars:
```json
"exclusive": false
```

general.conf:
```ini
gaps_out = 48, 10, 10, 10
```

Auto-hide is SIGUSR1/SIGUSR2 only — no CSS needed.
GTK CSS (used by Waybar) does NOT support `transform` or `pointer-events`.
The waybar `on-sigusr1: hide` / `on-sigusr2: show` config handles visibility.
navbar-hover.sh sends these signals based on cursor position and fullscreen state.

### Top Bar config.json

```json
{
    "layer": "top",
    "position": "top",
    "height": 36,
    "exclusive": false,
    "passthrough": false,
    "modules-left": ["hyprland/workspaces", "hyprland/window"],
    "modules-center": ["clock"],
    "modules-right": [
        "cpu", "memory", "temperature",
        "network", "pulseaudio", "battery",
        "tray", "custom/omni-wall", "custom/eve-status"
    ],

    "hyprland/workspaces": {
        "format": "{icon}",
        "format-icons": {
            "1": "󰖟", "2": "󰨞", "3": "󰆍",
            "4": "󰎆", "5": "󰭹",
            "urgent": "󰀨", "active": "󰮯", "default": "󰊠"
        },
        "persistent-workspaces": { "*": 5 }
    },

    "clock": {
        "format": "󰥔  {:%H:%M}",
        "format-alt": "󰃭  {:%A, %B %d %Y}",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt>{calendar}</tt>"
    },

    "cpu": {
        "format": "󰻠  {usage}%",
        "interval": 2,
        "tooltip": false
    },

    "memory": {
        "format": "󰍛  {used:0.1f}G",
        "interval": 5
    },

    "temperature": {
        "format": "󰔏  {temperatureC}°C",
        "critical-threshold": 80,
        "format-critical": "󰸁  {temperatureC}°C"
    },

    "network": {
        "format-wifi": "󰤨  {signalStrength}%",
        "format-ethernet": "󰈀  {ifname}",
        "format-disconnected": "󰤭  offline",
        "tooltip-format-wifi": "{essid} — {ipaddr}",
        "tooltip-format-ethernet": "{ifname}: {ipaddr}"
    },

    "pulseaudio": {
        "format": "{icon}  {volume}%",
        "format-muted": "󰖁  muted",
        "format-icons": { "default": ["󰕿", "󰖀", "󰕾"] },
        "on-click": "pavucontrol",
        "on-scroll-up": "pamixer -i 2",
        "on-scroll-down": "pamixer -d 2"
    },

    "battery": {
        "format": "{icon}  {capacity}%",
        "format-charging": "󰂄  {capacity}%",
        "format-icons": ["󰂎","󰁺","󰁻","󰁼","󰁽","󰁾","󰁿","󰂀","󰂁","󰂂","󰁹"],
        "states": { "warning": 30, "critical": 15 }
    },

    "custom/omni-wall": {
        "format": "󰸉",
        "tooltip": "Wallpaper Picker",
        "on-click": "~/.config/hypr/scripts/omni_wall.sh pick"
    },

    "custom/eve-status": {
        "exec": "~/.config/hypr/scripts/eve-status.sh",
        "interval": 10,
        "format": "{}",
        "return-type": "json"
    }
}
```

### Waybar style.css — EVE-PRIME

```css
@define-color bg_primary    #0D0015;
@define-color bg_secondary  #1A0030;
@define-color eve_violet    #7B2FBE;
@define-color eve_cyan      #00D4FF;
@define-color text_primary  #E8E8F0;
@define-color text_dim      #8080A0;
@define-color warning       #FFB347;
@define-color critical      #FF4444;

* {
    font-family: "JetBrainsMono Nerd Font", "Symbols Nerd Font", sans-serif;
    font-size: 13px;
    color: @text_primary;
    border: none;
    border-radius: 0;
    min-height: 0;
}

/* NOTE: GTK CSS does NOT support transform or pointer-events.
   Auto-hide is handled by waybar SIGUSR1/SIGUSR2 signals. */

window#waybar {
    background: alpha(@bg_primary, 0.88);
    border-bottom: 1px solid alpha(@eve_violet, 0.4);
}

#workspaces button {
    color: @text_dim;
    padding: 0 6px;
    margin: 4px 2px;
    border-radius: 4px;
    background: transparent;
    transition: all 0.2s ease;
}

#workspaces button:hover {
    color: @text_primary;
    background: alpha(@eve_violet, 0.15);
}

#workspaces button.active {
    color: @eve_cyan;
    background: alpha(@eve_violet, 0.25);
    border-bottom: 2px solid @eve_cyan;
}

#workspaces button.urgent {
    color: @critical;
    background: alpha(@critical, 0.15);
}

#window {
    color: @text_dim;
    font-style: italic;
    padding: 0 8px;
}

#clock {
    color: @eve_cyan;
    font-weight: bold;
    padding: 0 12px;
}

#cpu, #memory, #temperature, #network,
#pulseaudio, #battery, #tray {
    padding: 0 8px;
}

#temperature.critical {
    color: @critical;
    animation: blink 1s ease infinite;
}

#network { color: @eve_cyan; }
#network.disconnected { color: @text_dim; }

#pulseaudio.muted { color: @text_dim; }

#battery.charging { color: @eve_cyan; }
#battery.warning  { color: @warning; }
#battery.critical {
    color: @critical;
    animation: blink 0.5s linear infinite alternate;
}

#custom-omni-wall {
    color: @eve_violet;
    font-size: 16px;
    padding: 0 10px;
    transition: color 0.2s;
}
#custom-omni-wall:hover { color: @eve_cyan; }

tooltip {
    background: @bg_secondary;
    border: 1px solid @eve_violet;
    border-radius: 6px;
    padding: 4px;
}

@keyframes blink {
    to { color: @bg_primary; background: @critical; }
}
```

---

## SECTION 3 — BOOT + AUTOSTART

### autostart.conf

```ini
# ============================================================
# EVE-PRIME — autostart.conf
# Stage ordering is required. Do not reorder without testing.
# ============================================================

# === STAGE 1: DAEMONS ===
exec-once = /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = sleep 0.1 && ~/.config/hypr/scripts/requirement-check.sh

# === STAGE 2: NOTIFICATION DAEMON ===
exec-once = sleep 0.3 && swaync

# === STAGE 3: IDLE + LOCK ===
exec-once = sleep 0.5 && hypridle

# === STAGE 4: VISUAL SYSTEMS ===
exec-once = sleep 0.5 && ~/.config/hypr/scripts/omni_wall.sh restore
exec-once = sleep 0.8 && ~/.config/hypr/scripts/waybar-launch.sh
exec-once = sleep 1.0 && ~/.config/hypr/scripts/navbar-hover.sh
exec-once = sleep 1.0 && hyprsunset

# === STAGE 5: TRAY ===
exec-once = sleep 1.2 && nm-applet --indicator
exec-once = sleep 1.2 && blueman-applet

# === STAGE 6: WATCHERS ===
exec-once = sleep 1.5 && ~/.config/hypr/scripts/hotplug-daemon.sh
exec-once = sleep 1.5 && ~/.config/hypr/scripts/eve-daemon-watch.sh
```

### requirement-check.sh

```bash
#!/bin/bash
REQUIRED=(
    "waybar" "swaync" "hypridle" "hyprlock"
    "wofi" "rofi" "playerctl" "nm-applet"
    "blueman-applet" "pamixer" "brightnessctl"
    "grim" "slurp" "wl-clipboard" "mpvpaper"
    "python3" "convert"
)
MISSING=()
for tool in "${REQUIRED[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
        MISSING+=("$tool")
    fi
done
if [ ${#MISSING[@]} -gt 0 ]; then
    notify-send "EVE-PRIME — Missing Tools" \
        "󰀨 Install: ${MISSING[*]}" \
        --urgency=critical --expire-time=10000
fi
```

---

## SECTION 4 — WORKSPACE OVERVIEW

```ini
# plugins.conf
# NOTE: enable_gesture, gesture_fingers, gesture_positive are NOT valid
# in the installed hyprexpo version — they throw parse errors.
# Gesture is configured via hyprexpo-gesture in keybinds.conf instead.
plugin {
    hyprexpo {
        columns = 3
        gap_size = 8
        bg_col = rgb(0D0015)
        workspace_method = first 1
        gesture_distance = 300
    }
}

# keybinds.conf
bind = SUPER, Super_L, hyprexpo:expo, toggle
```

---

## SECTION 5 — HYPRLOCK

### hyprlock/hyprlock.conf

```ini
general {
    disable_loading_bar = false
    hide_cursor = true
    grace = 3
    no_fade_in = false
    no_fade_out = false
    ignore_empty_input = false
}

background {
    monitor =
    path = screenshot
    blur_passes = 3
    blur_size = 7
    brightness = 0.5
    vibrancy = 0.2
    vibrancy_darkness = 0.2
}

label {
    monitor =
    text = cmd[update:1000] echo "$(date +'%H:%M')"
    color = rgba(00D4FFff)
    font_size = 72
    font_family = JetBrainsMono Nerd Font Bold
    position = 0, 120
    halign = center
    valign = center
}

label {
    monitor =
    text = cmd[update:60000] echo "$(date +'%A, %B %d')"
    color = rgba(B080D0cc)
    font_size = 18
    font_family = JetBrainsMono Nerd Font
    position = 0, 50
    halign = center
    valign = center
}

label {
    monitor =
    text = 󱄑  OmniKing Dev
    color = rgba(7B2FBEcc)
    font_size = 14
    font_family = JetBrainsMono Nerd Font
    position = 0, -60
    halign = center
    valign = center
}

input-field {
    monitor =
    size = 280, 48
    outline_thickness = 2
    dots_size = 0.3
    dots_spacing = 0.2
    dots_center = true
    outer_color = rgba(7B2FBEcc)
    inner_color = rgba(0D001599)
    font_color = rgba(E8E8F0ff)
    fade_on_empty = true
    placeholder_text = 󰍁  enter password
    rounding = 8
    check_color = rgba(00D4FFff)
    fail_color = rgba(FF4444ff)
    fail_text = 󰀨  invalid password
    capslock_color = rgba(FFB347ff)
    position = 0, -140
    halign = center
    valign = center
}
```

### hypridle.conf

```ini
general {
    lock_cmd = pidof hyprlock || hyprlock
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = hyprctl dispatch dpms on
    ignore_dbus_inhibit = false
}

listener {
    timeout = 300
    on-timeout = loginctl lock-session
}

listener {
    timeout = 600
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}
```

---

## SECTION 6 — ANIMATIONS + DECORATION

### animations.conf

```ini
animations {
    enabled = true

    bezier = easeOut,    0.16, 1,     0.3,  1
    bezier = easeIn,     0.7,  0,     0.84, 0
    bezier = easeInOut,  0.37, 0,     0.63, 1
    bezier = spring,     0.34, 1.56,  0.64, 1
    bezier = overviewIn, 0.25, 0.46,  0.45, 0.94

    animation = windows,          1, 4,  spring,   popin 85%
    animation = windowsOut,       1, 3,  easeIn,   popin 85%
    animation = windowsMove,      1, 4,  easeOut
    animation = border,           1, 8,  easeInOut
    animation = borderangle,      1, 40, easeInOut, loop
    animation = fade,             1, 4,  easeOut
    animation = fadeOut,          1, 3,  easeIn
    animation = workspaces,       1, 5,  easeOut,  slide
    animation = specialWorkspace, 1, 5,  spring,   slidevert
    animation = layersIn,         1, 3,  spring,   popin 85%
    animation = layersOut,        1, 3,  easeIn,   popin 85%
}
```

### decoration.conf

```ini
decoration {
    rounding = 10

    active_opacity = 1.0
    inactive_opacity = 1.0

    blur {
        enabled = true
        size = 6
        passes = 3
        new_optimizations = true
        xray = false
        noise = 0.0117
        contrast = 0.8916
        brightness = 0.8
        vibrancy = 0.1696
        vibrancy_darkness = 0.0
        special = true
        popups = true
    }

    shadow {
        enabled = true
        range = 20
        render_power = 3
        color = rgba(7B2FBE55)
        ignore_window = true
    }

    dim_inactive = true
    dim_strength = 0.12
    dim_special = 0.3
}
```

---

## SECTION 7 — KEYBINDS (full)

```ini
$mod = SUPER
$terminal = kitty
$browser = firefox
$filemanager = nautilus
$launcher = rofi -show drun

bind = $mod, Return,       exec, $terminal
bind = $mod, B,            exec, $browser
bind = $mod, E,            exec, $filemanager
bind = $mod, Space,        exec, $launcher
bind = $mod, X,            exec, ~/.config/hypr/scripts/context-menu.sh
bind = $mod, Q,            killactive
bind = $mod SHIFT, Q,      exit
bind = $mod, R,            exec, hyprctl reload && notify-send "EVE-PRIME" "󰑓 Config reloaded"
bind = $mod, L,            exec, loginctl lock-session
bind = $mod, W,            exec, ~/.config/hypr/scripts/omni_wall.sh pick
bind = $mod, I,            exec, ~/.config/hypr/scripts/eve-settings.sh
bind = $mod, F,            fullscreen, 1
bind = $mod SHIFT, F,      fullscreen, 0
bind = $mod, T,            togglefloating
bind = $mod, C,            centerwindow
bind = $mod, P,            pin
bind = $mod, V,            togglesplit
bind = $mod, H,            movefocus, l
bind = $mod, L,            movefocus, r
bind = $mod, K,            movefocus, u
bind = $mod, J,            movefocus, d
bind = $mod, left,         movefocus, l
bind = $mod, right,        movefocus, r
bind = $mod, up,           movefocus, u
bind = $mod, down,         movefocus, d
bind = $mod SHIFT, H,      movewindow, l
bind = $mod SHIFT, L,      movewindow, r
bind = $mod SHIFT, K,      movewindow, u
bind = $mod SHIFT, J,      movewindow, d
bind = $mod SHIFT, left,   movewindow, l
bind = $mod SHIFT, right,  movewindow, r
bind = $mod SHIFT, up,     movewindow, u
bind = $mod SHIFT, down,   movewindow, d
bind = $mod CTRL, H,       resizeactive, -40 0
bind = $mod CTRL, L,       resizeactive, 40 0
bind = $mod CTRL, K,       resizeactive, 0 -40
bind = $mod CTRL, J,       resizeactive, 0 40
bind = $mod CTRL, left,    resizeactive, -40 0
bind = $mod CTRL, right,   resizeactive, 40 0
bind = $mod CTRL, up,      resizeactive, 0 -40
bind = $mod CTRL, down,    resizeactive, 0 40
bind = $mod, Super_L,      hyprexpo:expo, toggle
bind = $mod, 1,            workspace, 1
bind = $mod, 2,            workspace, 2
bind = $mod, 3,            workspace, 3
bind = $mod, 4,            workspace, 4
bind = $mod, 5,            workspace, 5
bind = $mod, 6,            workspace, 6
bind = $mod, 7,            workspace, 7
bind = $mod, 8,            workspace, 8
bind = $mod, 9,            workspace, 9
bind = $mod, 0,            workspace, 10
bind = $mod, TAB,          workspace, e+1
bind = $mod SHIFT, TAB,    workspace, e-1
bind = $mod SHIFT, 1,      movetoworkspace, 1
bind = $mod SHIFT, 2,      movetoworkspace, 2
bind = $mod SHIFT, 3,      movetoworkspace, 3
bind = $mod SHIFT, 4,      movetoworkspace, 4
bind = $mod SHIFT, 5,      movetoworkspace, 5
bind = $mod, S,            togglespecialworkspace
bind = $mod SHIFT, S,      movetoworkspacesilent, special
bind = , Print,            exec, grim ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png
bind = SHIFT, Print,       exec, grim -g "$(slurp)" ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png
bind = $mod, Print,        exec, grim -g "$(slurp)" - | wl-copy
bindm = $mod, mouse:272,   movewindow
bindm = $mod, mouse:273,   resizewindow
bind  = $mod, mouse_down,  workspace, e-1
bind  = $mod, mouse_up,    workspace, e+1
bindel = , XF86AudioRaiseVolume,  exec, pamixer -i 5
bindel = , XF86AudioLowerVolume,  exec, pamixer -d 5
bindl  = , XF86AudioMute,         exec, pamixer -t
bindl  = , XF86AudioPlay,         exec, playerctl play-pause
bindl  = , XF86AudioNext,         exec, playerctl next
bindl  = , XF86AudioPrev,         exec, playerctl previous
bindel = , XF86MonBrightnessUp,   exec, brightnessctl set +5%
bindel = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
```

---

## SECTION 8 — SYSTEM SCRIPTS

### scripts/eve-settings.sh

```bash
#!/bin/bash
CHOICE=$(printf \
"󰍹  Display\n󰓃  Audio\n󰤨  Network\n󰟩  Bluetooth\n󰖩  Theme\n󰏔  Packages\n󱁤  System Info\n󰊠  About EVE-PRIME" \
    | wofi --dmenu --prompt "EVE Settings" --width 300 --height 380)

case "$CHOICE" in
    *"Display"*)    notify-send "Display" "$(hyprctl monitors | grep -E 'Monitor|resolution|at|scale')" ;;
    *"Audio"*)      pavucontrol & ;;
    *"Network"*)    nm-connection-editor & ;;
    *"Bluetooth"*)  blueman-manager & ;;
    *"Theme"*)      notify-send "Theme" "Wallpaper: $(cat ~/.config/hypr/last-wallpaper 2>/dev/null || echo default)" ;;
    *"Packages"*)
        COUNT=$(dpkg -l | grep -c "^ii")
        notify-send "Packages" "󰏔 $COUNT installed" ;;
    *"System Info"*)
        notify-send "System" "Kernel: $(uname -r)\nUptime: $(uptime -p)\nRAM: $(free -h | awk '/^Mem/{print $3"/"$2}')" ;;
    *"About"*)
        notify-send "EVE-PRIME" "󱄑 OmniKing Dev\nEve Industries\nBuilt different." ;;
esac
```

### scripts/eve-daemon-watch.sh

```bash
#!/bin/bash
WATCH=("waybar" "swaync" "hypridle")
while true; do
    for proc in "${WATCH[@]}"; do
        if ! pgrep -x "$proc" > /dev/null; then
            notify-send "EVE-PRIME" "󰀨 $proc stopped — restarting" --urgency=normal
            case "$proc" in
                waybar)   ~/.config/hypr/scripts/waybar-launch.sh & ;;
                swaync)   swaync & ;;
                hypridle) hypridle & ;;
            esac
        fi
    done
    sleep 15
done
```

### scripts/eve-status.sh

```bash
#!/bin/bash
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print int($2+$4)}')
TEMP=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -n | tail -1)
TEMP=$((TEMP/1000))
if   [ "$TEMP" -ge 80 ]; then CLASS="critical"
elif [ "$TEMP" -ge 65 ]; then CLASS="warning"
else CLASS="normal"
fi
echo "{\"text\": \"󱄑 ${CPU}% ${TEMP}°\", \"class\": \"$CLASS\", \"tooltip\": \"CPU: ${CPU}% | Temp: ${TEMP}°C\"}"
```

---

## BUILD PHASES

### PHASE 1 — BUG FIXES (execute first, nothing else)
- Fix BUG 1: exclusive:false, gaps_out top margin
- Fix BUG 2: navbar-hover.sh fullscreen detection
- Fix BUG 3: global opacity 1.0/1.0, remove fullscreen_opacity
- Fix BUG 4: 6-stage autostart, create requirement-check.sh
- Fix BUG 5: convert all windowrulev2 to windowrule + match: prefix + explicit values
- After all fixes: hyprctl reload → confirm ZERO config errors
- Do not touch anything outside Phase 1 scope

### PHASE 2 — WAYBAR REBUILD
- Full config.json from Section 2
- Full style.css from Section 2
- Nerd Fonts 3.x throughout
- eve-status.sh created
- Auto-hide CSS only, verified

### PHASE 3 — WINDOW RULES + KEYBINDS
- Full windowrules.conf from Section 1
- Full keybinds.conf from Section 7
- context-menu.sh created
- Both fullscreen modes tested

### PHASE 4 — BOOT + AUTOSTART
- autostart.conf from Section 3
- requirement-check.sh finalized
- hypridle.conf verified
- Boot sequence tested on next login

### PHASE 5 — HYPRLOCK
- hyprlock.conf from Section 5
- EVE-PRIME visual spec verified
- Lock/unlock cycle tested

### PHASE 6 — ANIMATIONS + DECORATION
- animations.conf from Section 6
- decoration.conf from Section 6
- hyprexpo overview configured
- Super key bound to overview

### PHASE 7 — OMNI_WALL + COLOR ENGINE
- All omni_wall.sh modes verified
- Color engine hook confirmed
- Waybar hot-reload on palette change
- Super+W tested

### PHASE 8 — SETTINGS + DEBUGGER
- eve-settings.sh from Section 8
- eve-daemon-watch.sh from Section 8
- All notifications consistent
- System fully operational

---

## THE RULES THAT NEVER CHANGE

```
NO windowrulev2 — windowrule only in Hyprland 0.54
NO bare class:name — always match:class ^name$
NO toggle fields without values — float on, center 1, pin on
NO blur/idleinhibit as windowrule — blur is layerrule only
NO hardcoded values — variables only
NO pushing windows when waybar animates
NO fullscreen_opacity global
NO opacity snapping on workspace switch
NO out-of-order boot
NO silent failures
NO duplicate process launchers

YES windowrule with match:class ^name$ syntax
YES layerrule with match:namespace ^name$ syntax
YES explicit values on all toggle fields
YES 6-stage ordered autostart
YES two fullscreen modes: F1 fake, F2 true
YES CSS-only waybar hide
YES color engine drives visual system
YES hyprctl reload + hyprctl configerrors after every phase
YES zero config errors before next phase
```

---

Copyright © 2026 Eve Industries
Author: Demetrius Q Jackson (OmniKing Dev)
Brand: EVE-PRIME | Omni-Devs