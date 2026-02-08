# Repo Context

## Repo
- Path/URL: /repos/api-service
- Base ref: main
- Language/runtime: Node.js 18, Express.js
- Main components/modules: API routes, middleware, controllers
- Architecture docs: docs/architecture.md
- Coding conventions: Airbnb style guide, ESLint

## How to build (golden command)
- Command(s): npm install && npm run build
- Notes: TypeScript compilation required

## How to test (golden command)
- Command(s): npm test
- Test types present (unit/integration/e2e): unit (Jest), integration (Supertest), e2e (Playwright)
- Notes: Tests must pass with >80% coverage

## CI/CD signals
- Pipeline file(s): .github/workflows/ci.yml
- Quality gates (lint, typecheck, etc): ESLint, TypeScript, Jest coverage

## Relevant code areas
- Likely folders/modules: src/routes/, src/middleware/, src/controllers/, src/auth/
- Key files (if known): src/app.ts, src/routes/api.ts

## Snippets (short)
> Keep snippets short. Prefer paths and small excerpts.
- Path: src/app.ts
  - excerpt: Main Express app configuration
- Path: src/middleware/
  - excerpt: Existing middleware for logging, error handling
