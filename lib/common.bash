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

# ============================================================================
# Ollama LLM helpers (shared by vault67 and farm33)
# ============================================================================
# Requires: OLLAMA_URL, OLLAMA_MODEL set by the calling script's load_config()
# Requires: warn(), success() defined by the calling script's helpers.bash
#           (bash resolves these at call time, not definition time)
# Optional: OLLAMA_TIMEOUT (defaults to 120 seconds)

# Usage: ollama_generate "prompt text" ["system prompt"]
# Returns: response text on stdout, non-zero exit on failure
ollama_generate() {
    local prompt="$1"
    local system_prompt="${2:-}"
    local response_file
    response_file=$(mktemp)
    register_temp_file "$response_file"

    local timeout="${OLLAMA_TIMEOUT:-120}"

    # Build JSON payload using python3 for safe escaping
    local json_payload
    if [ -n "$system_prompt" ]; then
        json_payload=$(python3 -c "
import json, sys
print(json.dumps({
    'model': sys.argv[1],
    'prompt': sys.argv[2],
    'system': sys.argv[3],
    'stream': False
}))
" "$OLLAMA_MODEL" "$prompt" "$system_prompt" 2>/dev/null)
    else
        json_payload=$(python3 -c "
import json, sys
print(json.dumps({
    'model': sys.argv[1],
    'prompt': sys.argv[2],
    'stream': False
}))
" "$OLLAMA_MODEL" "$prompt" 2>/dev/null)
    fi

    if [ -z "$json_payload" ]; then
        rm -f "$response_file"
        return 1
    fi

    local _ollama_target_url="${OLLAMA_URL}"
    local http_code
    http_code=$(curl -s -w "%{http_code}" --connect-timeout 10 --max-time "$timeout" \
        -X POST "${_ollama_target_url}/api/generate" \
        -H "Content-Type: application/json" \
        -d "$json_payload" \
        -o "$response_file" 2>/dev/null) || {
        # Primary failed — try fallback if configured
        if [ -n "${OLLAMA_FALLBACK_URL:-}" ]; then
            _ollama_target_url="$OLLAMA_FALLBACK_URL"
            http_code=$(curl -s -w "%{http_code}" --connect-timeout 10 --max-time "$timeout" \
                -X POST "${_ollama_target_url}/api/generate" \
                -H "Content-Type: application/json" \
                -d "$json_payload" \
                -o "$response_file" 2>/dev/null) || {
                rm -f "$response_file"
                if [ "${LLM_OPTIONAL:-0}" = "1" ]; then
                    echo ""
                    return 0
                fi
                return 1
            }
        else
            rm -f "$response_file"
            if [ "${LLM_OPTIONAL:-0}" = "1" ]; then
                echo ""
                return 0
            fi
            return 1
        fi
    }

    if [[ "$http_code" != "200" ]]; then
        # Check for model not found — auto-pull
        if grep -q "model.*not found\|no such model" "$response_file" 2>/dev/null; then
            warn "Model '${OLLAMA_MODEL}' not found — pulling..."
            if command -v ollama >/dev/null 2>&1 && ollama pull "$OLLAMA_MODEL" 2>&1 | tail -1; then
                success "Model '${OLLAMA_MODEL}' pulled successfully"
                rm -f "$response_file"
                # Retry the request
                http_code=$(curl -s -w "%{http_code}" --connect-timeout 10 --max-time "$timeout" \
                    -X POST "${_ollama_target_url}/api/generate" \
                    -H "Content-Type: application/json" \
                    -d "$json_payload" \
                    -o "$response_file" 2>/dev/null) || {
                    rm -f "$response_file"
                    return 1
                }
                if [[ "$http_code" != "200" ]]; then
                    rm -f "$response_file"
                    return 1
                fi
            else
                rm -f "$response_file"
                return 1
            fi
        else
            rm -f "$response_file"
            return 1
        fi
    fi

    # Extract .response from JSON (strict=False handles control chars in LLM output)
    local response_text
    response_text=$(python3 -c "
import json, sys
data = json.load(open(sys.argv[1]), strict=False)
print(data.get('response', ''))
" "$response_file" 2>/dev/null)

    rm -f "$response_file"

    if [ -z "$response_text" ]; then
        return 1
    fi

    echo "$response_text"
    return 0
}
