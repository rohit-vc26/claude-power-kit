#!/bin/bash
# secret_scan.sh - shared secret-pattern detector for memory backup hooks.
# Sourced (not executed). Provides:
#   has_secrets <file>   -> exit 0 if file contains secret-shaped content
#   filter_secrets <in> <out> -> copy <in> to <out> with secret lines redacted
#
# Patterns ported from gbrain's secret-scan layer (gstack v1.x).

SECRET_PATTERNS=(
    'AKIA[0-9A-Z]{16}'                    # AWS access key
    'aws_secret_access_key'                # AWS secret key var
    'ghp_[A-Za-z0-9]{36}'                  # GitHub personal access token
    'github_pat_[A-Za-z0-9_]{82}'          # GitHub fine-grained PAT
    'gho_[A-Za-z0-9]{36}'                  # GitHub OAuth
    'sk-ant-api[0-9]{2}-[A-Za-z0-9_-]+'    # Anthropic API key
    'sk-[A-Za-z0-9]{48}'                   # OpenAI API key
    '-----BEGIN [A-Z ]*PRIVATE KEY-----'   # PEM private key
    'eyJ[A-Za-z0-9_-]{20,}\.eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]+'  # JWT
    'xox[baprs]-[A-Za-z0-9-]{10,}'         # Slack token
    'AIza[0-9A-Za-z_-]{35}'                # Google API key
)

has_secrets() {
    local f="$1"
    [ -f "$f" ] || return 1
    for pat in "${SECRET_PATTERNS[@]}"; do
        if grep -qE "$pat" "$f" 2>/dev/null; then
            return 0
        fi
    done
    return 1
}

filter_secrets() {
    local in="$1" out="$2"
    local sed_args=()
    for pat in "${SECRET_PATTERNS[@]}"; do
        sed_args+=(-e "s|$pat|[REDACTED-SECRET]|g")
    done
    # -E = extended regex (ERE) so {N,M}, +, () work without backslash-escapes
    sed -E "${sed_args[@]}" "$in" > "$out"
}
