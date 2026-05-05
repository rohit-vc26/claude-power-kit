#!/usr/bin/env bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Claude Power Kit — Installer v2
# One-command setup: hooks, skills, NCS dashboard, GitNexus
# Works on: macOS (Homebrew) · Ubuntu/Debian · Linux (nvm)
# Usage: bash install.sh
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -euo pipefail

BOLD="\033[1m"; GREEN="\033[0;32m"; YELLOW="\033[0;33m"
CYAN="\033[0;36m"; RED="\033[0;31m"; RESET="\033[0m"

step() { echo -e "\n${BOLD}${CYAN}▶ $1${RESET}"; }
ok()   { echo -e "  ${GREEN}✓ $1${RESET}"; }
warn() { echo -e "  ${YELLOW}⚠ $1${RESET}"; }
err()  { echo -e "  ${RED}✗ $1${RESET}"; exit 1; }
skip() { echo -e "  ${YELLOW}↷ $1${RESET}"; }

PLATFORM=$(uname -s)   # Darwin | Linux
KIT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
API_DIR="$CLAUDE_DIR/api-branch"
SKILLS_DIR="$CLAUDE_DIR/skills"
SETTINGS="$CLAUDE_DIR/settings.json"
NCS_DIR="$HOME/neural-command-system"

echo -e "\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD} Claude Power Kit v2 — Installer${RESET}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  Platform: $PLATFORM ($(uname -m))"

# ── 1. Python3 ────────────────────────────────────────────────
step "Python3"
PYTHON3=""
for candidate in \
  "$(which python3 2>/dev/null)" \
  "/opt/homebrew/bin/python3" \
  "/usr/local/bin/python3" \
  "/usr/bin/python3"; do
  [ -x "$candidate" ] && PYTHON3="$candidate" && break
done

if [ -z "$PYTHON3" ]; then
  if [ "$PLATFORM" = "Linux" ]; then
    warn "python3 not found — installing via apt"
    sudo apt-get update -qq && sudo apt-get install -y python3 python3-pip
    PYTHON3="$(which python3)"
  else
    err "Python3 not found. Install Python 3.11+ first: brew install python3"
  fi
fi
ok "Python3: $PYTHON3 ($(${PYTHON3} --version))"

# ── 2. Node.js ────────────────────────────────────────────────
step "Node.js"
NODE=""
for candidate in \
  "$(which node 2>/dev/null)" \
  "/opt/homebrew/bin/node" \
  "$HOME/.nvm/versions/node/$(ls "$HOME/.nvm/versions/node" 2>/dev/null | sort -V | tail -1)/bin/node" \
  "/usr/local/bin/node" \
  "/usr/bin/node"; do
  [ -x "$candidate" ] && NODE="$candidate" && break
done

if [ -z "$NODE" ]; then
  warn "Node.js not found — installing via nvm"
  export NVM_DIR="$HOME/.nvm"
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
  nvm install --lts && nvm use --lts
  NODE="$(which node)"
fi
export PATH="$(dirname "$NODE"):$PATH"
ok "Node: $NODE ($($NODE --version))"

# ── 3. bun (required by gstack) ───────────────────────────────
step "bun"
if ! command -v bun >/dev/null 2>&1 && [ ! -x "$HOME/.bun/bin/bun" ]; then
  warn "bun not found — installing"
  curl -fsSL https://bun.sh/install | bash
fi
export PATH="$HOME/.bun/bin:$PATH"
ok "bun $(bun --version 2>/dev/null || echo 'installed')"

# ── 4. Claude Code CLI ────────────────────────────────────────
step "Claude Code CLI"
if ! command -v claude >/dev/null 2>&1; then
  warn "claude not found — installing"
  npm install -g @anthropic-ai/claude-code
fi
ok "claude $(claude --version 2>/dev/null | head -1 || echo 'installed')"

# ── 5. Create directories ────────────────────────────────────
step "Directories"
mkdir -p "$HOOKS_DIR" "$HOOKS_DIR/gitnexus" "$API_DIR" "$SKILLS_DIR"
ok "~/.claude/hooks/, ~/.claude/api-branch/, ~/.claude/skills/"

# ── 6. Install hooks ─────────────────────────────────────────
step "Hooks"

