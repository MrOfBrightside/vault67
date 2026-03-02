#!/usr/bin/env bats

setup() {
    load '../test_helper/setup'
    load_farm33_helpers
    _FARM33_TEMP_FILES=()
    TEST_DIR=$(mktemp -d)
}

teardown() {
    rm -rf "$TEST_DIR"
}

# --- parse_llm_json_object ---

@test "json_object: parses clean JSON" {
    echo '{"files": [{"path": "main.py", "action": "create"}], "commit_message": "init"}' > "$TEST_DIR/input.txt"
    run parse_llm_json_object "$TEST_DIR/input.txt" "files"
    assert_success
    [[ "$output" == *'"files"'* ]]
}

@test "json_object: strips markdown fences" {
    cat > "$TEST_DIR/input.txt" <<'EOF'
```json
{"files": [{"path": "main.py"}], "commit_message": "init"}
```
EOF
    run parse_llm_json_object "$TEST_DIR/input.txt" "files"
    assert_success
    [[ "$output" == *'"files"'* ]]
}

@test "json_object: extracts JSON from surrounding text" {
    cat > "$TEST_DIR/input.txt" <<'EOF'
Here is my plan:

{"files": [{"path": "app.py", "action": "create"}], "commit_message": "add app"}

I hope this helps!
EOF
    run parse_llm_json_object "$TEST_DIR/input.txt" "files"
    assert_success
    [[ "$output" == *'"files"'* ]]
}

@test "json_object: fails on missing required key" {
    echo '{"items": [1, 2, 3]}' > "$TEST_DIR/input.txt"
    run parse_llm_json_object "$TEST_DIR/input.txt" "files"
    assert_failure
}

@test "json_object: fails on invalid JSON" {
    echo 'not json at all' > "$TEST_DIR/input.txt"
    run parse_llm_json_object "$TEST_DIR/input.txt" "files"
    assert_failure
}

@test "json_object: works without required key" {
    echo '{"anything": "goes"}' > "$TEST_DIR/input.txt"
    run parse_llm_json_object "$TEST_DIR/input.txt"
    assert_success
    [[ "$output" == *'"anything"'* ]]
}

@test "json_object: handles nested braces in fallback" {
    cat > "$TEST_DIR/input.txt" <<'EOF'
Some text { invalid
{"verdict": "pass", "confidence": 85, "gaps": []}
EOF
    run parse_llm_json_object "$TEST_DIR/input.txt" "verdict"
    assert_success
    [[ "$output" == *'"verdict"'* ]]
    [[ "$output" == *'"pass"'* ]]
}

@test "json_object: handles verdict JSON for spec review" {
    echo '{"verdict": "fail", "confidence": 40, "gaps": ["missing auth"]}' > "$TEST_DIR/input.txt"
    run parse_llm_json_object "$TEST_DIR/input.txt" "verdict"
    assert_success
    [[ "$output" == *'"fail"'* ]]
    [[ "$output" == *'"gaps"'* ]]
}

@test "json_object: handles acceptance JSON" {
    echo '{"all_satisfied": true, "scenarios": []}' > "$TEST_DIR/input.txt"
    run parse_llm_json_object "$TEST_DIR/input.txt" "all_satisfied"
    assert_success
    [[ "$output" == *'"all_satisfied"'* ]]
}

@test "json_object: handles confidence JSON" {
    echo '{"confidence": 92}' > "$TEST_DIR/input.txt"
    run parse_llm_json_object "$TEST_DIR/input.txt" "confidence"
    assert_success
    [[ "$output" == *'92'* ]]
}

# --- parse_llm_json_array ---

@test "json_array: parses clean array" {
    echo '[{"path": "test.py", "content": "pass"}]' > "$TEST_DIR/input.txt"
    run parse_llm_json_array "$TEST_DIR/input.txt"
    assert_success
    [[ "$output" == '['* ]]
}

@test "json_array: strips markdown fences" {
    cat > "$TEST_DIR/input.txt" <<'EOF'
```json
[{"path": "main.py", "content": "print('hello')"}]
```
EOF
    run parse_llm_json_array "$TEST_DIR/input.txt"
    assert_success
    [[ "$output" == '['* ]]
}

@test "json_array: extracts array from surrounding text" {
    cat > "$TEST_DIR/input.txt" <<'EOF'
Here are the patches:
[{"path": "fix.py", "content": "fixed"}]
Applied successfully.
EOF
    run parse_llm_json_array "$TEST_DIR/input.txt"
    assert_success
    [[ "$output" == *'"fix.py"'* ]]
}

@test "json_array: fails on non-array JSON" {
    echo '{"not": "an array"}' > "$TEST_DIR/input.txt"
    run parse_llm_json_array "$TEST_DIR/input.txt"
    assert_failure
}

@test "json_array: fails on invalid JSON" {
    echo 'just some text' > "$TEST_DIR/input.txt"
    run parse_llm_json_array "$TEST_DIR/input.txt"
    assert_failure
}

@test "json_array: handles empty array" {
    echo '[]' > "$TEST_DIR/input.txt"
    run parse_llm_json_array "$TEST_DIR/input.txt"
    assert_success
    assert_output "[]"
}

@test "json_array: handles multiple objects in array" {
    echo '[{"path":"a.py","content":"1"},{"path":"b.py","content":"2"}]' > "$TEST_DIR/input.txt"
    run parse_llm_json_array "$TEST_DIR/input.txt"
    assert_success
    [[ "$output" == *'"a.py"'* ]]
    [[ "$output" == *'"b.py"'* ]]
}
