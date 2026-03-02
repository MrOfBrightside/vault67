#!/usr/bin/env bash
# Shared test setup for vault67/farm33 bats tests

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT="$(cd "$TESTS_DIR/.." && pwd)"

# Load bats-support and bats-assert
load "${TESTS_DIR}/lib/bats-support/load"
load "${TESTS_DIR}/lib/bats-assert/load"

load_vault67_helpers() {
    # Source vault67 helpers without triggering main script
    source "${PROJECT_ROOT}/vault67/vault67/lib/helpers.bash"
}

load_farm33_helpers() {
    # Source farm33 helpers without triggering main script
    source "${PROJECT_ROOT}/farm33/lib/helpers.bash"
}
