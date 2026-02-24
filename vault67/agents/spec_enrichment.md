# Spec Enrichment Agent

## Placeholder patterns
# Extended regex patterns (one per line) that identify template/placeholder content.
# Lines matching ANY of these are excluded when counting substantive content.
^[[:space:]]*$
^[[:space:]]*-[[:space:]]*$
^Why is this needed
^What must be true
^What problem
TODO
TBD
to be determined
to be defined
needs clarification
Part of project:
Project scope:

## Substance threshold
# Minimum number of substantive lines (non-placeholder) required.
4

## Prompt rules
# Guidelines the LLM must follow when expanding thin specs.
# One rule per line, prefixed with number and period.
1. Context: Explain WHY this work is needed (1-3 sentences). What problem exists?
2. Goal: State WHAT must be true after implementation (1-2 sentences). Measurable outcomes.
3. Requirements: List 3-5 specific, concrete requirements as bullet points.
4. In Scope: List 2-4 specific deliverables as bullet points.
5. Each field MUST have DIFFERENT content - no copy-pasting between fields.
6. Be specific to the title/topic - no generic software platitudes.
7. If you genuinely cannot infer enough, say INSUFFICIENT on its own line.
