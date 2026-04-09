#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PRE-FLIGHT CHECKLIST -- SessionStart hook
# Forces Claude to read atlas + protocol before coding.
# Paths are auto-detected from $PWD.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PROJECT_DIR="${PWD}"
PROJECT_NAME=$(basename "$PROJECT_DIR")

# Derive the Claude memory path for this project
# Claude Code uses: ~/.claude/projects/-<path-with-dashes>/memory/
ENCODED_PATH=$(echo "$PROJECT_DIR" | sed 's|^/||' | tr '/' '-')
MEMORY_DIR="$HOME/.claude/projects/-${ENCODED_PATH}/memory"
MEMORY_INDEX="$MEMORY_DIR/MEMORY.md"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " PRE-FLIGHT CHECKLIST"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Project: $PROJECT_NAME"
echo ""

# Check for atlas
ATLAS=$(find "$MEMORY_DIR" -maxdepth 1 -name "*atlas*" 2>/dev/null | head -1)
if [ -n "$ATLAS" ]; then
    echo " ATLAS     Found -> READ $(basename "$ATLAS") FIRST"
else
    echo " ATLAS     Not found -- create one with project architecture details"
fi

# Check for protocol
PROTOCOL=$(find "$MEMORY_DIR" -maxdepth 1 -name "*protocol*" 2>/dev/null | head -1)
if [ -n "$PROTOCOL" ]; then
    echo " PROTOCOL  Found -> READ $(basename "$PROTOCOL") before coding"
else
    echo " PROTOCOL  Not found -- create one from memory-templates/feedback_dev_protocol.md"
fi

# Count memory entries
if [ -f "$MEMORY_INDEX" ]; then
    COUNT=$(grep -c '^\- \[' "$MEMORY_INDEX" 2>/dev/null || echo "0")
    echo " MEMORY    $COUNT entries indexed in MEMORY.md"
else
    echo " MEMORY    No MEMORY.md found -- initialize memory system"
fi

echo ""
echo " BEFORE ANY FEATURE WORK:"
echo "   1. Read atlas + protocol + MEMORY.md"
echo "   2. Ask user for source docs (PDF/Postman/Notion)"
echo "   3. Verify API endpoints with curl BEFORE coding"
echo "   4. Build incrementally -- max 3 items per deploy"
echo "   5. Save session snapshot before context fills"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
