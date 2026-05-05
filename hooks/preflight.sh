#!/bin/bash
# Pre-flight checklist -- outputs at every session start
# Forces Claude to see the dev protocol before writing any code

PROJECT_DIR="$(pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"

# Claude Code encodes project paths as: -Users-solvix-Desktop-projectname
ENCODED_PATH=$(echo "$PROJECT_DIR" | sed 's|^/||' | tr '/' '-')
MEMORY_DIR="$HOME/.claude/projects/-${ENCODED_PATH}/memory"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " PRE-FLIGHT CHECKLIST"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Project: $PROJECT_NAME"
echo ""

# Check what exists
HAS_ATLAS=0; HAS_PROTO=0; MEM_COUNT=0

if [ -f "$MEMORY_DIR/reference_project_atlas.md" ]; then
    HAS_ATLAS=1
    echo " ATLAS     Found -> READ reference_project_atlas.md FIRST"
fi

if [ -f "$MEMORY_DIR/feedback_dev_protocol.md" ]; then
    HAS_PROTO=1
    echo " PROTOCOL  Found -> READ feedback_dev_protocol.md before coding"
fi

if [ -f "$MEMORY_DIR/MEMORY.md" ]; then
    MEM_COUNT=$(grep -c "^-" "$MEMORY_DIR/MEMORY.md" 2>/dev/null || echo "0")
    echo " MEMORY    $MEM_COUNT entries indexed in MEMORY.md"
fi

if [ "$HAS_ATLAS" -eq 0 ] && [ "$HAS_PROTO" -eq 0 ]; then
    echo " WARNING   No atlas or protocol found for this project"
fi

echo ""
echo " BEFORE ANY FEATURE WORK:"
echo "   1. Read atlas + protocol + MEMORY.md"
echo "   2. Ask user for source docs (PDF/Postman/Notion)"
echo "   3. Verify API endpoints with curl BEFORE coding"
echo "   4. Build incrementally -- max 3 items per deploy"
echo "   5. Save session snapshot before context fills"
echo ""
echo " HARD RULES (anti-drift):"
echo "   - NO em dashes in any output. Use hyphen (-) only."
echo "   - Run gitnexus_impact BEFORE editing any function/class."
echo "   - Run gitnexus_detect_changes BEFORE deploy."
echo "   - Max 3 files per deploy batch. Always."
echo "   - Default response: under 6 lines. Add detail only if asked."
echo "   - No decorative tables/headers unless the answer needs them."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
