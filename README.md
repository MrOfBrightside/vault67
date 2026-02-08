# Engineering Principles Agent (va-v0l)

> Agent #5 in the Gas Town refinement pipeline

## Overview

The **Engineering Principles Agent** transforms abstract team values and repository conventions into concrete, actionable development guardrails and Definition of Done criteria.

### Purpose
- **Input**: Repository conventions (tools, frameworks, CI/CD) + Team principles (values, standards)
- **Output**: Development guardrails (automated checks) + DoD additions (acceptance criteria)
- **Role**: Ensures engineering principles are consistently enforced through automation

## Quick Start

### For Agent Operators
1. Review the [Agent Specification](./engineering_principles_agent.md)
2. Use the [Prompt Template](./engineering_principles_prompt.md) to invoke the agent
3. Reference the [Example Run](./example_agent_run.md) for expected inputs/outputs

### For Gas Town Integration
```bash
# Hook the bead
gt hook

# Attach molecule (when ready)
gt mol attach va-v0l <molecule-id>

# Agent processes inputs and generates outputs
# Output: guardrails.yaml + dod_additions.md
```

## Documentation Structure

### Core Documents
| File | Purpose | Audience |
|------|---------|----------|
| [engineering_principles_agent.md](./engineering_principles_agent.md) | Complete agent specification | Developers, architects |
| [engineering_principles_prompt.md](./engineering_principles_prompt.md) | Prompt template for invocation | Agent operators, AI systems |
| [example_agent_run.md](./example_agent_run.md) | Working example (Node.js/TypeScript) | All users |
| [spec.md](./spec.md) | Formal specification (Gherkin) | QA, stakeholders |

### Supporting Documents
- [repo_context.md](./repo_context.md) - Repository metadata
- [questions.md](./questions.md) - Q&A tracking (empty if no blockers)
- [plan.md](./plan.md) - Implementation plan tracking
- [promtpack.md](./promtpack.md) - Prompt package configurations

## Key Features

### 1. Principle → Guardrail Mapping
The agent maps abstract principles to concrete checks:

**Example:**
```
Principle: "Security-First Development"
↓
Guardrails:
- Pre-commit: Secret scanning (blocking)
- CI: SAST scan (blocking)
- CI: Dependency vulnerabilities (blocking)
- DoD: Input validation checklist
```

### 2. Multi-Format Output

**Guardrails (YAML)**: Machine-readable configuration
```yaml
ci_pipeline_checks:
  - name: unit_tests
    command: pytest --cov=src --cov-fail-under=80
    threshold: 80%
    blocking: true
```

**DoD Additions (Markdown)**: Human-readable checklist
```markdown
## Testing
- [ ] Unit tests added/updated
- [ ] Coverage ≥ 80% (run: `pytest --cov=src`)
- [ ] All tests pass (run: `pytest`)
```

### 3. Adaptive to Project Types
- **Web Apps**: Accessibility, browser compatibility checks
- **APIs**: OpenAPI validation, versioning, rate limiting
- **Mobile**: Platform-specific testing, app store requirements
- **Data Pipelines**: Data validation, monitoring

### 4. Graceful Degradation
- Handles missing/incomplete inputs
- Provides sensible defaults with rationale
- Flags gaps requiring manual review

## Example Use Cases

### Use Case 1: New Project Setup
**Input**: Team principles + chosen tech stack
**Output**: Complete guardrails configuration + DoD template
**Value**: Instant enforcement of team standards from day one

### Use Case 2: Legacy Project Modernization
**Input**: Existing conventions + desired new principles
**Output**: Incremental guardrails that bridge current → target state
**Value**: Gradual, non-disruptive improvement

### Use Case 3: Cross-Team Consistency
**Input**: Organization-wide principles + repo-specific conventions
**Output**: Consistent guardrails across teams, customized per repo
**Value**: Standardization without sacrificing flexibility

## Integration Points

### Pipeline Position
```
[Agent 1] → [Agent 2] → [Agent 3] → [Agent 4] → [Agent 5: Engineering Principles] → [Agent 6] → ...
                                                           ↓
                                          Guardrails + DoD Additions
```

### Upstream Dependencies
- Repository metadata (from discovery agents)
- Team principles documentation
- Technical context (from architecture agents)

### Downstream Consumers
- Validation agents (use guardrails to verify compliance)
- Test planning agents (use DoD to generate test scenarios)
- CI/CD configuration generators

## Quality Metrics

The agent's output is considered high-quality if:
- ✅ **Specific**: Guardrails reference exact tools and commands
- ✅ **Measurable**: Thresholds are numeric and verifiable
- ✅ **Actionable**: DoD items have clear pass/fail criteria
- ✅ **Consistent**: Aligns with stated conventions
- ✅ **Complete**: Covers quality, security, testing, docs, performance

## Customization

### Strictness Levels
- **Lenient**: Fewer blocking checks, focus on critical items
- **Balanced**: Standard checks with reasonable thresholds (default)
- **Strict**: Comprehensive checks with high thresholds

### Domain Specialization
Add domain-specific guardrails by extending the prompt template:
- Healthcare: HIPAA compliance checks
- Finance: PCI-DSS requirements
- Government: FISMA controls

## Troubleshooting

### Common Issues

**Issue**: Agent generates too many guardrails
- **Solution**: Adjust strictness to "lenient" or filter principles

**Issue**: Generated commands don't exist in repo
- **Solution**: Provide golden commands in repo_context.md

**Issue**: DoD items too vague
- **Solution**: Provide more specific team principles as input

**Issue**: Conflicts between principles
- **Solution**: Prioritize principles in input, agent will resolve

## Contributing

### Adding New Examples
1. Create a new section in `example_agent_run.md`
2. Include: input conventions + principles + expected outputs
3. Add justification for key decisions

### Extending Agent Capabilities
1. Update `engineering_principles_agent.md` (specification)
2. Extend `engineering_principles_prompt.md` (prompt template)
3. Add examples in `example_agent_run.md`
4. Update `spec.md` (acceptance criteria)

## Status & Roadmap

### Current State: v1.0 (Complete Specification)
- [x] Agent specification
- [x] Prompt template
- [x] Working example
- [x] Formal specification (Gherkin)
- [x] Integration guidelines

### Future Enhancements
- [ ] Learning from PR feedback (adaptive guardrails)
- [ ] Repository-specific template library
- [ ] Direct tool integration (linters, scanners)
- [ ] Dynamic strictness adjustment
- [ ] Cross-repo knowledge sharing

## References

### Related Gas Town Agents
- Agent #4: (Upstream - provides context)
- Agent #6: (Downstream - consumes guardrails)

### External Resources
- [Gas Town Documentation](../../README.md) (if exists)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Test Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html)

## Contact & Support

- **Bead ID**: va-v0l
- **Owner**: vault67/polecats/quartz
- **Created**: 2026-02-08
- **Status**: HOOKED (in progress)

---

**Quick Commands**
```bash
# View bead details
gt bead show va-v0l

# Check hook status
gt hook

# View agent trail
gt trail
```
