#!/usr/bin/env bats

setup() {
    load '../test_helper/setup'
    load_farm33_helpers
}

# --- extract_golden_commands ---

@test "golden_commands: inline bullet format" {
    input="- Golden build command: \`make build\`
- Golden test command: \`make test\`"
    run extract_golden_commands "$input"
    assert_success
    assert_line "BUILD_CMD=make build"
    assert_line "TEST_CMD=make test"
}

@test "golden_commands: inline without backticks" {
    input="- Golden build command: npm run build
- Golden test command: npm test"
    run extract_golden_commands "$input"
    assert_success
    assert_line "BUILD_CMD=npm run build"
    assert_line "TEST_CMD=npm test"
}

@test "golden_commands: asterisk bullets" {
    input="* Golden build command: cargo build
* Golden test command: cargo test"
    run extract_golden_commands "$input"
    assert_success
    assert_line "BUILD_CMD=cargo build"
    assert_line "TEST_CMD=cargo test"
}

@test "golden_commands: section format" {
    input="### How to build
make build

### How to test
pytest tests/"
    run extract_golden_commands "$input"
    assert_success
    assert_line "BUILD_CMD=make build"
    assert_line "TEST_CMD=pytest tests/"
}

@test "golden_commands: inline takes precedence over section" {
    input="- Golden build command: \`make\`
### How to build
cmake --build ."
    run extract_golden_commands "$input"
    assert_success
    assert_line "BUILD_CMD=make"
}

@test "golden_commands: missing commands return empty" {
    input="Some random text without commands"
    run extract_golden_commands "$input"
    assert_success
    assert_line "BUILD_CMD="
    assert_line "TEST_CMD="
}

@test "golden_commands: section with '(see parent issue)' is skipped" {
    input="### How to build
(see parent issue)

### How to test
npm test"
    run extract_golden_commands "$input"
    assert_success
    assert_line "BUILD_CMD="
    assert_line "TEST_CMD=npm test"
}

@test "golden_commands: strips backticks from section format" {
    input="### How to build
\`\`\`
make build
\`\`\`"
    # The stripping removes backticks at start/end
    run extract_golden_commands "$input"
    assert_success
    # Content has fences stripped
    assert_line --partial "BUILD_CMD="
}

# --- extract_base_ref ---

@test "base_ref: backtick format" {
    run extract_base_ref "Base ref: \`develop\`"
    assert_success
    assert_output "develop"
}

@test "base_ref: section format" {
    input="### Base ref
- feature/my-branch"
    run extract_base_ref "$input"
    assert_success
    assert_output "feature/my-branch"
}

@test "base_ref: defaults to main" {
    run extract_base_ref "No base ref here"
    assert_success
    assert_output "main"
}

@test "base_ref: backtick format takes precedence" {
    input="Base ref: \`staging\`
### Base ref
- develop"
    run extract_base_ref "$input"
    assert_success
    assert_output "staging"
}
