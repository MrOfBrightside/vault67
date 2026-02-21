# Judge Agent - Definition of Ready

## Criteria
# Each criterion has: name, section to check, grep pattern(s)
# Logic: "and" = all patterns must match, "or" = any pattern matches

### 1. Scope in/out defined
- section: ### In scope
- pattern: ^-[[:space:]]*[^[:space:]]
- and_section: ### Out of scope
- and_pattern: ^-[[:space:]]*[^[:space:]]

### 2. Gherkin scenarios are present and testable
- section: ## Acceptance Criteria (Gherkin)
- pattern: Feature:\s+\w
- and_pattern: Scenario:\s+\w
- and_pattern: Given\s+\w
- and_pattern: When\s+\w
- and_pattern: Then\s+\w

### 3. Architecture alignment reviewed and constraints captured
- section: ## Architecture alignment
- pattern: - Relevant modules:[[:space:]]*[^[:space:]]
- or_pattern: - Constraints:[[:space:]]*[^[:space:]]
- grep_range: 10

### 4. Security/compliance reviewed and constraints captured
- section: ## Security and compliance
- pattern: - [[:alnum:]]*:[[:space:]]*[^[:space:]]
- or_pattern: N/A|not applicable
- grep_range: 10

### 5. Test strategy defined for each scenario
- section: ## Test strategy
- pattern: - Golden build command:[[:space:]]*[^[:space:]]
- and_pattern: - Golden test command:[[:space:]]*[^[:space:]]
- grep_range: 10

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
