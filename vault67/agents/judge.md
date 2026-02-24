# Judge Agent - Definition of Ready

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

### 10. Engineering principles captured
- section: ## Engineering principles and DoD additions
- pattern: ^-[[:space:]]*[^[:space:]]
- grep_range: 15

### 11. Fields contain distinct content
- special: check_duplicate_fields

### 12. Sufficient detail provided
- special: check_substance_threshold
- min_substance: 4
