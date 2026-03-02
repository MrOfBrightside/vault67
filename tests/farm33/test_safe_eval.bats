#!/usr/bin/env bats

setup() {
    load '../test_helper/setup'
    load_farm33_helpers
    TEST_DIR=$(mktemp -d)
    echo "hello" > "$TEST_DIR/testfile.txt"
}

teardown() {
    rm -rf "$TEST_DIR"
}

# --- safe_eval_cmd: allowed commands ---

@test "safe_eval_cmd: runs simple command" {
    run safe_eval_cmd "$TEST_DIR" "ls"
    assert_success
    assert_output --partial "testfile.txt"
}

@test "safe_eval_cmd: runs command with flags" {
    run safe_eval_cmd "$TEST_DIR" "cat testfile.txt"
    assert_success
    assert_output "hello"
}

@test "safe_eval_cmd: runs command with quoted args" {
    run safe_eval_cmd "$TEST_DIR" "echo 'hello world'"
    assert_success
    assert_output "hello world"
}

@test "safe_eval_cmd: passes through exit code" {
    run safe_eval_cmd "$TEST_DIR" "false"
    assert_failure
}

# --- safe_eval_cmd: rejected patterns ---

@test "safe_eval_cmd: rejects command substitution \$()" {
    run safe_eval_cmd "$TEST_DIR" 'echo $(whoami)'
    assert_failure
    assert_output --partial "Rejected command"
}

@test "safe_eval_cmd: rejects backtick substitution" {
    run safe_eval_cmd "$TEST_DIR" 'echo `whoami`'
    assert_failure
    assert_output --partial "Rejected command"
}

@test "safe_eval_cmd: rejects semicolon chaining" {
    run safe_eval_cmd "$TEST_DIR" "echo hi; rm -rf /"
    assert_failure
    assert_output --partial "Rejected command"
}

@test "safe_eval_cmd: rejects && chaining" {
    run safe_eval_cmd "$TEST_DIR" "echo hi && rm -rf /"
    assert_failure
    assert_output --partial "Rejected command"
}

@test "safe_eval_cmd: rejects || chaining" {
    run safe_eval_cmd "$TEST_DIR" "echo hi || rm -rf /"
    assert_failure
    assert_output --partial "Rejected command"
}

@test "safe_eval_cmd: changes to working directory" {
    run safe_eval_cmd "$TEST_DIR" "pwd"
    assert_success
    assert_output "$TEST_DIR"
}
