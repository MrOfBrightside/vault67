#!/usr/bin/env bats

setup() {
    load '../test_helper/setup'
    load_vault67_helpers
}

# --- _extract_features ---

@test "extract_features: Feature N pattern" {
    run _extract_features "Feature 1: Auth system. Feature 2: Dashboard"
    assert_success
    assert_line --index 0 "Auth system"
    assert_line --index 1 "Dashboard"
}

@test "extract_features: numbered list with dots" {
    input="$(printf '1. Authentication module\n2. User dashboard\n3. Settings page')"
    run _extract_features "$input"
    assert_success
    assert_line --index 0 "Authentication module"
    assert_line --index 1 "User dashboard"
    assert_line --index 2 "Settings page"
}

@test "extract_features: numbered list with parens" {
    input="$(printf '1) Auth module\n2) Dashboard')"
    run _extract_features "$input"
    assert_success
    assert_line --index 0 "Auth module"
    assert_line --index 1 "Dashboard"
}

@test "extract_features: bullet points with dashes" {
    input="$(printf '%s\n%s\n%s' '- Auth system' '- User dashboard' '- Admin panel')"
    run _extract_features "$input"
    assert_success
    assert_line --index 0 "Auth system"
    assert_line --index 1 "User dashboard"
    assert_line --index 2 "Admin panel"
}

@test "extract_features: bullet points with asterisks" {
    input="$(printf '* Auth system\n* User dashboard')"
    run _extract_features "$input"
    assert_success
    assert_line --index 0 "Auth system"
    assert_line --index 1 "User dashboard"
}

@test "extract_features: sentence splitting on periods" {
    run _extract_features "Build an authentication system. Add a user dashboard with charts. Create an admin panel for management"
    assert_success
    assert_line --index 0 "Build an authentication system"
    assert_line --index 1 "Add a user dashboard with charts"
    assert_line --index 2 "Create an admin panel for management"
}

@test "extract_features: single feature passthrough" {
    run _extract_features "Build a login page"
    assert_success
    assert_output "Build a login page"
}

@test "extract_features: ignores short sentences in fallback" {
    run _extract_features "Build an authentication system. Yes. Create a dashboard"
    assert_success
    # "Yes" is < 10 chars, should be filtered
    refute_output --partial "Yes"
}

# --- _detect_feature_dependencies ---

@test "detect_deps: explicit 'requires' keyword" {
    run _detect_feature_dependencies \
        "Build authentication system with JWT tokens" \
        "Create user profile page that requires authentication"
    assert_success
    assert_output --partial "1 0"
}

@test "detect_deps: explicit 'using' keyword" {
    run _detect_feature_dependencies \
        "Build authentication system" \
        "Dashboard using authentication tokens"
    assert_success
    assert_output --partial "1 0"
}

@test "detect_deps: no dependencies for unrelated features" {
    run _detect_feature_dependencies \
        "Build authentication system" \
        "Design marketing landing page"
    assert_success
    assert_output ""
}

@test "detect_deps: single feature returns nothing" {
    run _detect_feature_dependencies "Only one feature here"
    assert_success
    assert_output ""
}

@test "detect_deps: sequential overlap with shared keywords" {
    run _detect_feature_dependencies \
        "Build database schema for user accounts" \
        "Create REST API endpoints for user accounts management"
    assert_success
    # Should detect overlap on "user", "accounts" (2+ shared words)
    assert_output --partial "1 0"
}

@test "detect_deps: three features with chain" {
    run _detect_feature_dependencies \
        "Build authentication system with JWT" \
        "Create user profiles using authentication" \
        "Build admin dashboard for user management"
    assert_success
    # Feature 1 depends on 0 (uses 'using' + 'authentication')
    assert_output --partial "1 0"
}
