#!/usr/bin/env bats

setup() {
    load '../test_helper/setup'
    load_farm33_helpers
}

# --- extract_issue_title ---

@test "extract_issue_title: extracts title from valid JSON" {
    result=$(echo '{"title": "Fix login bug"}' | extract_issue_title)
    assert_equal "$result" "Fix login bug"
}

@test "extract_issue_title: handles empty title" {
    result=$(echo '{"title": ""}' | extract_issue_title)
    assert_equal "$result" ""
}

@test "extract_issue_title: fails on invalid JSON" {
    run bash -c 'source "'"${PROJECT_ROOT}"'/farm33/lib/helpers.bash"; echo "bad" | extract_issue_title'
    assert_failure
}

# --- extract_issue_body ---

@test "extract_issue_body: extracts body from valid JSON" {
    result=$(echo '{"body": "Some description"}' | extract_issue_body)
    assert_equal "$result" "Some description"
}

@test "extract_issue_body: handles empty body" {
    result=$(echo '{"body": ""}' | extract_issue_body)
    assert_equal "$result" ""
}

# --- extract_issue_labels ---

@test "extract_issue_labels: extracts labels from valid JSON" {
    result=$(echo '{"labels": [{"name": "bug"}, {"name": "urgent"}]}' | extract_issue_labels)
    assert_equal "$result" "bug urgent"
}

@test "extract_issue_labels: handles empty labels" {
    result=$(echo '{"labels": []}' | extract_issue_labels)
    assert_equal "$result" ""
}

# --- log_worker ---

@test "log_worker: includes worker ID and timestamp" {
    export WORKER_ID="7"
    run log_worker "test message"
    assert_success
    assert_output --regexp '\[.*T.*Z\] \[worker-7\] test message'
}

@test "log_worker: defaults to 'main' worker" {
    unset WORKER_ID
    run log_worker "test message"
    assert_success
    assert_output --partial "[worker-main] test message"
}

# --- logging functions ---

@test "success: outputs green checkmark" {
    run success "done"
    assert_success
    assert_output --partial "✓ done"
}

@test "info: outputs blue arrow" {
    run info "processing"
    assert_success
    assert_output --partial "→ processing"
}

@test "warn: outputs yellow warning to stderr" {
    run warn "be careful"
    assert_success
    assert_output --partial "⚠ be careful"
}
