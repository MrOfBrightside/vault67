# PLAN: CLI-first Multi-Agent Refinement -> READY_TO_IMPLEMENT -> Gas Town (MD-only)

## CLI Commands (v0)

### Create
`ticket create --title "<title>" --repo "<path_or_url>" --base-ref "main"`

Creates the folder and the MD files.

### Refine (main entrypoint)
`refine <id>` 

Does:
1) set `state -> REFINING`
2) update `repo_context.md` (scan repo)
3) run agents in order (patching `spec.md` and possibly `questions.md`)
4) run Judge to update DoR checklist
5) if blocking questions exist -> `state -> NEEDS_INFO` and stop
6) if DoR passes -> `state -> READY_TO_IMPLEMENT`, bump `spec_version`, generate `promptpack.md`

### Answer (HITL)
`answer <id>`

Validates `questions.md` contains answers and re-enables refinement.

### Implement (handover to Gas Town)
`implement <id> --executor gastown`

Guard:
- require `state == READY_TO_IMPLEMENT`

Then:
- atomically set `state -> IMPLEMENTING`
- run Gas Town with `promptpack.md` as the single input
- append result to `runs.md`

---

## Multi-Agent Refinement Pipeline

Agents run in this exact order and are constrained to specific sections in `spec.md`.

1) **BA Translator Agent**
- Input: BA raw requirements + repo context
- Output: Gherkin scenarios (Acceptance Criteria)
- Adds: open questions if requirements are unclear

2) **Architecture Compliance Agent**
- Input: repo_context + gherkin
- Output: architecture alignment notes, constraints, allowed/forbidden paths

3) **Security & Compliance Agent**
- Input: gherkin + repo_context
- Output: security requirements (auth/logging/PII/secrets), guardrails

4) **Test Strategy Agent**
- Input: gherkin + repo_context test structure
- Output: mapping from each scenario -> test approach (unit/integration/e2e)
- Ensures golden build/test commands exist or flags blocker

5) **Engineering Principles Agent**
- Input: repo conventions + team principles
- Output: development guardrails and DoD additions

6) **Judge Agent (Gatekeeper)**
- Updates Definition of Ready checklist
- If blockers -> writes questions and instructs `NEEDS_INFO`
- If ready -> instructs `READY_TO_IMPLEMENT` and promptpack generation

---

## Definition of Ready (DoR) for READY_TO_IMPLEMENT

A ticket can move to `READY_TO_IMPLEMENT` only when ALL are true:
- Scope is defined (in scope + out of scope)
- Gherkin scenarios exist and are testable
- Architecture constraints captured (including allowed/forbidden paths)
- Security/compliance constraints captured (or explicitly not applicable)
- Test strategy defined for each scenario
- Repo golden commands known for build and test (or explicit BLOCKED reason)
- No blocking open questions remain

Judge marks these in `spec.md`.

---

## File Templates (copy/paste)

### ticket.md
```md
---
id: TCK-000123
title: ""
state: NEW
spec_version: 0
repo: ""
base_ref: "main"
executor: "gastown"
created_at: ""
updated_at: ""
---

# Summary
Short description of the work.

## Links
- Issue:
- PR:

## Notes
-