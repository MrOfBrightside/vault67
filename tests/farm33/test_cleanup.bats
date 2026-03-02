#!/usr/bin/env bats

setup() {
    load '../test_helper/setup'
    load_farm33_helpers
    # Reset temp file tracking for each test
    _COMMON_TEMP_FILES=()
}

@test "register_temp_file: adds file to tracking array" {
    register_temp_file "/tmp/farm_test_1"
    register_temp_file "/tmp/farm_test_2"
    assert_equal "${#_COMMON_TEMP_FILES[@]}" "2"
}

@test "safe_cleanup: removes tracked files" {
    local tmpfile
    tmpfile=$(mktemp)
    register_temp_file "$tmpfile"
    [ -f "$tmpfile" ]

    safe_cleanup

    [ ! -f "$tmpfile" ]
}

@test "safe_cleanup: removes tracked directories" {
    local tmpdir
    tmpdir=$(mktemp -d)
    touch "$tmpdir/inner"
    register_temp_file "$tmpdir"
    [ -d "$tmpdir" ]

    safe_cleanup

    [ ! -d "$tmpdir" ]
}

@test "safe_cleanup: handles missing files" {
    register_temp_file "/tmp/nonexistent_farm_$$"
    run safe_cleanup
    assert_success
}

@test "safe_cleanup: handles empty array" {
    run safe_cleanup
    assert_success
}
