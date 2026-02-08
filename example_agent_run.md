# Engineering Principles Agent - Example Run

## Scenario: Node.js/TypeScript REST API Project

### Input 1: Repository Conventions (extracted from repo)

```yaml
repository:
  name: user-service-api
  language: TypeScript
  runtime: Node.js 20
  framework: Express.js

build_system:
  package_manager: pnpm
  build_command: pnpm build
  dev_command: pnpm dev

code_quality:
  linter: ESLint
  formatter: Prettier
  type_checker: TypeScript (strict mode)

testing:
  framework: Jest
  coverage_tool: Jest coverage
  e2e_framework: Supertest
  current_coverage: 75%

ci_cd:
  platform: GitHub Actions
  pipelines:
    - lint_and_format
    - type_check
    - test
    - build
    - deploy

dependencies:
  security_scanning: npm audit

documentation:
  api_docs: OpenAPI 3.0 (Swagger)
  code_docs: TSDoc comments

git_workflow:
  branching: feature branches from main
  commit_format: Conventional Commits
  pr_required: true
```

### Input 2: Team Principles

```markdown
# Engineering Principles - User Service Team

## Core Values

1. **API-First Development**
   - OpenAPI spec before implementation
   - All endpoints versioned
   - Backward compatibility maintained

2. **Reliability & Observability**
   - Structured logging on all requests
   - Metrics for all endpoints
   - Error tracking integrated
   - Health checks required

3. **Security by Default**
   - Authentication on all routes (except health)
   - Input validation using schemas
   - No sensitive data in logs
   - Regular dependency updates

4. **Type Safety**
   - No `any` types in production code
   - Strict TypeScript configuration
   - Runtime validation matches types

5. **Test Pyramid**
   - Unit tests for business logic (70%)
   - Integration tests for API endpoints (25%)
   - E2E tests for critical flows (5%)
   - Minimum 80% coverage

6. **Performance Standards**
   - API response < 100ms for simple queries
   - API response < 500ms for complex operations
   - Database queries optimized
   - Caching strategy documented

7. **Documentation Culture**
   - All public functions have JSDoc
   - OpenAPI always up to date
   - Architecture decisions recorded (ADRs)
   - README includes setup and examples
```

---

## Agent Processing

### Step 1: Analysis
The agent analyzes the inputs and identifies:
- Build tools: pnpm, TypeScript, Express.js
- Quality tools: ESLint, Prettier, Jest
- Current coverage: 75% (team wants 80%)
- Security: npm audit available
- Documentation: OpenAPI + TSDoc
- Key principles: API-first, security, type safety, observability

### Step 2: Synthesis
Maps principles to concrete guardrails:
- API-First → Validate OpenAPI spec in CI
- Security → Auth checks, input validation, secret scanning
- Type Safety → No `any`, strict mode enforced
- Test Pyramid → Coverage + test type requirements
- Observability → Logging/metrics checks
- Performance → Load testing requirements

### Step 3: Output Generation

---

## Output 1: guardrails.yaml

