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
FULL_INSTALL=false
for arg in "$@"; do [ "$arg" = "--full" ] && FULL_INSTALL=true; done
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

# v3.2: memory backup + health hooks
mkdir -p "$HOOKS_DIR/lib"
cp "$KIT_DIR/hooks/lib/secret_scan.sh" "$HOOKS_DIR/lib/secret_scan.sh"
chmod +x "$HOOKS_DIR/lib/secret_scan.sh"
ok "lib/secret_scan.sh"

cp "$KIT_DIR/hooks/memory_sync.sh" "$HOOKS_DIR/memory_sync.sh"
chmod +x "$HOOKS_DIR/memory_sync.sh"
ok "memory_sync.sh"

cp "$KIT_DIR/hooks/memory_git_backup.sh" "$HOOKS_DIR/memory_git_backup.sh"
chmod +x "$HOOKS_DIR/memory_git_backup.sh"
ok "memory_git_backup.sh"

cp "$KIT_DIR/hooks/memory_health.sh" "$HOOKS_DIR/memory_health.sh"
chmod +x "$HOOKS_DIR/memory_health.sh"
ok "memory_health.sh"

# Restore CLI in PATH
mkdir -p "$HOME/.local/bin"
cp "$KIT_DIR/bin/power-kit-memory-restore" "$HOME/.local/bin/power-kit-memory-restore"
chmod +x "$HOME/.local/bin/power-kit-memory-restore"
ok "bin: power-kit-memory-restore (in ~/.local/bin)"

# Memory backup config — only ask once on first install
PK_CONFIG="$CLAUDE_DIR/.power-kit-config"
if [ ! -f "$PK_CONFIG" ]; then
    OS_KIND=$(uname -s)
    case "$OS_KIND" in
        Darwin)  DEFAULT_BAK="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Claude-Memory-Backup" ;;
        Linux)
            if [ -d "/mnt/c/Users" ]; then
                # WSL: pick first OneDrive folder we can find
                ONEDRIVE=$(find /mnt/c/Users -maxdepth 3 -type d -name "OneDrive*" 2>/dev/null | head -1)
                DEFAULT_BAK="${ONEDRIVE:-$HOME/Dropbox}/Claude-Memory-Backup"
            else
                DEFAULT_BAK="$HOME/Dropbox/Claude-Memory-Backup"
            fi
            ;;
        *) DEFAULT_BAK="$HOME/Claude-Memory-Backup" ;;
    esac
    cat > "$PK_CONFIG" <<EOC
# claude-power-kit config (v3.2+) — edit to enable memory backup
# Cloud-folder sync (rsync to local cloud-synced folder, runs on SessionEnd)
POWER_KIT_BACKUP_ENABLED=false
POWER_KIT_BACKUP_DIR="$DEFAULT_BAK"
POWER_KIT_BACKUP_MIN_INTERVAL=600

# Private GitHub repo backup (weekly, runs on SessionStart)
POWER_KIT_GIT_BACKUP_ENABLED=false
POWER_KIT_GIT_BACKUP_REPO=""
POWER_KIT_GIT_BACKUP_INTERVAL=604800
EOC
    chmod 600 "$PK_CONFIG"
    ok "config: $PK_CONFIG (backups disabled by default - edit to enable)"
fi

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
    ( cd "$GSTACK_DIR" && ./setup --no-prefix 2>/dev/null ) || warn "gstack full setup skipped (bun/Playwright not ready) — skills will be linked in step 8b"
  else
    warn "Cloning gstack from GitHub"
    if git clone --depth 1 https://github.com/garrytan/gstack "$GSTACK_DIR" 2>/dev/null; then
      ok "gstack cloned"
      if ( cd "$GSTACK_DIR" && ./setup --no-prefix 2>/dev/null ); then
        ok "gstack full setup complete (browse binary built)"
      else
        warn "gstack full setup skipped (bun/Playwright not ready) — skills will be linked in step 8b"
      fi
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

# ── 8b. Guarantee all skills are linked as /slash commands ───
# Runs unconditionally after steps 7+8. Links every SKILL.md found under
# ~/.claude/skills/gstack/* directly into ~/.claude/skills/<name>/ so that
# Claude Code discovers them as top-level commands (/terra, /qa, /ship …).
# This is a pure-bash fallback — works even when bun/Playwright setup failed.
step "Registering all skills as /slash commands"
_linked=0
_already=0

