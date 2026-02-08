# Repo Context

## Repo
- Path/URL: vault67/polecats/quartz
- Base ref: main
- Language/runtime: Documentation/Specification (Markdown)
- Main components/modules:
  - Engineering Principles Agent specification
  - Prompt templates for agent invocation
  - Example transformations and outputs
- Architecture docs: engineering_principles_agent.md
- Coding conventions: N/A (documentation project)

## How to build (golden command)
- Command(s): N/A (documentation project, no build step)
- Notes: Files are markdown documents consumed by Gas Town agents

## How to test (golden command)
- Command(s): Manual review and validation
- Test types present: Example validation (manual)
- Notes: Testing involves validating examples match specifications

## CI/CD signals
- Pipeline file(s): None yet (documentation project)
- Quality gates: Manual peer review

## Relevant code areas
- Likely folders/modules:
  - /vault67/ - Root documentation directory
  - /vault67/tickets/ - Ticket templates and examples
- Key files (if known):
  - engineering_principles_agent.md - Main agent specification
  - engineering_principles_prompt.md - Prompt template for invocation
  - example_agent_run.md - Working example with inputs/outputs
  - spec.md - Formal specification document

## Snippets (short)
> Keep snippets short. Prefer paths and small excerpts.

- Path: engineering_principles_agent.md
  - Excerpt: "Agent #5 in refinement pipeline. Input: repo conventions + team principles. Output: development guardrails and DoD additions."

- Path: engineering_principles_prompt.md
  - Excerpt: "Transform repository conventions and team engineering principles into concrete, actionable development guardrails and Definition of Done additions."

- Path: example_agent_run.md
  - Excerpt: Shows complete transformation from TypeScript/Express conventions + team principles → guardrails.yaml + dod_additions.md