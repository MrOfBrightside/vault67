# Specification: Engineering Principles Agent (va-v0l)

## Context
The ticket refinement pipeline requires an agent that transforms abstract engineering principles and repository conventions into concrete, actionable development guardrails. Currently, teams must manually translate their values (like "security-first" or "test-driven development") into specific checks, thresholds, and Definition of Done criteria. This manual process is time-consuming, inconsistent, and error-prone.

The Engineering Principles Agent automates this translation, ensuring that team values are consistently enforced through automated checks and clear acceptance criteria.

## Goal
After implementation, the Engineering Principles Agent must:
1. Accept repository conventions and team principles as input
2. Generate concrete development guardrails (automated checks, gates, thresholds)
3. Produce specific Definition of Done additions
4. Output results in machine-readable (YAML) and human-readable (Markdown) formats
5. Operate as agent #5 in the refinement pipeline

## Scope
### In scope
- Agent specification and documentation
- Prompt templates for agent invocation
- Input/output format definitions
- Example transformations showing principle → guardrail mapping
- Integration guidelines for Gas Town pipeline
- Quality criteria for agent outputs
- Error handling for missing/incomplete inputs

### Out of scope
- Actual agent runtime implementation (execution engine)
- Integration with specific CI/CD platforms (examples only)
- Tool installation or configuration scripts
- Repository-specific customizations (agent produces generic output)
- UI/dashboard for agent management

## Requirements (Raw, BA input)
1. Agent must analyze repository conventions (build system, testing framework, linting rules, CI/CD setup)
2. Agent must analyze team engineering principles (values, standards, quality expectations)
3. Agent must map principles to concrete, measurable guardrails
4. Agent must generate DoD additions as testable checklist items
5. Output must be specific enough to implement without additional interpretation
6. Agent must handle incomplete inputs gracefully (defaults or clarifying questions)
7. Agent must operate within the Gas Town multi-agent framework
8. Documentation must enable other agents or humans to use this agent effectively

## Acceptance Criteria (Gherkin)

Feature: Engineering Principles Agent

  Scenario: Generate guardrails from complete inputs
    Given repository conventions are provided (language, tools, CI/CD)
    And team engineering principles are provided (values, standards)
    When the Engineering Principles Agent processes the inputs
    Then it generates a guardrails configuration in YAML format
    And it generates DoD additions in Markdown checklist format
    And all guardrails are specific and automatable
    And all DoD items are testable and unambiguous
    And output includes justification for key decisions

  Scenario: Handle missing repository conventions
    Given team principles are provided
    But repository conventions are incomplete or missing
    When the Engineering Principles Agent processes the inputs
    Then it identifies the gaps explicitly
    And it provides sensible defaults with rationale
    And it flags areas requiring manual review

  Scenario: Map principle to multiple guardrails
    Given a team principle like "Security-First Development"
    When the agent processes this principle
    Then it generates multiple related guardrails:
      - Pre-commit secret scanning
      - CI security audit
      - Dependency vulnerability checks
      - Input validation requirements
    And each guardrail specifies the tool, command, and threshold

  Scenario: Adapt to different project types
    Given repository conventions indicate a web application
    When the agent generates guardrails
    Then it includes web-specific checks (accessibility, browser compat)
    Given repository conventions indicate an API service
    When the agent generates guardrails
    Then it includes API-specific checks (OpenAPI validation, versioning)

## Architecture alignment
- Relevant modules: Gas Town agent pipeline (position #5)
- Constraints:
  - Must work within Gas Town agent communication protocol
  - Must accept structured input (conventions + principles)
  - Must produce structured output (YAML + Markdown)
  - Must complete processing in < 60 seconds for typical inputs
- Allowed paths:
  - Read from provided input files/structured data
  - Write to specified output files
  - Reference external documentation (tool docs, best practices)
- Forbidden paths:
  - Modifying repository code directly
  - Executing arbitrary commands
  - Making external API calls (except documented tool lookups)

## Security and compliance
- Data classification: Repository metadata (potentially sensitive)
- AuthN/AuthZ: Inherits from Gas Town agent framework
- Logging/Audit: All inputs/outputs logged for pipeline traceability
- PII/Secrets: Must not expose secrets even if present in inputs
- Security constraints:
  - Generated guardrails must not weaken existing security posture
  - Must flag if requested principle conflicts with security best practices

## Test strategy
- Golden build command: N/A (documentation/specification project)
- Golden test command: N/A (documentation/specification project)
- Scenario to test mapping:
  - Scenario: Generate guardrails from complete inputs
    - Test type: Example validation (manual)
    - Suggested location: example_agent_run.md (already created)
  - Scenario: Handle missing repository conventions
    - Test type: Documentation review (manual)
    - Suggested location: engineering_principles_prompt.md (error handling section)
  - Scenario: Map principle to multiple guardrails
    - Test type: Example validation (manual)
    - Suggested location: example_agent_run.md (synthesis step)
  - Scenario: Adapt to different project types
    - Test type: Documentation (manual)
    - Suggested location: engineering_principles_prompt.md (customization section)

## Engineering principles and DoD additions
- Principle: **Specificity** - All guardrails must be concrete (tool + command + threshold)
- Principle: **Actionability** - All DoD items must be verifiable (pass/fail, no ambiguity)
- Principle: **Consistency** - Output must align with provided conventions
- Principle: **Completeness** - Cover all critical engineering dimensions (quality, security, testing, docs, performance)

## Open questions
- None remaining (specification is complete)

## Definition of Done
- [x] Agent specification document created (engineering_principles_agent.md)
- [x] Prompt template created (engineering_principles_prompt.md)
- [x] Working example created (example_agent_run.md)
- [x] Spec.md updated with full specification
- [ ] Repo context updated (repo_context.md)
- [ ] PR created with all documentation
- [ ] Peer review completed
- [ ] Integrated into Gas Town pipeline documentation (if applicable)

## Definition of Ready
- [x] Scope in/out defined
- [x] Gherkin scenarios are present and testable
- [x] Architecture alignment reviewed and constraints captured
- [x] Security/compliance reviewed and constraints captured
- [x] Test strategy defined for each scenario
- [x] Repo golden commands known or explicitly blocked (N/A for docs)
- [x] Allowed/forbidden paths set
- [x] No blocking questions remain