if [ -d "$GSTACK_DIR" ]; then
  for _skill_dir in "$GSTACK_DIR"/*/; do
    [ -f "$_skill_dir/SKILL.md" ] || continue
    _name=$(basename "$_skill_dir")
    [ "$_name" = "node_modules" ] && continue
    _target="$SKILLS_DIR/$_name"
    mkdir -p "$_target"
    if [ ! -e "$_target/SKILL.md" ]; then
      ln -snf "$(cd "$_skill_dir" && pwd)/SKILL.md" "$_target/SKILL.md"
      _linked=$((_linked + 1))
    else
      _already=$((_already + 1))
    fi
  done
  ok "gstack skills: $_linked newly linked, $_already already active"
else
  warn "gstack dir not found — no gstack skills to link"
fi

# Verify custom bundled skills have SKILL.md present
_custom=0
if [ -d "$BUNDLED_SKILLS_DIR" ]; then
  for _skill_dir in "$BUNDLED_SKILLS_DIR"/*/; do
    _name=$(basename "$_skill_dir")
    [ -f "$SKILLS_DIR/$_name/SKILL.md" ] && _custom=$((_custom + 1)) || true
  done
  ok "custom bundled skills: $_custom registered (/ui-ux-pro-max /ops-manager /senior-dev-mode ...)"
fi

# ── 8c. Terra + NCS workflow activation ─────────────────────
# Initializes the gstack config + state dirs that terra's preamble
# reads on every /terra invocation. All gstack bin/* tools are bash
# scripts — no bun required. Also checks NCS status so terra can
# log tasks to the dashboard immediately after install.
step "Terra + NCS workflow activation"
GSTACK_HOME="$HOME/.gstack"
GSTACK_BIN="$SKILLS_DIR/gstack/bin"
GSTACK_CONFIG_BIN="$GSTACK_BIN/gstack-config"

# Create the ~/.gstack/ state dirs terra's preamble expects
mkdir -p "$GSTACK_HOME/sessions" "$GSTACK_HOME/projects" "$GSTACK_HOME/analytics"
ok "~/.gstack/ state dirs (sessions/ projects/ analytics/)"

# Initialize gstack config using the bash script — works without bun
if [ -x "$GSTACK_CONFIG_BIN" ]; then
  "$GSTACK_CONFIG_BIN" set proactive     true     2>/dev/null && ok "gstack config: proactive=true"     || warn "gstack-config set proactive failed"
  "$GSTACK_CONFIG_BIN" set skill_prefix  false    2>/dev/null && ok "gstack config: skill_prefix=false"  || warn "gstack-config set skill_prefix failed"
  "$GSTACK_CONFIG_BIN" set telemetry     off      2>/dev/null && ok "gstack config: telemetry=off"       || warn "gstack-config set telemetry failed"
  "$GSTACK_CONFIG_BIN" set checkpoint_mode explicit 2>/dev/null || true
else
  warn "gstack-config not found at $GSTACK_CONFIG_BIN — skipping config init (gstack clone may have failed)"
fi

# NCS status check — terra logs tasks to localhost:3777
if curl -sf http://localhost:3777/api/health >/dev/null 2>&1; then
  ok "NCS dashboard live at localhost:3777 — terra task logging active"
elif [ -d "$NCS_DIR" ] && [ -f "$NCS_DIR/package.json" ]; then
  warn "NCS installed but not running"
  echo -e "  ${YELLOW}→ Start it: cd $NCS_DIR && npm run dev${RESET}"
  echo -e "  ${YELLOW}  Terra will log to localhost:3777 once NCS is up${RESET}"
else
  warn "NCS not found — terra will work offline (no dashboard logging)"
  echo -e "  ${YELLOW}→ Clone: git clone git@github.com:rohit-vc26/IQ.git $NCS_DIR${RESET}"
fi

ok "Terra ready — run /terra in any Claude Code session to activate the NCS workflow"

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

