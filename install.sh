#!/bin/bash
set -euo pipefail

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Claude Power Kit -- Installer
# Replicates the full dev-protocol enforcement
# system for any teammate's machine.
#
# Usage:  bash install.sh
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
API_DIR="$CLAUDE_DIR/api-branch"
SETTINGS="$CLAUDE_DIR/settings.json"
KIT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Claude Power Kit -- Installer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Detect Python3 ──
PYTHON3=""
for candidate in /opt/homebrew/bin/python3.13 /opt/homebrew/bin/python3 /usr/local/bin/python3 /usr/bin/python3 "$(which python3 2>/dev/null)"; do
    if [ -x "$candidate" 2>/dev/null ]; then
        PYTHON3="$candidate"
        break
    fi
done

if [ -z "$PYTHON3" ]; then
    echo "! Python3 not found. Install Python 3.11+ first."
    exit 1
fi
echo "  Python3: $PYTHON3"

# ── Create directories ──
mkdir -p "$HOOKS_DIR" "$API_DIR"
echo "  Created: $HOOKS_DIR"
echo "  Created: $API_DIR"

# ── Install hooks ──
# Preflight: session start protocol enforcement
sed "s|__PYTHON3__|$PYTHON3|g" "$KIT_DIR/hooks/preflight.sh" > "$HOOKS_DIR/preflight.sh"
chmod +x "$HOOKS_DIR/preflight.sh"
echo "  Installed: preflight.sh"

# API Branch scanner + hook
sed "s|__PYTHON3__|$PYTHON3|g" "$KIT_DIR/hooks/api_scan_hook.sh" > "$API_DIR/scan_hook.sh"
chmod +x "$API_DIR/scan_hook.sh"
echo "  Installed: api_scan_hook.sh"

cp "$KIT_DIR/api-branch/scanner.py" "$API_DIR/scanner.py"
chmod +x "$API_DIR/scanner.py"
echo "  Installed: scanner.py"

# ── Seed API branch registry (empty template) ──
if [ ! -f "$API_DIR/registry.json" ]; then
    cp "$KIT_DIR/api-branch/registry.template.json" "$API_DIR/registry.json"
    echo "  Created: registry.json (empty -- register projects with scanner.py --add-project)"
else
    echo "  Skipped: registry.json already exists"
fi

# ── Install memory templates ──
echo ""
echo "  Memory templates copied to: $KIT_DIR/memory-templates/"
echo "  To use: copy into your project's .claude/projects/<path>/memory/ directory"

# ── Merge hooks into settings.json ──
echo ""
echo "  Merging hooks into settings.json..."

if [ ! -f "$SETTINGS" ]; then
    echo '{}' > "$SETTINGS"
    echo "  Created fresh settings.json"
fi

# Backup first
cp "$SETTINGS" "$SETTINGS.bak.$(date +%s)"

# Use Python to safely merge hooks
$PYTHON3 << 'PYEOF'
import json, sys, os

settings_path = os.path.expanduser("~/.claude/settings.json")
hooks_dir = os.path.expanduser("~/.claude/hooks")
api_dir = os.path.expanduser("~/.claude/api-branch")

with open(settings_path) as f:
    settings = json.load(f)

if "hooks" not in settings:
    settings["hooks"] = {}

if "SessionStart" not in settings["hooks"]:
    settings["hooks"]["SessionStart"] = []

existing_commands = set()
for entry in settings["hooks"]["SessionStart"]:
    for h in entry.get("hooks", []):
        existing_commands.add(h.get("command", ""))

new_hooks = [
    {
        "matcher": "",
        "hooks": [{
            "type": "command",
            "command": f"bash {hooks_dir}/preflight.sh",
            "timeout": 5000
        }]
    },
    {
        "matcher": "",
        "hooks": [{
            "type": "command",
            "command": f"bash {api_dir}/scan_hook.sh",
            "timeout": 8000
        }]
    },
]

added = 0
for hook in new_hooks:
    cmd = hook["hooks"][0]["command"]
    if cmd not in existing_commands:
        settings["hooks"]["SessionStart"].append(hook)
        added += 1

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)

print(f"  Added {added} new SessionStart hooks ({len(existing_commands)} already existed)")
PYEOF

# ── Install global CLAUDE.md template ──
if [ ! -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    cp "$KIT_DIR/templates/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
    echo "  Installed: global CLAUDE.md"
else
    echo "  Skipped: CLAUDE.md already exists (merge manually if needed)"
    echo "  Template at: $KIT_DIR/templates/CLAUDE.md"
fi

# ── Install GitNexus (code knowledge graph) ──
echo ""
echo "  Setting up GitNexus (code knowledge graph)..."
if command -v npm &>/dev/null; then
    if ! command -v gitnexus &>/dev/null; then
        npm install -g gitnexus 2>/dev/null && echo "  Installed: gitnexus (npm global)" || echo "  Warning: gitnexus install failed (npm error). Install manually: npm install -g gitnexus"
    else
        echo "  Skipped: gitnexus already installed ($(gitnexus --version))"
    fi
    # Auto-setup MCP for editors
    if command -v gitnexus &>/dev/null; then
        gitnexus setup 2>/dev/null && echo "  Configured: GitNexus MCP + skills + hooks" || echo "  Warning: gitnexus setup failed. Run manually: gitnexus setup"
    fi
else
    echo "  Skipped: npm not found. Install Node.js first, then: npm install -g gitnexus"
fi

# ── Summary ──
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " INSTALLED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  What fires on every session start:"
echo "    1. preflight.sh   -- forces reading atlas + protocol"
echo "    2. scan_hook.sh   -- API branch status + new API detection"
echo "    3. GitNexus hooks -- auto-reindex after code changes"
echo ""
echo "  Next steps:"
echo "    1. Register your projects:"
echo "       $PYTHON3 $API_DIR/scanner.py --add-project myproject /path/to/project"
echo ""
echo "    2. Run first scan:"
echo "       $PYTHON3 $API_DIR/scanner.py --scan --tree"
echo ""
echo "    3. Index your project with GitNexus:"
echo "       cd /path/to/project && gitnexus analyze --skills"
echo ""
echo "    4. Copy memory templates into your project:"
echo "       cp $KIT_DIR/memory-templates/*.md ~/.claude/projects/<your-project>/memory/"
echo ""
echo "    5. Edit CLAUDE.md with your project details:"
echo "       $CLAUDE_DIR/CLAUDE.md"
echo ""
echo "  Settings backup at: $SETTINGS.bak.*"
echo ""
