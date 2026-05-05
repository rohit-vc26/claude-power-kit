#!/bin/bash
# power_kit_update_check.sh - SessionStart hook.
#
# Compares ~/.claude/.power-kit-version (written by install.sh) against the
# remote VERSION file on GitHub and prints a one-line nudge when behind.
#
# Cached for 24h in ~/.claude/.power-kit-update-cache to avoid hammering GH.
# Silently noops if curl is missing, network is down, or files are absent.

set -u

LOCAL_VER_FILE="$HOME/.claude/.power-kit-version"
CACHE_FILE="$HOME/.claude/.power-kit-update-cache"
REMOTE_URL="https://raw.githubusercontent.com/rohit-vc26/claude-power-kit/main/VERSION"
CACHE_HOURS=24

# Bail if no install marker (user never ran install.sh, nothing to compare)
[ -f "$LOCAL_VER_FILE" ] || exit 0
LOCAL_VER=$(tr -d ' \n\r\t' < "$LOCAL_VER_FILE" 2>/dev/null)
[ -n "$LOCAL_VER" ] || exit 0

# Use cache if fresh
if [ -f "$CACHE_FILE" ]; then
    if find "$CACHE_FILE" -mmin -$((CACHE_HOURS*60)) 2>/dev/null | grep -q .; then
        REMOTE_VER=$(tr -d ' \n\r\t' < "$CACHE_FILE")
    fi
fi

# Fetch if cache stale or missing
if [ -z "${REMOTE_VER:-}" ]; then
    command -v curl >/dev/null 2>&1 || exit 0
    REMOTE_VER=$(curl -fsSL --max-time 3 "$REMOTE_URL" 2>/dev/null | tr -d ' \n\r\t')
    [ -n "$REMOTE_VER" ] || exit 0
    echo "$REMOTE_VER" > "$CACHE_FILE"
fi

# Compare. Use sort -V (version sort) and check if local is the smaller of the two.
if [ "$LOCAL_VER" != "$REMOTE_VER" ]; then
    NEWER=$(printf '%s\n%s\n' "$LOCAL_VER" "$REMOTE_VER" | sort -V | tail -1)
    if [ "$NEWER" = "$REMOTE_VER" ]; then
        echo "POWER-KIT UPDATE AVAILABLE: $LOCAL_VER -> $REMOTE_VER"
        echo "  Run: cd ~/Desktop/claude-power-kit && git pull && bash install.sh"
        echo "  Changelog: https://github.com/rohit-vc26/claude-power-kit/commits/main"
    fi
fi

exit 0
