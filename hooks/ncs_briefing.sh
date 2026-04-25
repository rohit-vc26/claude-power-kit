#!/usr/bin/env bash
# ncs_briefing.sh — SessionStart hook wrapper
# Finds node + briefing.js regardless of install location (macOS/Ubuntu/nvm)

# Find node
NODE=""
for candidate in \
  "$(which node 2>/dev/null)" \
  "/opt/homebrew/bin/node" \
  "$HOME/.nvm/versions/node/$(ls "$HOME/.nvm/versions/node" 2>/dev/null | sort -V | tail -1)/bin/node" \
  "/usr/local/bin/node" \
  "/usr/bin/node" \
  "$HOME/.bun/bin/node"; do
  [ -x "$candidate" ] && NODE="$candidate" && break
done

[ -z "$NODE" ] && exit 0  # node not found — skip silently

# Find briefing.js — check common NCS install locations
BRIEFING=""
for dir in \
  "$HOME/Desktop/neural-command-system" \
  "$HOME/neural-command-system" \
  "$HOME/.ncs" \
  "$HOME/ncs"; do
  if [ -f "$dir/scripts/briefing.js" ]; then
    BRIEFING="$dir/scripts/briefing.js"
    break
  fi
done

[ -z "$BRIEFING" ] && exit 0  # NCS not installed — skip silently

exec "$NODE" "$BRIEFING"
