#!/usr/bin/env bash
# Mock infrastructure for LLM/API calls in tests
# Usage: source this file, then set MOCK_OLLAMA_RESPONSE before calling functions

# Mock state
MOCK_OLLAMA_RESPONSE=""
MOCK_OLLAMA_EXIT_CODE=0
_MOCK_CALLS=()

# Override ollama_generate with mock
ollama_generate() {
    local prompt="$1"
    local system_prompt="${2:-}"
    _MOCK_CALLS+=("ollama_generate|${prompt}|${system_prompt}")

    if [ "${MOCK_OLLAMA_EXIT_CODE:-0}" -ne 0 ]; then
        return "$MOCK_OLLAMA_EXIT_CODE"
    fi

    echo "${MOCK_OLLAMA_RESPONSE:-}"
    return 0
}

# Override ollama_chat with mock (if used)
ollama_chat() {
    local messages="$1"
    _MOCK_CALLS+=("ollama_chat|${messages}")

    if [ "${MOCK_OLLAMA_EXIT_CODE:-0}" -ne 0 ]; then
        return "$MOCK_OLLAMA_EXIT_CODE"
    fi

    echo "${MOCK_OLLAMA_RESPONSE:-}"
    return 0
}

# Assertion: check that a mock was called with a pattern
# Usage: assert_mock_called_with "pattern"
assert_mock_called_with() {
    local pattern="$1"
    local call
    for call in "${_MOCK_CALLS[@]}"; do
        if echo "$call" | grep -q "$pattern"; then
            return 0
        fi
    done
    echo "Expected mock call matching '$pattern' but none found" >&2
    echo "Calls were:" >&2
    local i
    for i in "${!_MOCK_CALLS[@]}"; do
        echo "  [$i]: ${_MOCK_CALLS[$i]}" >&2
    done
    return 1
}

# Assertion: check mock call count
# Usage: assert_mock_call_count 3
assert_mock_call_count() {
    local expected="$1"
    local actual="${#_MOCK_CALLS[@]}"
    if [ "$actual" -ne "$expected" ]; then
        echo "Expected $expected mock calls but got $actual" >&2
        return 1
    fi
    return 0
}

# Reset all mock state
reset_mocks() {
    MOCK_OLLAMA_RESPONSE=""
    MOCK_OLLAMA_EXIT_CODE=0
    _MOCK_CALLS=()
}
