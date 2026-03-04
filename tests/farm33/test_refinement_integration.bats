#!/usr/bin/env bats
# Integration tests for farm33 refinement gate functions

setup() {
    load '../test_helper/setup'
    load_farm33_helpers
    load_mock_http

    FARM33_SCRIPT="${PROJECT_ROOT}/farm33/farm33"

    # Extract gate functions from farm33
    eval "$(sed -n '/^run_spec_review_gate()/,/^}/p' "$FARM33_SCRIPT")"
    eval "$(sed -n '/^run_build_gate()/,/^}/p' "$FARM33_SCRIPT")"
    eval "$(sed -n '/^run_test_gate()/,/^}/p' "$FARM33_SCRIPT")"
    eval "$(sed -n '/^run_acceptance_gate()/,/^}/p' "$FARM33_SCRIPT")"

    # Extract verify functions (these are called by gates)
    eval "$(sed -n '/^verify_spec_review()/,/^}/p' "$FARM33_SCRIPT")"
    eval "$(sed -n '/^verify_acceptance_criteria()/,/^}/p' "$FARM33_SCRIPT")"

    # Stub collect_changed_files (called by verify_acceptance_criteria)
    collect_changed_files() { echo "stub changed files"; }

    # Create temp dir for test artifacts
    TEST_TMPDIR=$(mktemp -d)

    # Initialize globals used by gates
    GATE_FEEDBACK=""
    _LAST_SPEC_REVIEW_RESULT=""
    _LAST_TESTS_PASSED="true"
    _LAST_ACCEPTANCE_RESULT=""
    SKIP_SPEC_REVIEW=""
    SKIP_ACCEPTANCE_CHECK=""
    PROMPTS_DIR="$TEST_TMPDIR/prompts"
    mkdir -p "$PROMPTS_DIR"

    # Create minimal prompt templates
    echo "You are a spec reviewer" > "$PROMPTS_DIR/review.md"
    echo "You are an acceptance verifier" > "$PROMPTS_DIR/verify_acceptance.md"
}

teardown() {
    rm -rf "$TEST_TMPDIR"
    reset_mocks
}

# --- run_spec_review_gate ---

@test "spec_review_gate: passes on good verdict" {
    MOCK_OLLAMA_RESPONSE='{"verdict":"pass","confidence":85,"gaps":[]}'

    local wt_dir="$TEST_TMPDIR/wt"
    mkdir -p "$wt_dir"
    (cd "$wt_dir" && git init -q && git commit --allow-empty -m "init" -q)

    GATE_FEEDBACK=""
    run run_spec_review_gate "$wt_dir" "some promptpack"
    assert_success
    assert_equal "$GATE_FEEDBACK" ""
}

@test "spec_review_gate: fails on fail verdict, appends feedback" {
    MOCK_OLLAMA_RESPONSE='{"verdict":"fail","confidence":30,"gaps":[{"requirement":"auth","status":"missing","detail":"no auth impl"}]}'

    local wt_dir="$TEST_TMPDIR/wt"
    mkdir -p "$wt_dir"
    (cd "$wt_dir" && git init -q && git commit --allow-empty -m "init" -q)

    GATE_FEEDBACK=""
    run run_spec_review_gate "$wt_dir" "some promptpack"
    assert_failure
}

@test "spec_review_gate: skipped when SKIP_SPEC_REVIEW=1" {
    SKIP_SPEC_REVIEW=1
    GATE_FEEDBACK=""

    run run_spec_review_gate "$TEST_TMPDIR" "some promptpack"
    assert_success
}

# --- run_build_gate ---

@test "build_gate: passes on exit 0" {
    local wt_dir="$TEST_TMPDIR/wt"
    mkdir -p "$wt_dir"
    # safe_eval_cmd stub
    safe_eval_cmd() { return 0; }

    GATE_FEEDBACK=""
    run run_build_gate "$wt_dir" "echo ok"
    assert_success
}

@test "build_gate: fails on build error, captures output" {
    local wt_dir="$TEST_TMPDIR/wt"
    mkdir -p "$wt_dir"
    safe_eval_cmd() { echo "compilation error on line 5" >&2; return 1; }

    GATE_FEEDBACK=""
    run run_build_gate "$wt_dir" "make build"
    assert_failure
}

@test "build_gate: skips on empty command" {
    GATE_FEEDBACK=""
    run run_build_gate "$TEST_TMPDIR" ""
    assert_success
}

# --- run_test_gate ---

@test "test_gate: passes on exit 0" {
    local wt_dir="$TEST_TMPDIR/wt"
    mkdir -p "$wt_dir"
    safe_eval_cmd() { return 0; }

    GATE_FEEDBACK=""
    run run_test_gate "$wt_dir" "npm test"
    assert_success
}

@test "test_gate: fails on test error" {
    local wt_dir="$TEST_TMPDIR/wt"
    mkdir -p "$wt_dir"
    safe_eval_cmd() { echo "FAIL: test_auth" >&2; return 1; }

    GATE_FEEDBACK=""
    run run_test_gate "$wt_dir" "npm test"
    assert_failure
}

@test "test_gate: skips on empty command" {
    GATE_FEEDBACK=""
    run run_test_gate "$TEST_TMPDIR" ""
    assert_success
}

# --- run_acceptance_gate ---

@test "acceptance_gate: passes when all_satisfied=true" {
    MOCK_OLLAMA_RESPONSE='{"all_satisfied":true,"scenarios":[{"name":"login","satisfied":true}]}'

    GATE_FEEDBACK=""
    run run_acceptance_gate "$TEST_TMPDIR" "some promptpack"
    assert_success
}

@test "acceptance_gate: fails when all_satisfied=false" {
    MOCK_OLLAMA_RESPONSE='{"all_satisfied":false,"scenarios":[{"name":"login","satisfied":false,"gaps":"no login endpoint"}]}'

    GATE_FEEDBACK=""
    run run_acceptance_gate "$TEST_TMPDIR" "some promptpack"
    assert_failure
}

@test "acceptance_gate: skipped when SKIP_ACCEPTANCE_CHECK=1" {
    SKIP_ACCEPTANCE_CHECK=1
    GATE_FEEDBACK=""

    run run_acceptance_gate "$TEST_TMPDIR" "some promptpack"
    assert_success
}