```yaml
# Development Guardrails - User Service API
# Generated: 2026-02-08
# Based on: TypeScript/Express conventions + team principles

pre_commit_hooks:
  - name: prettier_formatting
    tool: prettier
    command: prettier --check .
    description: Ensure code is formatted with Prettier
    blocking: true
    fix_command: prettier --write .

  - name: eslint_linting
    tool: eslint
    command: eslint . --max-warnings 0
    description: Lint code with ESLint, no warnings allowed
    blocking: true
    fix_command: eslint . --fix

  - name: typescript_check
    tool: tsc
    command: tsc --noEmit
    description: Type check with TypeScript
    blocking: true

  - name: no_secrets_check
    tool: git-secrets or truffleHog
    command: git secrets --scan
    description: Prevent committing secrets
    blocking: true

  - name: no_any_types
    tool: custom script
    command: npm run check-no-any
    description: Ensure no 'any' types in src/ code
    blocking: true

ci_pipeline_checks:
  - name: install_dependencies
    stage: setup
    command: pnpm install --frozen-lockfile
    threshold: success
    blocking: true

  - name: code_formatting
    stage: lint
    command: prettier --check .
    threshold: all_files_formatted
    blocking: true

  - name: linting
    stage: lint
    command: eslint . --max-warnings 0
    threshold: no_errors_no_warnings
    blocking: true

  - name: type_checking
    stage: lint
    command: tsc --noEmit
    threshold: no_type_errors
    blocking: true

  - name: unit_tests
    stage: test
    command: jest --testPathPattern=unit --coverage
    threshold: all_pass
    blocking: true

  - name: integration_tests
    stage: test
    command: jest --testPathPattern=integration
    threshold: all_pass
    blocking: true

  - name: coverage_gate
    stage: test
    command: jest --coverage --coverageThreshold='{"global":{"lines":80,"branches":80,"functions":80,"statements":80}}'
    threshold: 80%
    blocking: true

  - name: openapi_validation
    stage: test
    command: npm run validate-openapi
    threshold: spec_valid
    blocking: true

  - name: security_audit
    stage: security
    command: npm audit --audit-level=moderate
    threshold: no_moderate_or_higher
    blocking: true

  - name: dependency_check
    stage: security
    command: npm run check-licenses && npm audit
    threshold: approved_licenses_only
    blocking: false  # non-blocking but reported

  - name: build_check
    stage: build
    command: pnpm build
    threshold: build_succeeds
    blocking: true

  - name: bundle_size
    stage: build
    command: npm run check-bundle-size
    threshold: within_limits
    blocking: false  # warning only

code_quality_gates:
  - metric: test_coverage
    threshold: 80%
    tool: jest
    blocking: true

  - metric: type_coverage
    threshold: 100% (no any)
    tool: typescript + custom check
    blocking: true

  - metric: eslint_warnings
    threshold: 0
    tool: eslint
    blocking: true

  - metric: api_response_time
    threshold: p95 < 500ms
    tool: load testing (k6 or artillery)
    blocking: false  # measured but not blocking

security_checks:
  - name: dependency_vulnerabilities
    tool: npm audit
    severity_threshold: moderate
    blocking: true
    frequency: every_pr

  - name: secrets_detection
    tool: git-secrets
    severity_threshold: any
    blocking: true
    frequency: pre_commit

  - name: input_validation
    tool: code review + automated schema checks
    description: Verify all API inputs validated with zod/joi
    blocking: true
    frequency: code_review

observability_checks:
  - name: logging_present
    description: All endpoints log request/response
    tool: code review + grep patterns
    blocking: true

  - name: metrics_present
    description: All endpoints emit metrics
    tool: code review
    blocking: true

  - name: error_tracking
    description: Errors sent to tracking service
    tool: code review
    blocking: true

api_design_checks:
  - name: openapi_up_to_date
    description: OpenAPI spec matches implementation
    tool: openapi-validator or spectral
    blocking: true

  - name: versioning_correct
    description: All endpoints include version in path (/v1/...)
    tool: custom lint rule + code review
    blocking: true

  - name: backward_compatibility
    description: No breaking changes without version bump
    tool: openapi-diff + manual review
    blocking: true
```

---

## Output 2: dod_additions.md

```markdown
# Engineering Principles - Definition of Done Additions
# User Service API Team

Use this checklist in addition to the standard DoD for all PRs.

## Code Quality & Style
- [ ] Code formatted with Prettier (run: `prettier --check .`)
- [ ] No ESLint errors or warnings (run: `eslint . --max-warnings 0`)
- [ ] TypeScript type checking passes (run: `tsc --noEmit`)
- [ ] No `any` types in production code (run: `npm run check-no-any`)
- [ ] Code follows team conventions (naming, structure)

## Testing (Test Pyramid: 70% unit, 25% integration, 5% e2e)
- [ ] Unit tests added for new business logic (tests/unit/)
- [ ] Integration tests added for new API endpoints (tests/integration/)
- [ ] E2E tests added for critical user flows (if applicable)
- [ ] All tests pass locally (run: `jest`)
- [ ] Test coverage ≥ 80% (run: `jest --coverage`)
- [ ] Edge cases and error scenarios tested
- [ ] Test names describe behavior clearly

## API Design (API-First)
- [ ] OpenAPI spec updated BEFORE implementation
- [ ] OpenAPI spec validates (run: `npm run validate-openapi`)
- [ ] All endpoints versioned (e.g., /v1/users)
- [ ] Request/response schemas defined
- [ ] Backward compatibility maintained (run: `npm run check-api-compat`)
- [ ] Error responses follow standard format

## Security (Security by Default)
- [ ] Authentication required on all non-health endpoints
- [ ] Input validation using schema (zod/joi/class-validator)
- [ ] No secrets or API keys in code
- [ ] No sensitive data in logs or error messages
- [ ] npm audit passes with no moderate+ vulnerabilities (run: `npm audit`)
- [ ] Security implications reviewed (auth, injection, etc.)

## Observability & Reliability
- [ ] Structured logging added for new endpoints
- [ ] Request/response logged (excluding sensitive data)
- [ ] Metrics emitted for new endpoints (response time, error rate)
- [ ] Errors sent to tracking service (Sentry/Datadog)
- [ ] Health check updated if dependencies added
- [ ] Graceful error handling with appropriate status codes

## Type Safety (Strict TypeScript)
- [ ] Strict TypeScript mode maintained
- [ ] No type errors (run: `tsc --noEmit`)
- [ ] No `any`, `unknown` used appropriately
- [ ] Runtime validation matches TypeScript types
- [ ] Type definitions exported for consumers (if library)

## Performance
- [ ] Simple queries respond in < 100ms
- [ ] Complex operations respond in < 500ms
- [ ] Database queries optimized (indexes, joins)
- [ ] N+1 query issues prevented
- [ ] Caching strategy documented if used
- [ ] Load testing performed for critical paths (run: `npm run load-test`)

## Documentation
- [ ] JSDoc comments on public functions
- [ ] OpenAPI spec is the source of truth for API docs
- [ ] README updated if setup/usage changed
- [ ] Architecture decision recorded (ADR) if significant design choice
- [ ] Code comments explain "why", not "what"
- [ ] Environment variables documented in .env.example

## Build & Dependencies
- [ ] pnpm-lock.yaml updated (committed)
- [ ] Application builds successfully (run: `pnpm build`)
- [ ] No new dependencies without justification
- [ ] License check passes (run: `npm run check-licenses`)
- [ ] Bundle size within limits (run: `npm run check-bundle-size`)

## Git & Process
- [ ] Commit messages follow Conventional Commits format
- [ ] PR title describes the change clearly
- [ ] PR description includes context and testing notes
- [ ] Branch created from main
- [ ] All CI checks pass (GitHub Actions)
- [ ] At least 1 team member reviewed and approved
- [ ] All review comments addressed or discussed

## Deployment Readiness
- [ ] Database migrations included (if schema changes)
- [ ] Feature flags considered for risky changes
- [ ] Rollback plan documented for risky changes
- [ ] Monitoring alerts updated (if needed)
- [ ] Deployment runbook updated (if needed)

---

## Quick Validation Commands

Run these before pushing:
```bash
# Format, lint, type-check
pnpm format && pnpm lint && pnpm typecheck

