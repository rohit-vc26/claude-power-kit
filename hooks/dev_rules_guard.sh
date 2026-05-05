#!/bin/bash
# dev_rules_guard.sh - PreToolUse hook that enforces the dev protocol.
#
# Catches the slips that passive CLAUDE.md text reminders miss:
#   1. Editing source code without running gitnexus_impact first
#   2. Deploying more than 3 files in a single Bash command
#   3. Drifting from "no em dashes" rule by emitting one in tool input
#
# The hook reads the PreToolUse JSON from stdin and emits a system-reminder
# block to stderr when a rule is at risk. It never blocks (exit 0 always);
# Claude sees the reminder and self-corrects.
#
# Wire in settings.json under PreToolUse with matcher "Edit|Write|Bash".

set -u

# Read tool call JSON from stdin
INPUT=$(cat 2>/dev/null || echo "{}")

TOOL_NAME=$(echo "$INPUT" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('tool_name',''))" 2>/dev/null)
WARN=""

# ── Rule 1: source-code edits should follow gitnexus_impact ──────────────────
if [ "$TOOL_NAME" = "Edit" ] || [ "$TOOL_NAME" = "Write" ] || [ "$TOOL_NAME" = "NotebookEdit" ]; then
    FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null)
    case "$FILE_PATH" in
        *.py|*.js|*.jsx|*.ts|*.tsx)
            # Only warn for files inside an app/src/lib tree (skip configs, tests)
            case "$FILE_PATH" in
                */app/*|*/src/*|*/lib/*|*/services/*|*/routers/*|*/models/*)
                    WARN="${WARN}DEV RULE CHECK: editing $FILE_PATH. Did you run gitnexus_impact on the touched symbol? If d=1 risk is HIGH/CRITICAL, surface it before editing.\n"
                    ;;
            esac
            ;;
    esac
fi

# ── Rule 2: max 3 files per deploy batch ─────────────────────────────────────
if [ "$TOOL_NAME" = "Bash" ]; then
    CMD=$(echo "$INPUT" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('tool_input',{}).get('command',''))" 2>/dev/null)

    # Count file args in scp/rsync/cp commands targeted at remote or build dirs
    if echo "$CMD" | grep -qE '^(scp|rsync)\b'; then
        FILE_COUNT=$(echo "$CMD" | grep -oE '\.(py|js|jsx|ts|tsx|sh|json|md)\b' | wc -l | tr -d ' ')
        if [ "$FILE_COUNT" -gt 3 ]; then
            WARN="${WARN}DEV RULE CHECK: deploy batch has $FILE_COUNT files. Rule says max 3 per deploy. Split the batch unless this is a coordinated rollout.\n"
        fi
    fi
fi

# ── Rule 3: catch em dashes leaking into tool inputs ─────────────────────────
# The "—" character (U+2014) is banned per project preference.
if echo "$INPUT" | grep -q '—'; then
    WARN="${WARN}DEV RULE CHECK: em dash detected in tool input. Project rule: use hyphen (-) not em dash (—). Replace before continuing.\n"
fi

# Emit system reminder if any rule fired
if [ -n "$WARN" ]; then
    # PreToolUse hooks: stderr text becomes additional system-reminder context
    printf "DEV RULE REMINDERS:\n%b" "$WARN" 1>&2
fi

exit 0
