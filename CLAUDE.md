# EVE-PRIME — Hyprland Session Rules for Claude

## SESSION REMINDER — READ THIS EVERY RESPONSE

The permissions deny list may be empty or reset.
You are personally responsible for never running:
- hyprctl reload
- hyprctl dispatch exit
- killall Hyprland
- setsid or nohup to launch compositor scripts
- Any script from /tmp that touches the compositor
- systemctl restart anything

To restart navbar-hover.sh use ONLY:
pkill -f navbar-hover.sh && sleep 0.2 &&
bash ~/.config/hypr/scripts/navbar-hover.sh &

Every time you are about to run a bash command,
ask yourself: could this crash Hyprland?
If yes — find another way or do not run it.

## WAYLAND SESSION RULES — NEVER VIOLATE

Any operation that touches the display manager, PAM,
or session management WILL kill the running compositor.

PERMANENTLY BANNED — these kill the Wayland session:
- sudo systemctl restart greetd
- sudo systemctl restart display-manager
- sudo systemctl start greetd
- loginctl terminate-session
- Any PAM operation that closes the current session
- Any command that writes to /etc/greetd/ and then
  restarts anything

GREETD CHANGES ARE REBOOT-ONLY.
Write the config. Build the binary. Stop.
Never restart greetd from within the session.
The user reboots manually to test greetd changes.

PERMANENTLY BANNED — these can crash or destabilize the session:
- swaync-client -R (restarts notification daemon)
- swaync-client -rs (reloads notification daemon)
- kill -SIGUSR1 to any process except waybar (for show/hide)
- pkill targeting any daemon except navbar-hover.sh
- Any command that restarts a Wayland-connected daemon

SAFE ALTERNATIVE FOR SWAYNC CSS:
swaync CSS changes take effect automatically on next launch.
Never restart swaync from within the session.
swaync-client -t is safe — it only toggles the panel visibility.

## TESTING RULES — ABSOLUTE

You are NEVER allowed to test anything that requires
a session restart, display manager restart, or VT switch.

Your job is WRITE and BUILD only.
Testing is always done by the user manually.

When you finish writing code or config:
- Report what you built
- Give the user the test command to run themselves
- STOP. Do not run it yourself.

This applies to:
- hyprlock (user tests it: hyprlock &)
- greetd changes (user tests on reboot only)
- waybar restarts (user runs: killall waybar && waybar &)
- Any systemctl command touching display or session
- Any command that could affect VT state

You are a writer and builder in this session.
The user is the tester. Always.

## Active Blueprints

- Phases 1–8: ~/.config/hypr/EVEPRIME-HYPRLAND-BLUEPRINT.md (complete)
- Phases 9+:  ~/.config/hypr/EVEPRIME-DESKTOP-COMPLETION-BLUEPRINT.md (in progress)

## Rules That Never Change

- hyprctl configerrors must return zero before any phase is complete
- Read before you write — always
- Do NOT rewrite omni_wall.sh or omni_colors.sh — expand only
- Blueprint is authoritative over existing config
- Verify every new option with hyprctl getoption before adding it
