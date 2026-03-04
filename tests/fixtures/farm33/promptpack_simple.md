# Implementation Prompt Pack

Generated: 2026-01-15T10:00:00Z

## Spec
Feature: Add health check endpoint
  Scenario: Health check returns 200
    Given the application is running
    When GET /health is called
    Then the response status is 200
    And the body contains {"status": "ok"}

  Scenario: Health check includes version
    Given the application is running
    When GET /health is called
    Then the response body contains a "version" field

## Golden commands
- Golden build command: npm run build
- Golden test command: npm test
- Base ref: main

## Architecture
- Detected stack: Node.js, Express
- Allowed paths: src/routes/, src/middleware/
- Forbidden paths: src/database/

## Instructions
1. Implement changes according to the specification above
2. Follow all constraints and allowed/forbidden paths
3. Create tests as defined in test strategy
4. Create a PR against base ref
5. Include a brief PR description mapping changes to scenarios
