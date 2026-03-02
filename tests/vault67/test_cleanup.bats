#!/usr/bin/env bats

setup() {
    load '../test_helper/setup'
    load_vault67_helpers
    # Reset temp file tracking for each test
    _VAULT67_TEMP_FILES=()
}

@test "register_temp_file: adds file to tracking array" {
    register_temp_file "/tmp/test_file_1"
    register_temp_file "/tmp/test_file_2"
    assert_equal "${#_VAULT67_TEMP_FILES[@]}" "2"
    assert_equal "${_VAULT67_TEMP_FILES[0]}" "/tmp/test_file_1"
    assert_equal "${_VAULT67_TEMP_FILES[1]}" "/tmp/test_file_2"
}

@test "safe_cleanup: removes tracked files" {
    local tmpfile
    tmpfile=$(mktemp)
    register_temp_file "$tmpfile"
    [ -f "$tmpfile" ]  # file exists before cleanup

    safe_cleanup

    [ ! -f "$tmpfile" ]  # file removed after cleanup
}

@test "safe_cleanup: removes tracked directories" {
    local tmpdir
    tmpdir=$(mktemp -d)
    touch "$tmpdir/inner_file"
    register_temp_file "$tmpdir"
    [ -d "$tmpdir" ]

    safe_cleanup

    [ ! -d "$tmpdir" ]
}

@test "safe_cleanup: handles already-deleted files gracefully" {
    register_temp_file "/tmp/nonexistent_file_$$"
    run safe_cleanup
    assert_success
}

@test "safe_cleanup: handles empty tracking array" {
    run safe_cleanup
    assert_success
}

@test "safe_cleanup: cleans up mix of files and dirs" {
    local tmpfile tmpdir
    tmpfile=$(mktemp)
    tmpdir=$(mktemp -d)
    register_temp_file "$tmpfile"
    register_temp_file "$tmpdir"

    safe_cleanup

    [ ! -f "$tmpfile" ]
    [ ! -d "$tmpdir" ]
}