# Run all tests with coverage
pnpm test:all --coverage

# Validate OpenAPI spec
pnpm validate-openapi

# Security checks
npm audit
git secrets --scan

# Build check
pnpm build
```

## CI Pipeline Must Pass
All GitHub Actions checks must be green:
- ✅ Code formatting (Prettier)
- ✅ Linting (ESLint)
- ✅ Type checking (TypeScript)
- ✅ Unit tests + coverage ≥ 80%
- ✅ Integration tests
- ✅ Security audit (npm audit)
- ✅ OpenAPI validation
- ✅ Build success

---

**Note**: This DoD is in addition to the project's base DoD. All items must be satisfied before merging to main.
```

---

## Justification Summary

### Key Decisions Made:

1. **No `any` Types Enforced**
   - Principle: "Type Safety - No any types"
   - Implementation: Pre-commit hook + CI check
   - Rationale: Catches type errors early, maintains type safety

2. **80% Coverage Threshold**
   - Principle: "Test Pyramid - Minimum 80% coverage"
   - Implementation: Jest coverage gate in CI
   - Rationale: Balances thoroughness with practicality

3. **OpenAPI Validation**
   - Principle: "API-First Development - OpenAPI spec before implementation"
   - Implementation: CI check validates spec syntax + consistency
   - Rationale: Ensures docs match implementation

4. **Observability Requirements**
   - Principle: "Reliability & Observability - Structured logging, metrics"
   - Implementation: Manual review + automated pattern checks
   - Rationale: Ensures production visibility

5. **Performance Thresholds**
   - Principle: "Performance Standards - < 100ms simple, < 500ms complex"
   - Implementation: Load testing (non-blocking in CI for now)
   - Rationale: Establishes baseline, measured but doesn't block initially

6. **Security Depth**
   - Principle: "Security by Default - Auth, validation, no secrets"
   - Implementation: Multiple layers (pre-commit, CI, code review)
   - Rationale: Defense in depth approach

### Adaptations Made:

- **Coverage Target**: Aligned with team's stated 80% goal (up from current 75%)
- **Backward Compatibility**: Added checks based on "API-First" + versioning principle
- **Observability**: Elevated from nice-to-have to required based on team principles
- **Bundle Size**: Made non-blocking initially to avoid disruption

### Assumptions:

- npm scripts exist or will be created: `validate-openapi`, `check-no-any`, `check-licenses`, `check-bundle-size`, `load-test`
- Team has access to error tracking service (Sentry/Datadog)
- OpenAPI spec tooling will be integrated (Swagger, Spectral)

---

## Next Steps

1. **Implement Pre-Commit Hooks**: Install husky + lint-staged
2. **Update CI Pipeline**: Add checks to GitHub Actions
3. **Create Helper Scripts**: npm scripts for validations
4. **Team Review**: Present guardrails to team for approval/adjustments
5. **Gradual Rollout**: Enable checks incrementally if needed
6. **Monitor Impact**: Track PR cycle time, identify bottlenecks
7. **Iterate**: Adjust thresholds based on team feedback

---

**Generated by**: Engineering Principles Agent (va-v0l)
**Date**: 2026-02-08
**Status**: Ready for team review and implementation