cp "$KIT_DIR/hooks/preflight.sh" "$HOOKS_DIR/preflight.sh"
chmod +x "$HOOKS_DIR/preflight.sh"
ok "preflight.sh"

cp "$KIT_DIR/hooks/dev_rules_guard.sh" "$HOOKS_DIR/dev_rules_guard.sh"
chmod +x "$HOOKS_DIR/dev_rules_guard.sh"
ok "dev_rules_guard.sh"

cp "$KIT_DIR/hooks/power_kit_update_check.sh" "$HOOKS_DIR/power_kit_update_check.sh"
chmod +x "$HOOKS_DIR/power_kit_update_check.sh"
ok "power_kit_update_check.sh"

# Write installed-version marker for self-update check
if [ -f "$KIT_DIR/VERSION" ]; then
    cp "$KIT_DIR/VERSION" "$CLAUDE_DIR/.power-kit-version"
    ok "version marker: $(cat "$KIT_DIR/VERSION")"
fi

sed "s|__PYTHON3__|$PYTHON3|g" "$KIT_DIR/hooks/api_scan_hook.sh" > "$API_DIR/scan_hook.sh"
chmod +x "$API_DIR/scan_hook.sh"
ok "api_scan_hook.sh"

cp "$KIT_DIR/hooks/live_session_tracker.py" "$HOOKS_DIR/live_session_tracker.py"
chmod +x "$HOOKS_DIR/live_session_tracker.py"
ok "live_session_tracker.py"

cp "$KIT_DIR/hooks/session_title_generator.py" "$HOOKS_DIR/session_title_generator.py"
chmod +x "$HOOKS_DIR/session_title_generator.py"
ok "session_title_generator.py"

cp "$KIT_DIR/hooks/ncs_briefing.sh" "$HOOKS_DIR/ncs_briefing.sh"
chmod +x "$HOOKS_DIR/ncs_briefing.sh"
ok "ncs_briefing.sh"

cp "$KIT_DIR/hooks/gitnexus/gitnexus-hook.cjs" "$HOOKS_DIR/gitnexus/gitnexus-hook.cjs"
ok "gitnexus-hook.cjs"

cp "$KIT_DIR/api-branch/scanner.py" "$API_DIR/scanner.py"
chmod +x "$API_DIR/scanner.py"
if [ ! -f "$API_DIR/registry.json" ]; then
  cp "$KIT_DIR/api-branch/registry.template.json" "$API_DIR/registry.json"
  ok "api-branch registry.json (empty)"
else
  skip "api-branch registry.json already exists"
fi

# ── 7. gstack skills ─────────────────────────────────────────
step "gstack (slash commands: /terra /qa /ship /review /design-* ...)"
GSTACK_DIR="$SKILLS_DIR/gstack"
SKILLS_ZIP="$KIT_DIR/skills.zip"

if [ ! -f "$GSTACK_DIR/bin/gstack-update-check" ]; then
  mkdir -p "$SKILLS_DIR"
  if [ -f "$SKILLS_ZIP" ]; then
    warn "Installing gstack from bundled skills.zip"
    unzip -q "$SKILLS_ZIP" -d "$CLAUDE_DIR/"
    ok "Skills extracted from skills.zip"
    cd "$GSTACK_DIR" && ./setup && cd - >/dev/null
  else
    warn "Cloning gstack from GitHub"
    if git clone --depth 1 https://github.com/garrytan/gstack "$GSTACK_DIR" 2>/dev/null; then
      cd "$GSTACK_DIR" && ./setup && cd - >/dev/null
      ok "gstack cloned and set up"
    else
      warn "gstack clone failed — skills will be installed from bundled skills/ directory"
    fi
  fi
else
  skip "gstack already installed ($(cat "$GSTACK_DIR/VERSION" 2>/dev/null || echo 'unknown'))"
fi

# ── 8. Custom skills (not in gstack) ─────────────────────────
step "Custom skills (/ui-ux-pro-max /ops-manager /senior-dev-mode ...)"
BUNDLED_SKILLS_DIR="$KIT_DIR/skills"

