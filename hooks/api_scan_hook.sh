#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# API Branch -- SessionStart hook
# Shows API registry status + scans for new API files.
# No HTTP calls. No silent failures.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

BRANCH_DIR="$HOME/.claude/api-branch"
REGISTRY="$BRANCH_DIR/registry.json"
SCANNER="$BRANCH_DIR/scanner.py"

# Auto-detect Python3
PYTHON3="__PYTHON3__"
if [ ! -x "$PYTHON3" ]; then
    PYTHON3=$(which python3 2>/dev/null || echo "")
fi
if [ -z "$PYTHON3" ]; then
    exit 0
fi

# No registry = nothing to report
[ ! -f "$REGISTRY" ] && exit 0
[ ! -f "$SCANNER" ] && exit 0

# Quick status line
$PYTHON3 -c "
import json, sys
try:
    r = json.load(open('$REGISTRY'))
    p = r.get('projects', {})
    total = sum(len(v.get('apis', {})) for v in p.values())
    ls = r.get('last_scan', '')
    ls_short = ls[:10] if ls else 'never'
    projs = ' '.join(f'{k}({len(v.get(\"apis\",{}))})'  for k,v in p.items())
    print(f'API_BRANCH: {len(p)} projects | {total} APIs | {projs} | last scan: {ls_short}')
except Exception as e:
    print(f'API_BRANCH: registry error: {e}', file=sys.stderr)
" 2>/dev/null

# Lightweight diff scan (only prints if something new found)
$PYTHON3 "$SCANNER" --scan --quiet 2>/dev/null
