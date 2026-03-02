#!/usr/bin/env bash
# vault67 helper functions — extracted for testability

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

error() {
    echo -e "${RED}Error: $*${NC}" >&2
    exit 1
}

success() {
    echo -e "${GREEN}✓ $*${NC}"
}

info() {
    echo -e "${BLUE}→ $*${NC}"
}

warn() {
    echo -e "${YELLOW}⚠ $*${NC}"
}

# Extract issue number from API response
extract_issue_number() {
    python3 -c "import sys, json; print(json.load(sys.stdin)['number'])"
}

# Extract issue body from API response
extract_issue_body() {
    python3 -c "import sys, json; print(json.load(sys.stdin)['body'])"
}

# Extract issue labels from API response (returns space-separated list)
extract_issue_labels() {
    python3 -c "import sys, json; print(' '.join([label['name'] for label in json.load(sys.stdin)['labels']]))"
}

# Detect placeholder/generic Gherkin content
# Returns 0 if text contains placeholder patterns, 1 if substantive
is_placeholder_gherkin() {
    local text="$1"
    echo "$text" | grep -qiE \
        "works as expected|works as specified|the feature is used|the system is configured|expected behavior occurs|feature name|scenario name|TODO|TBD|to be determined|to be defined|needs clarification|prerequisites are defined|actions are specified|expected outcomes are documented|placeholder|the system works correctly|it should work|the result is correct"
}

# Temp file tracking for safe cleanup
_VAULT67_TEMP_FILES=()

register_temp_file() {
    _VAULT67_TEMP_FILES+=("$1")
}

safe_cleanup() {
    local f
    for f in "${_VAULT67_TEMP_FILES[@]+"${_VAULT67_TEMP_FILES[@]}"}"; do
        if [ -d "$f" ]; then
            rm -rf "$f" 2>/dev/null || true
        elif [ -f "$f" ]; then
            rm -f "$f" 2>/dev/null || true
        fi
    done
}
