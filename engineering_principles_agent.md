# Engineering Principles Agent (Agent #5)

## Overview
The Engineering Principles Agent is the 5th agent in the refinement pipeline. It analyzes repository conventions and team principles to generate development guardrails and Definition of Done (DoD) additions.

## Purpose
Transform abstract team principles and repository conventions into concrete, actionable development guardrails that ensure code quality and consistency.

## Inputs
1. **Repository Conventions**
   - Coding standards (style guides, naming conventions)
   - Project structure and architecture patterns
   - Build and test commands
   - CI/CD pipeline configuration
   - Dependency management practices

2. **Team Principles**
   - Engineering values (e.g., "test-first", "security-by-default")
   - Code review requirements
   - Documentation standards
   - Performance benchmarks
   - Accessibility requirements

## Outputs
1. **Development Guardrails**
   - Automated checks and validations
   - Pre-commit hooks
   - Linting rules
   - Type checking requirements
   - Security scanning rules
   - Test coverage thresholds

2. **Definition of Done (DoD) Additions**
   - Specific acceptance criteria per feature type
   - Documentation requirements
   - Testing requirements (unit, integration, e2e)
   - Performance criteria
   - Security checklist items
   - Accessibility compliance checks

## Process Flow

### 1. Input Analysis Phase
- Parse repository conventions from:
  - README.md, CONTRIBUTING.md
  - .eslintrc, .prettierrc, pyproject.toml, etc.
  - CI/CD configuration files (.github/workflows, .gitlab-ci.yml)
  - Architecture decision records (ADRs)
  - Existing test patterns

- Extract team principles from:
  - Team documentation
  - Previous PR review comments
  - Existing spec templates
  - Project guidelines

### 2. Synthesis Phase
Generate guardrails by mapping principles to concrete checks:

**Example Mapping:**
- Principle: "Security-first development"
  → Guardrails:
    - Mandatory SAST scanning in CI
    - No secrets in code (pre-commit hook)
    - Dependency vulnerability scanning
    - Security review checklist in DoD

- Principle: "Test-driven development"
  → Guardrails:
    - Minimum 80% code coverage
    - All new features require unit tests
    - Integration tests for API endpoints
    - E2E tests for critical user flows

### 3. Output Generation Phase
Create structured output in two sections:

**A. Guardrails Configuration**
```yaml
guardrails:
  pre_commit:
    - no_secrets_check
    - linting
    - type_checking

  ci_checks:
    - unit_tests: { min_coverage: 80% }
    - integration_tests: required
    - security_scan: required
    - performance_benchmarks: { threshold: 95th_percentile }

  code_review:
    - required_reviewers: 1
    - check_security: true
    - check_accessibility: true
```

**B. DoD Additions Template**
```markdown
## Engineering Principles DoD

### Code Quality
- [ ] Follows repository coding standards (link to style guide)
- [ ] No linting errors
- [ ] Type checking passes (if applicable)
- [ ] Code complexity within acceptable limits

### Testing
- [ ] Unit tests added/updated for new logic
- [ ] Integration tests for API changes
- [ ] Test coverage ≥ 80%
- [ ] All tests pass locally and in CI

### Security
- [ ] No hardcoded secrets or credentials
- [ ] Security scan passes
- [ ] Dependencies have no critical vulnerabilities
- [ ] Input validation implemented

### Documentation
- [ ] Code comments for complex logic
- [ ] API documentation updated
- [ ] README updated if needed
- [ ] Architecture decisions recorded (if applicable)

### Performance
- [ ] No performance regressions
- [ ] Benchmarks meet thresholds
- [ ] Database queries optimized
- [ ] Caching considered where appropriate
```

## Integration with Refinement Pipeline

### Upstream (from previous agents)
- Receives refined requirements and technical context
- May receive initial architecture decisions
- Has access to repository metadata

### Downstream (to next agents)
- Provides guardrails configuration for validation agents
- Supplies enhanced DoD criteria for completion checking
- Feeds into test planning agents

## Configuration

### Agent Behavior Settings
```yaml
agent:
  name: engineering_principles
  version: 1.0.0
  position_in_pipeline: 5

  strictness_level: balanced  # options: lenient, balanced, strict

  auto_generate:
    guardrails: true
    dod_additions: true
    examples: true

  customization:
    allow_overrides: true
    require_approval: false
```

### Example Invocation
```bash
# Run as part of pipeline
gt mol attach va-v0l engineering-principles-mol

# Standalone execution (if supported)
gt agent run engineering-principles \
  --input-conventions ./repo_context.md \
  --input-principles ./team-principles.md \
  --output-guardrails ./guardrails.yaml \
  --output-dod ./dod-additions.md
```

## Quality Criteria for Agent Output

The agent's output is considered high-quality if:
1. **Specificity**: Guardrails are concrete and measurable
2. **Actionability**: DoD items are clear and verifiable
3. **Consistency**: Aligns with stated repo conventions
4. **Completeness**: Covers all critical engineering aspects
5. **Practicality**: Implementable with available tools

## Error Handling

### Missing Inputs
- If conventions are incomplete: Use sensible defaults and flag gaps
- If principles are vague: Ask clarifying questions or use industry standards

### Conflicting Requirements
- Document conflicts clearly
- Propose resolution based on priority
- Escalate to human if critical

### Validation Failures
- Check that generated guardrails are syntactically valid
- Verify DoD items are testable
- Ensure no contradictions exist

## Metrics and Success Indicators

Track agent effectiveness through:
- Time to generate guardrails (target: < 30s)
- Number of manual overrides needed (target: < 10%)
- Downstream agent success rate (target: > 95%)
- User satisfaction with generated DoD (qualitative)

## Future Enhancements

1. **Learning from Feedback**: Adapt guardrails based on PR review patterns
2. **Repository-Specific Templates**: Build custom templates per repo
3. **Automated Tool Integration**: Direct integration with linters, scanners
4. **Dynamic Adjustment**: Modify strictness based on project phase
5. **Cross-Repo Learning**: Share best practices across similar projects

---

**Status**: Ready for implementation
**Owner**: vault67/polecats/quartz
**Last Updated**: 2026-02-08
