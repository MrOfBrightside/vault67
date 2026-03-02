#!/usr/bin/env bash
# farm33 helper functions — extracted for testability

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

error()   { echo -e "${RED}Error: $*${NC}" >&2; exit 1; }
success() { echo -e "${GREEN}✓ $*${NC}"; }
info()    { echo -e "${BLUE}→ $*${NC}"; }
warn()    { echo -e "${YELLOW}⚠ $*${NC}" >&2; }

log_worker() {
    local worker_id="${WORKER_ID:-main}"
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] [worker-${worker_id}] $*" >&2
}

extract_issue_title() {
    python3 -c "import sys,json; print(json.load(sys.stdin)['title'])"
}

extract_issue_body() {
    python3 -c "import sys,json; print(json.load(sys.stdin)['body'])"
}

extract_issue_labels() {
    python3 -c "import sys,json; print(' '.join([l['name'] for l in json.load(sys.stdin)['labels']]))"
}

# Validate and execute a command safely — rejects shell injection patterns
# Usage: safe_eval_cmd <working_dir> <command_string>
# Returns: exit code of the command, or 1 if rejected
safe_eval_cmd() {
    local wt_dir="$1"
    local cmd="$2"

    # Reject dangerous patterns
    if echo "$cmd" | grep -qE '\$\(|`|;|&&|\|\|'; then
        echo "ERROR: Rejected command with shell metacharacters: $cmd" >&2
        return 1
    fi

    (cd "$wt_dir" && eval "$cmd")
}

# Temp file tracking for safe cleanup
_FARM33_TEMP_FILES=()

register_temp_file() {
    _FARM33_TEMP_FILES+=("$1")
}

safe_cleanup() {
    local f
    for f in "${_FARM33_TEMP_FILES[@]+"${_FARM33_TEMP_FILES[@]}"}"; do
        if [ -d "$f" ]; then
            rm -rf "$f" 2>/dev/null || true
        elif [ -f "$f" ]; then
            rm -f "$f" 2>/dev/null || true
        fi
    done
}
