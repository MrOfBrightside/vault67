#!/usr/bin/env bash
# Shared helpers for vault67 and farm33

# Colors for output (used by sourcing scripts)
# shellcheck disable=SC2034
RED='\033[0;31m'
# shellcheck disable=SC2034
GREEN='\033[0;32m'
# shellcheck disable=SC2034
YELLOW='\033[1;33m'
# shellcheck disable=SC2034
BLUE='\033[0;34m'
# shellcheck disable=SC2034
CYAN='\033[0;36m'
# shellcheck disable=SC2034
NC='\033[0m' # No Color

# Temp file tracking for safe cleanup
_COMMON_TEMP_FILES=()

register_temp_file() {
    _COMMON_TEMP_FILES+=("$1")
}

safe_cleanup() {
    local f
    for f in "${_COMMON_TEMP_FILES[@]+"${_COMMON_TEMP_FILES[@]}"}"; do
        if [ -d "$f" ]; then
            rm -rf "$f" 2>/dev/null || true
        elif [ -f "$f" ]; then
            rm -f "$f" 2>/dev/null || true
        fi
    done
}