if [ -d "$BUNDLED_SKILLS_DIR" ]; then
  for skill_dir in "$BUNDLED_SKILLS_DIR"/*/; do
    skill_name=$(basename "$skill_dir")
    target="$SKILLS_DIR/$skill_name"
    if [ ! -d "$target" ]; then
      cp -r "$skill_dir" "$target"
      ok "$skill_name"
    else
      # Overwrite to get latest version
      cp -r "$skill_dir" "$target"
      ok "$skill_name (updated)"
    fi
  done
else
  skip "No bundled skills/ directory found"
fi

# ── 9. GitNexus ──────────────────────────────────────────────
step "GitNexus (code knowledge graph)"
if command -v npm >/dev/null 2>&1; then
  if ! command -v gitnexus >/dev/null 2>&1; then
    npm install -g gitnexus 2>/dev/null && ok "gitnexus installed" \
      || warn "gitnexus install failed — run: npm install -g gitnexus"
  else
    skip "gitnexus already installed ($(gitnexus --version 2>/dev/null || echo 'unknown'))"
  fi
  if command -v gitnexus >/dev/null 2>&1; then
    gitnexus setup 2>/dev/null && ok "GitNexus MCP + hooks + skills configured" \
      || warn "gitnexus setup failed — run manually: gitnexus setup"
  fi
else
  warn "npm not found — install Node.js first, then: npm install -g gitnexus"
fi

# ── 10. NCS dashboard (Neural Command System) ────────────────
step "NCS Dashboard (agent roster + task queue at localhost:3777)"
if [ ! -d "$NCS_DIR" ]; then
  warn "Cloning NCS dashboard"
  if git clone --depth 1 git@github.com:rohit-vc26/IQ.git "$NCS_DIR" 2>/dev/null || \
     git clone --depth 1 https://github.com/rohit-vc26/IQ.git "$NCS_DIR" 2>/dev/null; then
    cd "$NCS_DIR"
    npm install --silent 2>/dev/null && ok "NCS dependencies installed" \
      || warn "NCS npm install failed — run: cd $NCS_DIR && npm install"
    cd - >/dev/null
    ok "NCS cloned to $NCS_DIR"
  else
    warn "NCS clone failed (private repo). Clone manually:"
    warn "  git clone git@github.com:rohit-vc26/IQ.git $NCS_DIR"
  fi
else
  skip "NCS already at $NCS_DIR"
fi

# ── 11. Memory templates ──────────────────────────────────────
step "Memory templates"
echo "  Templates at: $KIT_DIR/memory-templates/"
echo "  Usage: cp $KIT_DIR/memory-templates/*.md ~/.claude/projects/<project>/memory/"

# ── 12. Wire all hooks into settings.json ────────────────────
step "Wiring hooks into settings.json (6 events)"

if [ ! -f "$SETTINGS" ]; then
  echo '{}' > "$SETTINGS"
  ok "Created fresh settings.json"
fi

cp "$SETTINGS" "$SETTINGS.bak.$(date +%s)"

$PYTHON3 - << 'PYEOF'
import json, os

settings_path = os.path.expanduser("~/.claude/settings.json")

with open(settings_path) as f:
    s = json.load(f)

if "hooks" not in s:
    s["hooks"] = {}

def existing_cmds(event):
    cmds = set()
    for entry in s["hooks"].get(event, []):
        for h in entry.get("hooks", []):
            cmds.add(h.get("command", "").strip())
    return cmds

def add_hook(event, matcher, command, timeout, status_msg=None):
    if command.strip() in existing_cmds(event):
        return False
    if event not in s["hooks"]:
        s["hooks"][event] = []
    hook = {"type": "command", "command": command, "timeout": timeout}
    if status_msg:
        hook["statusMessage"] = status_msg
    s["hooks"][event].append({"matcher": matcher, "hooks": [hook]})
    return True

added = []
spec = [
    # SessionStart — order matters
    ("SessionStart", "", "~/.claude/skills/gstack/bin/gstack-update-check 2>/dev/null; mkdir -p ~/.gstack/sessions && touch ~/.gstack/sessions/\"$$\"; _LEARN=$(~/.claude/skills/gstack/bin/gstack-learnings-search --limit 3 2>/dev/null); [ -n \"$_LEARN\" ] && echo \"GSTACK_LEARNINGS: $_LEARN\" || true", 8000, None),
    ("SessionStart", "", "node ~/.claude/hooks/gitnexus/gitnexus-hook.cjs", 8000, "Checking GitNexus index freshness..."),
    ("SessionStart", "", "bash ~/.claude/hooks/ncs_briefing.sh", 10000, None),
    ("SessionStart", "", "python3 ~/.claude/hooks/live_session_tracker.py", 5000, None),
    ("SessionStart", "", "bash ~/.claude/hooks/preflight.sh", 5000, None),
    ("SessionStart", "", "bash ~/.claude/hooks/power_kit_update_check.sh", 4000, None),
    ("SessionStart", "", "bash ~/.claude/api-branch/scan_hook.sh", 8000, None),
    # UserPromptSubmit — tracker LIVE
    ("UserPromptSubmit", "", "python3 ~/.claude/hooks/live_session_tracker.py", 3000, None),
    # Notification — tracker WAITING/STALE
    ("Notification", "", "python3 ~/.claude/hooks/live_session_tracker.py", 3000, None),
    # PreToolUse — gitnexus enrichment
    ("PreToolUse", "Grep|Glob|Bash", "node ~/.claude/hooks/gitnexus/gitnexus-hook.cjs", 10, "Enriching with GitNexus graph context..."),
    # PreToolUse — dev rules guard (em-dash, max-3-files, gitnexus-impact reminders)
    ("PreToolUse", "Edit|Write|NotebookEdit|Bash", "bash ~/.claude/hooks/dev_rules_guard.sh", 3000, None),
    # PostToolUse — gitnexus stale detection
    ("PostToolUse", "Bash", "node ~/.claude/hooks/gitnexus/gitnexus-hook.cjs", 10, "Checking GitNexus index freshness..."),
    # Stop + SessionEnd
    ("Stop", "", "python3 ~/.claude/hooks/live_session_tracker.py", 5000, None),
    ("SessionEnd", "", "python3 ~/.claude/hooks/live_session_tracker.py", 5000, None),
    ("SessionEnd", "", "python3 ~/.claude/hooks/session_title_generator.py", 15000, None),
]

for event, matcher, cmd, timeout, msg in spec:
    if add_hook(event, matcher, cmd, timeout, msg):
        added.append(f"  + [{event}] {cmd[:55]}")

with open(settings_path, "w") as f:
    json.dump(s, f, indent=2)

if added:
    print(f"  Added {len(added)} hooks:")
    for h in added:
        print(h)
else:
    print("  All hooks already present — no changes")
PYEOF

# ── 13. Global CLAUDE.md template ────────────────────────────
step "Global CLAUDE.md"
if [ ! -f "$CLAUDE_DIR/CLAUDE.md" ]; then
  cp "$KIT_DIR/templates/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
  ok "Installed global CLAUDE.md"
else
  skip "CLAUDE.md already exists (merge manually if needed)"
  echo "  Template at: $KIT_DIR/templates/CLAUDE.md"
fi

# ── Summary ───────────────────────────────────────────────────
echo -e "\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}${GREEN} INSTALLED ✓${RESET}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo "  Session boot fires (in order):"
echo "    1. gstack-update-check  — skill updates"
echo "    2. gitnexus             — index freshness (STALE/FRESH)"
echo "    3. ncs_briefing         — agent roster + task count"
echo "    4. live_session_tracker — Karma STARTING state"
echo "    5. preflight            — atlas/protocol/memory check"
echo "    6. api_scan_hook        — API registry status"
echo ""
echo "  Slash commands: /terra /qa /ship /review /investigate"
echo "    /design-* /ops-manager /ui-ux-pro-max /gitnexus-* ..."
echo ""
echo "  Next steps:"
echo "    1. Index your project:"
echo "       cd /your/project && npx gitnexus analyze"
echo ""
echo "    2. Register APIs:"
echo "       python3 $API_DIR/scanner.py --add-project myproject /path/to/project"
echo "       python3 $API_DIR/scanner.py --scan --tree"
echo ""
echo "    3. Start NCS dashboard:"
echo "       cd $NCS_DIR && npm run dev"
echo "       Open: http://localhost:3777"
echo ""
echo "    4. Copy memory templates to a project:"
echo "       cp $KIT_DIR/memory-templates/*.md ~/.claude/projects/<project>/memory/"
echo ""
echo "  Settings backup at: $SETTINGS.bak.*"
echo ""
