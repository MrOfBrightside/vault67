# Specification

## Context
We need to add user authentication to protect sensitive endpoints in the API. Currently, all endpoints are public which poses a security risk.

## Goal
Users must be able to log in with username/password and receive a JWT token for subsequent requests. Protected endpoints will validate this token.

## Scope
### In scope
- User login endpoint
- JWT token generation
- Token validation middleware

### Out of scope
- User registration
- Password reset functionality
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
    Given a registered user with username "testuser" and password "testpass123"
    When the user POSTs credentials to /api/login
    Then the response should be 200 OK
    And the response should contain a valid JWT token
    And the token should expire in 24 hours

  Scenario: Failed login with invalid credentials
    Given an unregistered user or wrong password
    When the user POSTs credentials to /api/login
    Then the response should be 401 Unauthorized

  Scenario: Access protected endpoint with valid token
    Given a valid JWT token in Authorization header
    When the user requests a protected endpoint
    Then the request should succeed

## Architecture alignment
- Relevant modules: /api/auth, /middleware/jwt
- Constraints: Use existing JWT library (jsonwebtoken), follow REST conventions
- Allowed paths: /api/auth/login.js, /middleware/jwt-validator.js
- Forbidden paths: Do not modify user database schema or core auth lib

## Security and compliance
- Data classification: Sensitive (passwords, tokens)
- AuthN/AuthZ: JWT-based authentication required
- Logging/Audit: Log all login attempts (success and failure) with timestamp and IP
- PII/Secrets: Store JWT secret in environment variable JWT_SECRET
- Security constraints: Hash passwords with bcrypt, use HTTPS only, rate limit login attempts

## Test strategy
- Golden build command: npm run build
- Golden test command: npm test
- Scenario to test mapping:
  - Scenario: Successful login with valid credentials
    - Test type (unit/integration/e2e/manual): integration
    - Suggested location (folder/file): tests/integration/auth.test.js
  - Scenario: Failed login with invalid credentials
    - Test type (unit/integration/e2e/manual): integration
    - Suggested location (folder/file): tests/integration/auth.test.js
  - Scenario: Access protected endpoint with valid token
    - Test type (unit/integration/e2e/manual): integration
    - Suggested location (folder/file): tests/integration/protected-routes.test.js

## Engineering principles and DoD additions
- Follow RESTful API design patterns
- Write clear error messages for authentication failures
- Keep middleware functions simple and focused
- Use existing logging infrastructure

## Open questions
- None

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
