# Judge Agent - Definition of Ready

## System prompt
You are a quality gate judge performing a final substance check on a software specification.

You receive the complete spec. Your ONLY job is to identify fields that look filled but actually contain:
1. Generic content that could apply to any spec (not specific to this feature)
2. Content that contradicts other sections (e.g., security says "No auth" but Gherkin has login scenarios)
3. Security/test/architecture sections that don't align with the Gherkin acceptance criteria
4. Fabricated details that sound plausible but weren't derived from real user input

You do NOT check structural completeness (that's handled by other criteria).
For each problem found, output a CONCERN: line with the specific issue. If no problems, output PASS.

## Format Reference
# Each criterion has: name (the ### header), and a set of key-value fields.
#
# Fields:
#   section:        Markdown section header to search within
#   pattern:        Primary grep pattern (POSIX extended regex)
#   and_section:    Additional section that must ALSO contain a match
#   and_pattern:    Additional pattern that must ALSO match (can repeat)
#   or_pattern:     Alternative pattern; criterion passes if ANY or_pattern matches
#   reject_pattern: If this pattern matches inside the section, the criterion FAILS
#                   (used to catch generic placeholders / garbage content)
#   min_matches:    "pattern N" — require at least N matches of the given pattern
#   grep_range:     Number of lines to scan after the section header (default: all)
#   question:       Blocking question auto-generated when this criterion fails
#   special:        Name of a built-in check function instead of pattern matching
#   min_substance:  Parameter for special checks that need a numeric threshold
#
# Logic:
#   "and"  = all patterns/sections must match for the criterion to pass
#   "or"   = any one of the or_patterns matching is sufficient
#   Reject patterns are evaluated AFTER positive matches; a reject hit overrides a pass.

## Criteria

### 1. Scope in/out defined
- section: ### In scope
- pattern: ^-[[:space:]]*[^[:space:]]
- and_section: ### Out of scope
- and_pattern: ^-[[:space:]]*[^[:space:]]
- question: What is in scope for this work? Please list specific deliverables.

### 2. Gherkin scenarios are present and testable
- section: ## Acceptance Criteria (Gherkin)
- pattern: Feature:\s+\w
- and_pattern: Scenario:\s+\w
- and_pattern: Given\s+\w
- and_pattern: When\s+\w
- and_pattern: Then\s+\w
- reject_pattern: works as expected|works as specified|the feature is used|the system is configured|expected behavior occurs|feature name|scenario name|TODO|TBD|to be determined|to be defined|needs clarification|prerequisites are defined|actions are specified|expected outcomes are documented|placeholder|the system works correctly|it should work|the result is correct
- min_matches: Scenario: 2
- question: What are the key user scenarios? Please describe at least 2 concrete workflows with expected outcomes.

### 3. Architecture alignment reviewed and constraints captured
- section: ## Architecture alignment
- pattern: - Relevant modules:[[:space:]]*[^[:space:]]
- or_pattern: - Constraints:[[:space:]]*[^[:space:]]
- or_pattern: - Detected stack:[[:space:]]*[^[:space:]]
- grep_range: 10

### 4. Security/compliance reviewed and constraints captured
- section: ## Security and compliance
- pattern: - [^:]+:[[:space:]]+[^[:space:]]
- or_pattern: (^|[[:space:]])N/A($|[[:space:],;])|not applicable
- grep_range: 10

### 5. Test strategy defined for each scenario
- section: ## Test strategy
- pattern: - Scenario:[[:space:]]*[^[:space:]]
- or_pattern: \| Scenario[[:space:]]*\|
- and_pattern: (Unit|Integration|E2E|e2e) tests:
- grep_range: 20
- question: What test approach is needed? Which scenarios need unit vs integration vs e2e tests?

### 6. Repo golden commands known or explicitly blocked
- section: ## Test strategy
- pattern: - Golden build command:[[:space:]]*[^[:space:]]
- and_pattern: - Golden test command:[[:space:]]*[^[:space:]]
- grep_range: 10

### 7. Allowed/forbidden paths set
- section: ## Architecture alignment
- pattern: - Allowed paths:[[:space:]]*[^[:space:]]
- or_pattern: - Forbidden paths:[[:space:]]*[^[:space:]]
- grep_range: 10

### 8. No blocking questions remain
- special: check_blocking_questions

### 9. Code structure reviewed
- section: ## Code structure
- pattern: - Module pattern:[[:space:]]*[^[:space:]]
- grep_range: 10
- question: What is the expected code structure? Which modules or patterns should be used?

### 10. Engineering principles captured
- section: ## Engineering principles and DoD additions
- pattern: ^-[[:space:]]*[^[:space:]]
- grep_range: 15
- question: What engineering principles or definition-of-done criteria apply to this work?

### 11. Fields contain distinct content
- special: check_duplicate_fields
- question: The Context, Goal, Requirements, and Scope fields contain duplicate content. Can you provide distinct descriptions for each?

### 12. Sufficient detail provided
- special: check_substance_threshold
- min_substance: 4
- question: The spec lacks sufficient detail. Can you provide more context about the problem, goals, and specific requirements?

### 13. LLM substance check
- special: llm_substance_check
- question: The spec contains sections that may not be specific to this feature. Can you verify the content is accurate?
