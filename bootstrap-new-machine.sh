#!/bin/bash
# bootstrap-new-machine.sh - one-shot mirror of your Claude Code workflow on
# a fresh machine.
#
# Run this AFTER `bash install.sh`. It does:
#   1. Install the claude-mem plugin (memory MCP)
#   2. Prompt for your private memory-backup repo URL (no defaults baked in)
#   3. Restore claude-mem DB + project memory dirs from that repo
#   4. List the project memory dirs that came back so you know which repos
#      to clone manually + index with GitNexus
#
# Generic by design - no project names, no usernames, no machine-specific
# paths. Works for any user who installed the kit.
#
# Usage:
#   bash bootstrap-new-machine.sh
#
# Idempotent: safe to re-run. Each step skips work that's already done.

set -u

CONFIG="$HOME/.claude/.power-kit-config"
RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; DIM=$'\033[2m'; RST=$'\033[0m'

step()  { echo; echo "${YELLOW}==>${RST} $*"; }
ok()    { echo "  ${GREEN}OK${RST}  $*"; }
skip()  { echo "  ${DIM}--  $* (skipped)${RST}"; }
fail()  { echo "  ${RED}!!${RST}  $*" >&2; }

# ── 0. sanity ──────────────────────────────────────────────────────────────
if ! command -v claude >/dev/null 2>&1; then
    fail "claude CLI not on PATH. Install Claude Code first, then re-run."
    exit 1
fi
if [ ! -f "$CONFIG" ]; then
    fail "$CONFIG not found. Run \`bash install.sh\` from this directory first."
    exit 1
fi

# ── 1. claude-mem plugin ───────────────────────────────────────────────────
step "claude-mem plugin"
if claude plugin list 2>/dev/null | grep -q "claude-mem"; then
    skip "claude-mem already installed"
else
    if claude plugin install thedotmack/claude-mem 2>&1 | tail -3; then
        ok "claude-mem installed"
    else
        fail "claude-mem install failed - check 'claude /plugin install thedotmack/claude-mem' manually"
    fi
fi

# ── 2. memory backup repo ──────────────────────────────────────────────────
step "memory backup repo"
# shellcheck disable=SC1090
. "$CONFIG"
REPO="${POWER_KIT_GIT_BACKUP_REPO:-}"

if [ -z "$REPO" ]; then
    echo "  Your private memory-backup repo URL is needed to restore."
    echo "  Format: git@github.com:<you>/<your-private-repo>.git"
    echo -n "  Repo URL (or blank to skip): "
    read -r REPO
    if [ -n "$REPO" ]; then
        # Persist into config so future restores don't re-prompt
        if grep -q "^POWER_KIT_GIT_BACKUP_REPO=" "$CONFIG"; then
            sed -i.bak "s|^POWER_KIT_GIT_BACKUP_REPO=.*|POWER_KIT_GIT_BACKUP_REPO=\"$REPO\"|" "$CONFIG" && rm -f "${CONFIG}.bak"
        else
            echo "POWER_KIT_GIT_BACKUP_REPO=\"$REPO\"" >> "$CONFIG"
        fi
        # Also flip backup ON for future sessions
        if grep -q "^POWER_KIT_GIT_BACKUP_ENABLED=" "$CONFIG"; then
            sed -i.bak "s/^POWER_KIT_GIT_BACKUP_ENABLED=.*/POWER_KIT_GIT_BACKUP_ENABLED=true/" "$CONFIG" && rm -f "${CONFIG}.bak"
        fi
        ok "saved to $CONFIG"
    fi
fi

# ── 3. restore memory ──────────────────────────────────────────────────────
step "restore memory"
if [ -z "$REPO" ]; then
    skip "no repo URL provided - run \`power-kit-memory-restore\` later when you have one"
elif [ ! -x "$HOME/.local/bin/power-kit-memory-restore" ]; then
    fail "power-kit-memory-restore not in ~/.local/bin/ - re-run install.sh"
else
    if [ -s "$HOME/.claude-mem/claude-mem.db" ]; then
        skip "claude-mem.db already populated - skipping restore (use --force to overwrite)"
    else
        "$HOME/.local/bin/power-kit-memory-restore" --from-git || fail "restore failed - run manually"
    fi
fi

# ── 4. surface restored projects ───────────────────────────────────────────
step "projects restored"
PROJ_DIR="$HOME/.claude/projects"
if [ -d "$PROJ_DIR" ]; then
    # Find every <encoded-path>/memory dir and decode the path back to a real fs path
    found=0
    for d in "$PROJ_DIR"/*/memory; do
        [ -d "$d" ] || continue
        encoded=$(basename "$(dirname "$d")")
        # Encoded form is "-path-with-dashes" - reverse to "/path/with/dashes"
        decoded=$(echo "$encoded" | sed 's|^-||; s|-|/|g; s|^|/|')
        echo "  ${decoded}"
        if [ ! -d "$decoded" ]; then
            echo "    ${DIM}-> not present on this machine. Clone the repo to ${decoded} then run \`npx gitnexus analyze\`${RST}"
        else
            echo "    ${GREEN}-> present. Run \`cd ${decoded} && npx gitnexus analyze\` to index${RST}"
        fi
        found=$((found+1))
    done
    if [ "$found" -eq 0 ]; then
        skip "no project memory dirs found yet"
    else
        echo
        ok "$found project(s) restored"
    fi
fi

# ── done ───────────────────────────────────────────────────────────────────
echo
echo "${GREEN}Bootstrap complete.${RST}"
echo
echo "Next steps:"
echo "  1. Clone any project repos listed above to the suggested paths"
echo "  2. Run \`npx gitnexus analyze\` in each to index its code graph"
echo "  3. Open Claude Code in any of them and your memory + workflow follow"
