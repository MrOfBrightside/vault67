# Spec: Add user authentication endpoint

## Context
The API currently has no authentication. Users access all endpoints without credentials.
We need to add JWT-based authentication to protect sensitive endpoints.

## Goal
Add a /api/auth/login endpoint that accepts username/password and returns a JWT token.
Protected endpoints should validate the token via middleware.

## Requirements
- POST /api/auth/login accepts JSON body with username and password
- Returns JWT token with 24h expiry on success
- Returns 401 on invalid credentials
- Add auth middleware for protected routes

### In scope
- Login endpoint implementation
- JWT token generation and validation

### Out of scope
- User registration

## Acceptance Criteria (Gherkin)
Feature: User Authentication
  Scenario: The feature works as expected
    Given the system is configured
    When the feature is used
    Then it works as expected

## Architecture alignment
- Detected stack: Node.js, Express
- Constraints: Must use existing middleware pattern
- Allowed paths: src/auth/
- Forbidden paths: src/database/

## Security and compliance
- Passwords: bcrypt hashing
- JWT: RS256 signing

## Test strategy
- Golden build command: npm run build
- Golden test command: npm test
- Unit tests: auth service tests
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
