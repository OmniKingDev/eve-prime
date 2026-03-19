#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  EVE-PRIME — WAYBAR LAUNCHER                                ║
# ║  Pins waybar to the primary monitor detected via hyprctl    ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

WAYBAR_CONFIG="${HOME}/.config/waybar/config.jsonc"
TMP_CONFIG="/tmp/waybar-primary.jsonc"

# ── Resolve primary monitor name from hyprctl ──────────────────
# Falls back to DP-1 if hyprctl is unavailable (e.g. early boot race)
PRIMARY=$(hyprctl monitors -j 2>/dev/null \
    | python3 -c "
import json, sys
monitors = json.load(sys.stdin)
# First monitor in the list is the primary (matches monitors.conf order)
if monitors:
    print(monitors[0]['name'])
" 2>/dev/null || echo "DP-1")

# ── Inject output binding into every bar that has no output set ─
python3 - "$WAYBAR_CONFIG" "$TMP_CONFIG" "$PRIMARY" <<'EOF'
import json, re, sys

src, dst, output = sys.argv[1], sys.argv[2], sys.argv[3]

text = open(src).read()
# Strip // line comments
text = re.sub(r'//[^\n]*', '', text)
# Strip /* */ block comments
text = re.sub(r'/\*.*?\*/', '', text, flags=re.DOTALL)

bars = json.loads(text)
for bar in bars:
    if not bar.get('output'):
        bar['output'] = [output]

with open(dst, 'w') as f:
    json.dump(bars, f, indent=2)
EOF

exec waybar --config "$TMP_CONFIG"
