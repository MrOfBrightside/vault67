#!/usr/bin/env bats

setup() {
    load '../test_helper/setup'
    load_vault67_helpers
}

# --- extract_issue_number ---

@test "extract_issue_number: extracts number from valid JSON" {
    result=$(echo '{"number": 42, "title": "test"}' | extract_issue_number)
    assert_equal "$result" "42"
}

@test "extract_issue_number: handles large numbers" {
    result=$(echo '{"number": 99999}' | extract_issue_number)
    assert_equal "$result" "99999"
}

@test "extract_issue_number: fails on invalid JSON" {
    run bash -c 'source "'"${PROJECT_ROOT}"'/vault67/vault67/lib/helpers.bash"; echo "not json" | extract_issue_number'
    assert_failure
}

# --- extract_issue_body ---

@test "extract_issue_body: extracts body from valid JSON" {
    result=$(echo '{"body": "Hello world"}' | extract_issue_body)
    assert_equal "$result" "Hello world"
}

@test "extract_issue_body: handles empty body" {
    result=$(echo '{"body": ""}' | extract_issue_body)
    assert_equal "$result" ""
}

@test "extract_issue_body: handles multiline body" {
    result=$(echo '{"body": "line1\nline2"}' | extract_issue_body)
    assert_equal "$result" "line1
line2"
}

# --- extract_issue_labels ---

@test "extract_issue_labels: extracts labels from valid JSON" {
    result=$(echo '{"labels": [{"name": "bug"}, {"name": "urgent"}]}' | extract_issue_labels)
    assert_equal "$result" "bug urgent"
}

@test "extract_issue_labels: handles empty labels array" {
    result=$(echo '{"labels": []}' | extract_issue_labels)
    assert_equal "$result" ""
}

@test "extract_issue_labels: handles single label" {
    result=$(echo '{"labels": [{"name": "feature"}]}' | extract_issue_labels)
    assert_equal "$result" "feature"
}

# --- logging functions ---

@test "success: outputs green checkmark" {
    run success "it works"
    assert_success
    assert_output --partial "✓ it works"
}

@test "info: outputs blue arrow" {
    run info "some info"
    assert_success
    assert_output --partial "→ some info"
}

@test "warn: outputs yellow warning" {
    run warn "caution"
    assert_success
    assert_output --partial "⚠ caution"
}
