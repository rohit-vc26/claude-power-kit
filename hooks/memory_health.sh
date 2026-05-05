#!/bin/bash
# memory_health.sh - SessionStart hook. Adds 4 lines of memory-system health
# to the session briefing. Catches breakage early (worker dead, sync stalled,
# DB bloated) before you notice from missing recall.

set -u

CONFIG="$HOME/.claude/.power-kit-config"
[ -f "$CONFIG" ] && . "$CONFIG" 2>/dev/null

DB="$HOME/.claude-mem/claude-mem.db"
WORKER_PID="$HOME/.claude-mem/worker.pid"
SYNC_STAMP="$HOME/.claude/.power-kit-last-sync"
GIT_STAMP="$HOME/.claude/.power-kit-last-git-push"

# DB stats
if [ -f "$DB" ]; then
    SIZE=$(du -h "$DB" 2>/dev/null | awk '{print $1}')
    OBS_COUNT="?"
    if command -v sqlite3 >/dev/null 2>&1; then
        OBS_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM observations" 2>/dev/null || echo "?")
    fi
    echo "MEMORY    claude-mem db: $SIZE, $OBS_COUNT observations"
else
    echo "MEMORY    claude-mem db: missing (run 'claude /restart-mem' or restore)"
fi

# Watcher worker liveness — claude-mem stores worker.pid as JSON like
# {"pid": 30377, "port": ..., "startedAt": ...}, so extract pid field.
if [ -f "$WORKER_PID" ]; then
    PID=$(grep -oE '"pid"[[:space:]]*:[[:space:]]*[0-9]+' "$WORKER_PID" 2>/dev/null | grep -oE '[0-9]+$')
    if [ -z "$PID" ]; then
        # Fallback: maybe it's a plain integer file
        PID=$(tr -dc '0-9' < "$WORKER_PID" 2>/dev/null | head -c 10)
    fi
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        echo "WATCHER   pid $PID alive"
    elif [ -n "$PID" ]; then
        echo "WATCHER   pid $PID DEAD - sessions not being indexed"
    else
        echo "WATCHER   pid file unreadable"
    fi
else
    echo "WATCHER   no pid file - claude-mem worker not running"
fi

# Last cloud-folder sync
if [ -f "$SYNC_STAMP" ]; then
    AGE=$(( $(date +%s) - $(cat "$SYNC_STAMP" 2>/dev/null || echo 0) ))
    if [ "$AGE" -lt 3600 ]; then     LBL="$((AGE/60))m ago"
    elif [ "$AGE" -lt 86400 ]; then LBL="$((AGE/3600))h ago"
    else                              LBL="$((AGE/86400))d ago"; fi
    echo "BACKUP    cloud sync: $LBL"
elif [ "${POWER_KIT_BACKUP_ENABLED:-false}" = "true" ]; then
    echo "BACKUP    cloud sync: never (will run on next session end)"
fi

# Last git push
if [ -f "$GIT_STAMP" ]; then
    AGE=$(( $(date +%s) - $(cat "$GIT_STAMP" 2>/dev/null || echo 0) ))
    DAYS=$((AGE/86400))
    if [ "$DAYS" -gt 14 ]; then
        echo "GIT BACK  last push: ${DAYS}d ago - check git remote"
    elif [ "$DAYS" -ge 1 ]; then
        echo "GIT BACK  last push: ${DAYS}d ago"
    fi
fi

exit 0
