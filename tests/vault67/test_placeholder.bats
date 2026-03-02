#!/usr/bin/env bats

setup() {
    load '../test_helper/setup'
    load_vault67_helpers
}

# --- is_placeholder_gherkin ---

@test "is_placeholder_gherkin: detects 'works as expected'" {
    run is_placeholder_gherkin "Then the feature works as expected"
    assert_success
}

@test "is_placeholder_gherkin: detects 'works as specified'" {
    run is_placeholder_gherkin "Then it works as specified"
    assert_success
}

@test "is_placeholder_gherkin: detects 'TODO'" {
    run is_placeholder_gherkin "Given TODO: implement later"
    assert_success
}

@test "is_placeholder_gherkin: detects 'TBD'" {
    run is_placeholder_gherkin "When TBD"
    assert_success
}

@test "is_placeholder_gherkin: detects 'placeholder'" {
    run is_placeholder_gherkin "This is a placeholder scenario"
    assert_success
}

@test "is_placeholder_gherkin: detects 'to be determined'" {
    run is_placeholder_gherkin "Given the requirements are to be determined"
    assert_success
}

@test "is_placeholder_gherkin: detects 'needs clarification'" {
    run is_placeholder_gherkin "When the behavior needs clarification"
    assert_success
}

@test "is_placeholder_gherkin: detects 'the system works correctly'" {
    run is_placeholder_gherkin "Then the system works correctly"
    assert_success
}

@test "is_placeholder_gherkin: detects 'it should work'" {
    run is_placeholder_gherkin "Then it should work"
    assert_success
}

@test "is_placeholder_gherkin: detects 'the result is correct'" {
    run is_placeholder_gherkin "Then the result is correct"
    assert_success
}

@test "is_placeholder_gherkin: detects case-insensitive matches" {
    run is_placeholder_gherkin "Then THE FEATURE WORKS AS EXPECTED"
    assert_success
}

@test "is_placeholder_gherkin: passes substantive Gherkin" {
    run is_placeholder_gherkin "Given the user enters 'admin' as username
When they click the login button
Then they are redirected to the dashboard"
    assert_failure
}

@test "is_placeholder_gherkin: passes specific assertions" {
    run is_placeholder_gherkin "Then the response status code is 200
And the body contains 'success'"
    assert_failure
}

@test "is_placeholder_gherkin: passes numeric checks" {
    run is_placeholder_gherkin "Then the total is 42.50"
    assert_failure
}
