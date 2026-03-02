#!/usr/bin/env bats

setup() {
    load '../test_helper/setup'
    load_vault67_helpers
}

# --- clean_gherkin_response ---

@test "clean_gherkin: extracts plain Feature block" {
    input="Feature: Login
  Scenario: Valid login
    Given a user with email \"test@test.com\"
    When they login
    Then they see the dashboard"
    result=$(echo "$input" | clean_gherkin_response)
    assert_equal "$(echo "$result" | head -1)" "Feature: Login"
    [[ "$result" == *"Scenario: Valid login"* ]]
    [[ "$result" == *"Given a user"* ]]
}

@test "clean_gherkin: strips markdown gherkin fences" {
    input='Here is the Gherkin:

```gherkin
Feature: Login
  Scenario: Valid login
    Given a user
    When they login
    Then success
```

Hope this helps!'
    result=$(echo "$input" | clean_gherkin_response)
    assert_equal "$(echo "$result" | head -1)" "Feature: Login"
    [[ "$result" != *'```'* ]]
    [[ "$result" != *"Hope this helps"* ]]
}

@test "clean_gherkin: strips plain markdown fences" {
    input='```
Feature: Payments
  Scenario: Process payment
    Given a cart with items
    When checkout completes
    Then payment is processed
```'
    result=$(echo "$input" | clean_gherkin_response)
    assert_equal "$(echo "$result" | head -1)" "Feature: Payments"
}

@test "clean_gherkin: trims trailing blank lines" {
    input="Feature: Test
  Scenario: Basic
    Given something
    When action
    Then result


"
    result=$(echo "$input" | clean_gherkin_response)
    # Last line should not be blank
    last_line=$(echo "$result" | tail -1)
    [[ -n "$last_line" ]]
    [[ "$last_line" == *"Then result"* ]]
}

@test "clean_gherkin: fallback extracts Gherkin keywords without Feature block" {
    input="Some commentary here
Scenario: Edge case
Given a broken setup
When something happens
Then it recovers"
    result=$(echo "$input" | clean_gherkin_response)
    [[ "$result" == *"Scenario: Edge case"* ]]
    [[ "$result" == *"Given a broken setup"* ]]
    [[ "$result" != *"Some commentary"* ]]
}

@test "clean_gherkin: handles And/But keywords in fallback" {
    input="Scenario: Multi-step
Given a user is logged in
And they have items in cart
When they checkout
Then order is placed
But no duplicate charge"
    result=$(echo "$input" | clean_gherkin_response)
    [[ "$result" == *"And they have items"* ]]
    [[ "$result" == *"But no duplicate"* ]]
}

@test "clean_gherkin: empty input returns empty" {
    result=$(echo "" | clean_gherkin_response)
    assert_equal "$result" ""
}
