# Specification

## Context
We need to add user authentication to protect sensitive endpoints in the API.

## Goal
Users must be able to log in with username/password and receive a JWT token for subsequent requests.

## Scope
### In scope
- User login endpoint
- JWT token generation
- Token validation middleware

### Out of scope
- User registration
- Password reset
- OAuth integration

## Requirements (Raw, BA input)
- Users should POST credentials to /api/login
- If credentials are valid, return a JWT token
- Token should expire after 24 hours
- Protected endpoints should require valid JWT in Authorization header
- Return 401 if token is missing or invalid

## Acceptance Criteria (Gherkin)
Feature: User Authentication

  Scenario: Successful login with valid credentials
    Given a user exists with username "alice" and password "secret123"
    When the user POSTs credentials to /api/login
    Then the system returns a JWT token
    And the token expires in 24 hours

  Scenario: Login failure with invalid credentials
    Given a user does not exist or has wrong password
    When the user POSTs credentials to /api/login
    Then the system returns 401 Unauthorized
    And no token is provided

  Scenario: Access protected endpoint with valid token
    Given a user has a valid JWT token
    When the user sends a request to /api/protected with the token in Authorization header
    Then the system allows access
    And returns the requested resource

  Scenario: Access protected endpoint without token
    Given a user does not provide a JWT token
    When the user sends a request to /api/protected
    Then the system returns 401 Unauthorized

## Architecture alignment
- Relevant modules: authentication, middleware
- Constraints: Must use JWT standard (RFC 7519)
- Allowed paths: /api/*, /middleware/*
- Forbidden paths: /internal/*

## Security and compliance
- Data classification: Sensitive (credentials, tokens)
- AuthN/AuthZ: JWT with HS256 signing
- Logging/Audit: Log all authentication attempts
- PII/Secrets: Passwords must be hashed with bcrypt
- Security constraints: Tokens must have expiration, no plaintext passwords

## Test strategy
- Golden build command: npm install && npm run build
- Golden test command: npm test
- Scenario to test mapping:

## Engineering principles and DoD additions
- Follow REST API best practices
- Use async/await for all async operations

## Open questions
-

## Definition of Done
- PR created with changes scoped correctly
- Tests added/updated
- All required checks green
- Acceptance criteria satisfied
- Documentation updated (if needed)

## Definition of Ready
- [ ] Scope in/out defined
- [ ] Gherkin scenarios are present and testable
- [ ] Architecture alignment reviewed and constraints captured
- [ ] Security/compliance reviewed and constraints captured
- [ ] Test strategy defined for each scenario
- [ ] Repo golden commands known or explicitly blocked
- [ ] Allowed/forbidden paths set
- [ ] No blocking questions remain
