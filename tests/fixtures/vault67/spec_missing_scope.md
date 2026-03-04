# Spec: Add user authentication endpoint

## Context
The API needs authentication.

## Goal
Add authentication.

## Requirements
- Add login endpoint

### In scope

### Out of scope

## Acceptance Criteria (Gherkin)
Feature: User Authentication
  Scenario: Successful login
    Given a registered user
    When the user logs in with valid credentials
    Then they receive a token

  Scenario: Failed login
    Given a registered user
    When the user logs in with invalid credentials
    Then they receive an error

## Architecture alignment
- Detected stack: Node.js
- Constraints: Use Express
- Allowed paths: src/

## Security and compliance
- N/A

## Test strategy
- Golden build command: npm run build
- Golden test command: npm test
- Unit tests: basic tests
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
