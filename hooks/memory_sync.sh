#!/bin/bash
# memory_sync.sh - SessionEnd hook. rsync claude-mem DB + project memory dirs
# to $POWER_KIT_BACKUP_DIR (local cloud-synced folder).
#
# Reads config from ~/.claude/.power-kit-config:
#   POWER_KIT_BACKUP_DIR=<path>     # required, set by install.sh
#   POWER_KIT_BACKUP_ENABLED=true   # off-switch
#
# Skips silently when:
#   - config missing or BACKUP_ENABLED != true
#   - BACKUP_DIR doesn't exist (e.g. iCloud not signed in on this Mac)
#   - rsync not on PATH
#
# Throttled: skips if last sync was less than POWER_KIT_BACKUP_MIN_INTERVAL
# seconds ago (default 600 = 10 min). SessionEnd fires often; we don't need
# to flood the cloud every time.

set -u

CONFIG="$HOME/.claude/.power-kit-config"
[ -f "$CONFIG" ] || exit 0
# shellcheck disable=SC1090
. "$CONFIG"
[ "${POWER_KIT_BACKUP_ENABLED:-false}" = "true" ] || exit 0
[ -n "${POWER_KIT_BACKUP_DIR:-}" ] || exit 0
[ -d "$POWER_KIT_BACKUP_DIR" ] || exit 0
command -v rsync >/dev/null 2>&1 || exit 0

INTERVAL="${POWER_KIT_BACKUP_MIN_INTERVAL:-600}"
STAMP="$HOME/.claude/.power-kit-last-sync"
if [ -f "$STAMP" ]; then
    NOW=$(date +%s)
    LAST=$(cat "$STAMP" 2>/dev/null || echo 0)
    if [ "$((NOW - LAST))" -lt "$INTERVAL" ]; then
        exit 0
    fi
fi

DEST="$POWER_KIT_BACKUP_DIR"
mkdir -p "$DEST/claude-mem" "$DEST/projects" 2>/dev/null

# 1. claude-mem SQLite DB + Chroma vectors
if [ -d "$HOME/.claude-mem" ]; then
    rsync -a --delete \
        --exclude='*.db-shm' --exclude='*.db-wal' \
        --exclude='logs/' --exclude='worker.pid' \
        "$HOME/.claude-mem/" "$DEST/claude-mem/" 2>/dev/null
fi

# 2. Project memory dirs (markdown only, no compiled cache)
if [ -d "$HOME/.claude/projects" ]; then
    # shellcheck disable=SC1091
    . "$(dirname "$0")/lib/secret_scan.sh" 2>/dev/null || true

    find "$HOME/.claude/projects" -type d -name "memory" 2>/dev/null | while read -r src; do
        rel=$(echo "$src" | sed "s|^$HOME/.claude/projects/||")
        out="$DEST/projects/$rel"
        mkdir -p "$out"
        # Per-file copy with secret redaction (only on .md/.json/.jsonl)
        find "$src" -maxdepth 1 -type f 2>/dev/null | while read -r f; do
            base=$(basename "$f")
            case "$base" in
                *.md|*.json|*.jsonl|*.txt)
                    if command -v has_secrets >/dev/null 2>&1 && has_secrets "$f"; then
                        filter_secrets "$f" "$out/$base"
                    else
                        cp "$f" "$out/$base"
                    fi
                    ;;
                *)
                    cp "$f" "$out/$base" 2>/dev/null
                    ;;
            esac
        done
    done
fi

# 3. Update sync stamp
date +%s > "$STAMP"

exit 0
