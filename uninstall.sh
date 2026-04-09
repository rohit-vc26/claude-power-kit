#!/bin/bash
set -euo pipefail

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Claude Power Kit -- Uninstaller"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"

# Auto-detect Python3
PYTHON3=""
for candidate in /opt/homebrew/bin/python3.13 /opt/homebrew/bin/python3 /usr/local/bin/python3 /usr/bin/python3; do
    if [ -x "$candidate" 2>/dev/null ]; then
        PYTHON3="$candidate"
        break
    fi
done
[ -z "$PYTHON3" ] && PYTHON3=$(which python3 2>/dev/null || echo "python3")

echo ""
echo "  This will remove:"
echo "    - ~/.claude/hooks/preflight.sh"
echo "    - ~/.claude/api-branch/ (scanner + registry)"
echo "    - SessionStart hooks from settings.json"
echo ""
read -p "  Continue? (y/N) " confirm
[ "$confirm" != "y" ] && echo "  Cancelled." && exit 0

# Remove files
rm -f "$CLAUDE_DIR/hooks/preflight.sh"
echo "  Removed: preflight.sh"

rm -rf "$CLAUDE_DIR/api-branch"
echo "  Removed: api-branch/"

# Remove hooks from settings.json
if [ -f "$SETTINGS" ]; then
    cp "$SETTINGS" "$SETTINGS.bak.$(date +%s)"
    $PYTHON3 << 'PYEOF'
import json, os

settings_path = os.path.expanduser("~/.claude/settings.json")
with open(settings_path) as f:
    settings = json.load(f)

if "hooks" in settings and "SessionStart" in settings["hooks"]:
    before = len(settings["hooks"]["SessionStart"])
    settings["hooks"]["SessionStart"] = [
        entry for entry in settings["hooks"]["SessionStart"]
        if not any(
            "preflight.sh" in h.get("command", "") or
            "scan_hook.sh" in h.get("command", "")
            for h in entry.get("hooks", [])
        )
    ]
    after = len(settings["hooks"]["SessionStart"])
    print(f"  Removed {before - after} hooks from settings.json")

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)
PYEOF
fi

echo ""
echo "  Done. Memory files in project directories are untouched."
echo "  Settings backup at: $SETTINGS.bak.*"