FULL_INSTALL=$FULL_INSTALL $PYTHON3 - << 'PYEOF'
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
full_install = os.environ.get('FULL_INSTALL', 'false') == 'true'
lean_spec = [
    ("SessionStart", "", "node ~/.claude/hooks/gitnexus/gitnexus-hook.cjs", 8000, "Checking GitNexus index freshness..."),
    ("SessionStart", "", "bash ~/.claude/hooks/preflight.sh", 5000, None),
    ("PreToolUse", "Edit|Write|NotebookEdit", "bash ~/.claude/hooks/dev_rules_guard.sh", 3000, None),
    ("SessionEnd", "", "python3 ~/.claude/hooks/session_title_generator.py", 15000, None),
]
full_spec = [
    ("SessionStart", "", "~/.claude/skills/gstack/bin/gstack-update-check 2>/dev/null; mkdir -p ~/.gstack/sessions && touch ~/.gstack/sessions/\"$$\"; _LEARN=$(~/.claude/skills/gstack/bin/gstack-learnings-search --limit 3 2>/dev/null); [ -n \"$_LEARN\" ] && echo \"GSTACK_LEARNINGS: $_LEARN\" || true", 8000, None),
    ("SessionStart", "", "node ~/.claude/hooks/gitnexus/gitnexus-hook.cjs", 8000, "Checking GitNexus index freshness..."),
    ("SessionStart", "", "bash ~/.claude/hooks/ncs_briefing.sh", 10000, None),
    ("SessionStart", "", "python3 ~/.claude/hooks/live_session_tracker.py", 5000, None),
    ("SessionStart", "", "bash ~/.claude/hooks/preflight.sh", 5000, None),
    ("SessionStart", "", "bash ~/.claude/hooks/memory_health.sh", 4000, None),
    ("SessionStart", "", "bash ~/.claude/hooks/power_kit_update_check.sh", 4000, None),
    ("SessionStart", "", "bash ~/.claude/hooks/memory_git_backup.sh", 6000, None),
    ("SessionStart", "", "bash ~/.claude/api-branch/scan_hook.sh", 8000, None),
    ("SessionEnd", "", "bash ~/.claude/hooks/memory_sync.sh", 6000, None),
    ("UserPromptSubmit", "", "python3 ~/.claude/hooks/live_session_tracker.py", 3000, None),
    ("Notification", "", "python3 ~/.claude/hooks/live_session_tracker.py", 3000, None),
    ("PreToolUse", "Grep|Glob|Bash", "node ~/.claude/hooks/gitnexus/gitnexus-hook.cjs", 10, "Enriching with GitNexus graph context..."),
    ("PreToolUse", "Edit|Write|NotebookEdit|Bash", "bash ~/.claude/hooks/dev_rules_guard.sh", 3000, None),
    ("PostToolUse", "Bash", "node ~/.claude/hooks/gitnexus/gitnexus-hook.cjs", 10, "Checking GitNexus index freshness..."),
    ("Stop", "", "python3 ~/.claude/hooks/live_session_tracker.py", 5000, None),
    ("SessionEnd", "", "python3 ~/.claude/hooks/live_session_tracker.py", 5000, None),
    ("SessionEnd", "", "python3 ~/.claude/hooks/session_title_generator.py", 15000, None),
]
spec = full_spec if full_install else lean_spec

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
if [ "$FULL_INSTALL" = "true" ]; then
  echo "  Install mode: FULL (all hooks)"
else
  echo "  Install mode: LEAN - 4 hooks, minimal context burn"
  echo "  For full suite: bash install.sh --full"
fi
echo ""
echo "  Slash commands: /terra /qa /ship /review /investigate"
echo "    /design-* /ops-manager /ui-ux-pro-max /gitnexus-* ..."
echo ""
echo -e "  ${BOLD}Start the workflow:${RESET}"
echo "    1. Start NCS dashboard (terra needs this to log tasks):"
echo "       cd $NCS_DIR && npm run dev"
echo "       Open: http://localhost:3777"
echo ""
echo "    2. Open Claude Code in any project and type:"
echo "       /terra"
echo "       Terra reads the situation, picks the right agent, and delegates."
echo ""
echo -e "  ${BOLD}Other setup:${RESET}"
echo "    3. Index your project for GitNexus:"
echo "       cd /your/project && npx gitnexus analyze"
echo ""
echo "    4. Register APIs:"
echo "       python3 $API_DIR/scanner.py --add-project myproject /path/to/project"
echo "       python3 $API_DIR/scanner.py --scan --tree"
echo ""
echo "    5. Copy memory templates to a project:"
echo "       cp $KIT_DIR/memory-templates/*.md ~/.claude/projects/<project>/memory/"
echo ""
echo "  Settings backup at: $SETTINGS.bak.*"
echo ""
