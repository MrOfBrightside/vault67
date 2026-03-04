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
- Auth middleware for route protection
- Unit tests for auth logic

### Out of scope
- User registration (separate ticket)
- OAuth/SSO integration
- Password reset flow

## Acceptance Criteria (Gherkin)
Feature: User Authentication
  Scenario: Successful login
    Given a registered user with username "alice" and password "secret123"
    When the user sends POST /api/auth/login with valid credentials
    Then the response status is 200
    And the response body contains a valid JWT token

  Scenario: Invalid credentials
    Given a registered user with username "alice" and password "secret123"
    When the user sends POST /api/auth/login with wrong password
    Then the response status is 401
    And the response body contains error "Invalid credentials"

  Scenario: Protected endpoint without token
    Given an unauthenticated request
    When the user sends GET /api/users/me without a token
    Then the response status is 401

## Architecture alignment
- Detected stack: Node.js, Express, PostgreSQL
- Constraints: Must use existing Express middleware pattern
- Allowed paths: src/auth/, src/middleware/, tests/auth/
- Forbidden paths: src/database/migrations/ (separate PR)

## Security and compliance
- Passwords: bcrypt hashing with cost factor 12
- JWT: RS256 signing, 24h expiry, httpOnly cookie
- Rate limiting: 5 attempts per minute per IP
- Input validation: sanitize username, enforce password min length

## Test strategy
- Golden build command: npm run build
- Golden test command: npm test
- Unit tests: auth service, JWT utility, middleware
- Integration tests: login flow end-to-end
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
