#!/bin/bash
# Pre-flight checklist -- outputs at every session start
# Forces Claude to see the dev protocol before writing any code

PROJECT_DIR="$(pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"

# Claude Code encodes project paths as: -Users-solvix-Desktop-projectname
ENCODED_PATH=$(echo "$PROJECT_DIR" | sed 's|^/||' | tr '/' '-')
MEMORY_DIR="$HOME/.claude/projects/-${ENCODED_PATH}/memory"

BAR="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
HAS_ATLAS=0; HAS_PROTO=0; MEM_COUNT=0

[ -f "$MEMORY_DIR/reference_project_atlas.md" ] && HAS_ATLAS=1
[ -f "$MEMORY_DIR/feedback_dev_protocol.md" ]   && HAS_PROTO=1

# No project context: print minimal notice (4 lines) and exit
if [ "$HAS_ATLAS" -eq 0 ] && [ "$HAS_PROTO" -eq 0 ]; then
    echo "$BAR"
    echo " PRE-FLIGHT  $PROJECT_NAME"
    echo " WARNING   No atlas or protocol found for this project"
    echo "$BAR"
    exit 0
fi

# Project context found: print full checklist
echo "$BAR"
echo " PRE-FLIGHT CHECKLIST  ($PROJECT_NAME)"
echo "$BAR"
[ "$HAS_ATLAS" -eq 1 ] && echo " ATLAS     Found -> READ reference_project_atlas.md FIRST"
[ "$HAS_PROTO" -eq 1 ] && echo " PROTOCOL  Found -> READ feedback_dev_protocol.md before coding"
if [ -f "$MEMORY_DIR/MEMORY.md" ]; then
    MEM_COUNT=$(grep -c "^-" "$MEMORY_DIR/MEMORY.md" 2>/dev/null || echo "0")
    echo " MEMORY    $MEM_COUNT entries indexed in MEMORY.md"
fi
echo ""
echo " BEFORE CODING: read atlas + protocol + MEMORY.md | verify APIs with curl | max 3 files/deploy"
echo " RULES: no em dashes | run gitnexus_impact before edits | run gitnexus_detect_changes before deploy"
echo "$BAR"
