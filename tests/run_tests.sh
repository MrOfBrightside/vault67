#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Running vault67 tests..."
bats "$SCRIPT_DIR/vault67/"

echo ""
echo "Running farm33 tests..."
bats "$SCRIPT_DIR/farm33/"

echo ""
echo "All tests passed."
