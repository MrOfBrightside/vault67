#!/usr/bin/env bats

setup() {
    load '../test_helper/setup'
    load_vault67_helpers
    _VAULT67_TEMP_FILES=()
    TEST_DIR=$(mktemp -d)
}

teardown() {
    rm -rf "$TEST_DIR"
}

# --- get_ticket_state ---

@test "get_ticket_state: extracts state from YAML frontmatter" {
    cat > "$TEST_DIR/ticket.md" <<'EOF'
---
title: Test Ticket
state: REFINEMENT
spec_version: 3
---

# Test Ticket
Some content here.
EOF
    run get_ticket_state "$TEST_DIR/ticket.md"
    assert_success
    assert_output "REFINEMENT"
}

@test "get_ticket_state: handles different state values" {
    cat > "$TEST_DIR/ticket.md" <<'EOF'
---
state: READY_TO_IMPLEMENT
---
EOF
    run get_ticket_state "$TEST_DIR/ticket.md"
    assert_success
    assert_output "READY_TO_IMPLEMENT"
}

@test "get_ticket_state: returns empty for missing state" {
    cat > "$TEST_DIR/ticket.md" <<'EOF'
---
title: No State
---
EOF
    run get_ticket_state "$TEST_DIR/ticket.md"
    assert_success
    assert_output ""
}

# --- _replace_spec_section ---

@test "replace_spec_section: replaces section content" {
    cat > "$TEST_DIR/spec.md" <<'EOF'
## Context
Old context here.

## Goal
The goal is X.

## Requirements
Old requirements.
EOF
    _replace_spec_section "$TEST_DIR/spec.md" "## Context" "New context content."
    run cat "$TEST_DIR/spec.md"
    assert_output --partial "New context content."
    refute_output --partial "Old context here."
    # Other sections preserved
    assert_output --partial "## Goal"
    assert_output --partial "The goal is X."
}

@test "replace_spec_section: replaces last section" {
    cat > "$TEST_DIR/spec.md" <<'EOF'
## Context
Some context.

## Requirements
Old requirements.
EOF
    _replace_spec_section "$TEST_DIR/spec.md" "## Requirements" "New requirements."
    run cat "$TEST_DIR/spec.md"
    assert_output --partial "New requirements."
    refute_output --partial "Old requirements."
    assert_output --partial "## Context"
    assert_output --partial "Some context."
}

@test "replace_spec_section: handles section with trailing text in header" {
    cat > "$TEST_DIR/spec.md" <<'EOF'
## Context
Some context.

## Requirements (Raw, BA input)
Old requirements.

## Architecture
Architecture here.
EOF
    _replace_spec_section "$TEST_DIR/spec.md" "## Requirements" "Updated requirements."
    run cat "$TEST_DIR/spec.md"
    assert_output --partial "Updated requirements."
    refute_output --partial "Old requirements."
    assert_output --partial "## Architecture"
    assert_output --partial "Architecture here."
}

@test "replace_spec_section: preserves file when header not found" {
    cat > "$TEST_DIR/spec.md" <<'EOF'
## Context
Some context.
EOF
    _replace_spec_section "$TEST_DIR/spec.md" "## Nonexistent" "New content."
    run cat "$TEST_DIR/spec.md"
    assert_output --partial "## Context"
    assert_output --partial "Some context."
}
