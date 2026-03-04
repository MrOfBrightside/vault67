#!/usr/bin/env bats
# Integration tests for vault67 judge_agent and contract validation

setup() {
    load '../test_helper/setup'
    load_vault67_helpers

    # Extract judge functions from the monolithic script
    VAULT67_SCRIPT="${PROJECT_ROOT}/vault67/vault67/vault67"

    # Source _judge_add_question and validate_farm33_contract
    eval "$(sed -n '/^_judge_add_question()/,/^}/p' "$VAULT67_SCRIPT")"
    eval "$(sed -n '/^validate_farm33_contract()/,/^}/p' "$VAULT67_SCRIPT")"
    eval "$(sed -n '/^judge_agent()/,/^}/p' "$VAULT67_SCRIPT")"

    # Create temp dir for test artifacts
    TEST_TMPDIR=$(mktemp -d)
    FIXTURES_DIR="${TESTS_DIR}/fixtures/vault67"
}

teardown() {
    rm -rf "$TEST_TMPDIR"
}

# --- Complete spec passes all criteria ---

@test "judge: complete spec passes all criteria (exit 0)" {
    local spec_file="$TEST_TMPDIR/spec.md"
    local qfile="$TEST_TMPDIR/questions.md"
    cp "$FIXTURES_DIR/spec_complete.md" "$spec_file"
    cat > "$qfile" <<'EOF'
# Questions (Human in the loop)

## Blocking questions

## Notes
-
EOF

    run judge_agent "$spec_file" "$qfile"
    assert_success
}

# --- Placeholder Gherkin fails ---

@test "judge: placeholder Gherkin fails criterion 2 (exit 1)" {
    local spec_file="$TEST_TMPDIR/spec.md"
    local qfile="$TEST_TMPDIR/questions.md"
    cp "$FIXTURES_DIR/spec_placeholder.md" "$spec_file"
    cat > "$qfile" <<'EOF'
# Questions (Human in the loop)

## Blocking questions

## Notes
-
EOF

    run judge_agent "$spec_file" "$qfile"
    assert_failure
    # Exit 1 = not ready (not exit 2 which is NEEDS_INFO)
    [ "$status" -eq 1 ]
}

# --- Missing scope generates blocking question ---

@test "judge: missing scope fails criterion 1" {
    local spec_file="$TEST_TMPDIR/spec.md"
    local qfile="$TEST_TMPDIR/questions.md"
    cp "$FIXTURES_DIR/spec_missing_scope.md" "$spec_file"
    cat > "$qfile" <<'EOF'
# Questions (Human in the loop)

## Blocking questions

## Notes
-
EOF

    run judge_agent "$spec_file" "$qfile"
    assert_failure
    # Should have added a blocking question
    run grep -c "Question:" "$qfile"
    assert_output --regexp "[1-9]"
}

# --- Blocking questions → exit 2 (NEEDS_INFO) ---

@test "judge: unanswered blocking question yields exit 2" {
    local spec_file="$TEST_TMPDIR/spec.md"
    local qfile="$TEST_TMPDIR/questions.md"
    cp "$FIXTURES_DIR/spec_complete.md" "$spec_file"
    cat > "$qfile" <<'EOF'
# Questions (Human in the loop)

## Blocking questions
1) Question: What authentication backend should be used?
   Answer:

## Notes
-
EOF

    run judge_agent "$spec_file" "$qfile"
    assert_failure
    [ "$status" -eq 2 ]
}

# --- Duplicate fields fail criterion 9 ---

@test "judge: duplicate context/goal/requirements fails" {
    local spec_file="$TEST_TMPDIR/spec.md"
    local qfile="$TEST_TMPDIR/questions.md"
    # Create a spec where context, goal, requirements, and scope are identical
    cat > "$spec_file" <<'EOF'
# Spec: Duplicate fields test

## Context
Add authentication to the API so users can log in securely

## Goal
Add authentication to the API so users can log in securely

## Requirements
Add authentication to the API so users can log in securely

### In scope
- Add authentication to the API so users can log in securely

### Out of scope
- Registration

## Acceptance Criteria (Gherkin)
Feature: Auth
  Scenario: Login success
    Given a user exists
    When they log in
    Then they get a token

  Scenario: Login failure
    Given a user exists
    When they log in with wrong password
    Then they get an error

## Architecture alignment
- Detected stack: Node.js
- Constraints: Express
- Allowed paths: src/
- Forbidden paths: vendor/

## Security and compliance
- Passwords: bcrypt

## Test strategy
- Golden build command: npm run build
- Golden test command: npm test
- Unit tests: auth tests
- Base ref: main

## Definition of Ready
- [ ] Scope in/out defined
- [ ] Gherkin scenarios are present and testable
- [ ] Architecture alignment reviewed and constraints captured
- [ ] Security/compliance reviewed and constraints captured
- [ ] Test strategy defined with test layers
- [ ] Repo golden commands known or explicitly blocked
- [ ] Allowed/forbidden paths set
- [ ] No blocking questions remain
- [ ] Fields contain distinct content
- [ ] Sufficient detail provided
EOF
    cat > "$qfile" <<'EOF'
# Questions (Human in the loop)

## Blocking questions

## Notes
-
EOF

    run judge_agent "$spec_file" "$qfile"
    assert_failure
    [ "$status" -eq 1 ]
}

# --- Insufficient substance fails criterion 10 ---

@test "judge: insufficient substance (< 4 lines) fails" {
    local spec_file="$TEST_TMPDIR/spec.md"
    local qfile="$TEST_TMPDIR/questions.md"
    cat > "$spec_file" <<'EOF'
# Spec: Thin spec

## Context
TODO

## Goal
TBD

## Requirements
to be determined

### In scope
- Login endpoint

## Acceptance Criteria (Gherkin)
Feature: Something
  Scenario: It works
    Given a thing
    When it runs
    Then it passes

  Scenario: It fails
    Given a thing
    When it breaks
    Then it errors

## Architecture alignment
- Detected stack: Python
- Constraints: Django
- Allowed paths: app/
- Forbidden paths: migrations/

## Security and compliance
- N/A

## Test strategy
- Golden build command: make build
- Golden test command: make test
- Unit tests: basic
- Base ref: main

## Definition of Ready
- [ ] Scope in/out defined
- [ ] Gherkin scenarios are present and testable
- [ ] Architecture alignment reviewed and constraints captured
- [ ] Security/compliance reviewed and constraints captured
- [ ] Test strategy defined with test layers
- [ ] Repo golden commands known or explicitly blocked
- [ ] Allowed/forbidden paths set
- [ ] No blocking questions remain
- [ ] Fields contain distinct content
- [ ] Sufficient detail provided
EOF
    cat > "$qfile" <<'EOF'
# Questions (Human in the loop)

## Blocking questions

## Notes
-
EOF

    run judge_agent "$spec_file" "$qfile"
    assert_failure
    [ "$status" -eq 1 ]
}

# --- Contract validation tests ---

@test "contract: complete spec passes validation" {
    local spec
    spec=$(cat "$FIXTURES_DIR/spec_complete.md")
    run validate_farm33_contract "$spec"
    assert_success
}

@test "contract: spec without golden commands fails" {
    run validate_farm33_contract "# Spec
## Context
Some context
## Acceptance Criteria (Gherkin)
Feature: Test
  Scenario: Basic
    Given a thing
    When it runs
    Then it passes"
    assert_failure
}

@test "contract: spec without Feature block fails" {
    run validate_farm33_contract "# Spec
- Golden build command: make build
- Golden test command: make test
- Base ref: main"
    assert_failure
}
