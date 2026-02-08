#!/usr/bin/env bash
set -euo pipefail

# Test Strategy Agent
# Analyzes Gherkin scenarios and repo context to generate test strategy

# Get ticket directory from argument
TICKET_DIR="${1:?Error: Ticket directory required}"

# Validate ticket directory exists
[ ! -d "$TICKET_DIR" ] && {
    echo "Error: Ticket directory not found: $TICKET_DIR" >&2
    exit 1
}

# Define file paths
SPEC_FILE="$TICKET_DIR/spec.md"
REPO_CONTEXT_FILE="$TICKET_DIR/repo_context.md"

# Validate required files exist
[ ! -f "$SPEC_FILE" ] && {
    echo "Error: spec.md not found in $TICKET_DIR" >&2
    exit 1
}

[ ! -f "$REPO_CONTEXT_FILE" ] && {
    echo "Error: repo_context.md not found in $TICKET_DIR" >&2
    exit 1
}

# Read the files
SPEC_CONTENT=$(<"$SPEC_FILE")
REPO_CONTEXT=$(<"$REPO_CONTEXT_FILE")

# Extract Gherkin scenarios from spec.md (between "## Acceptance Criteria" and next "##")
GHERKIN=$(echo "$SPEC_CONTENT" | sed -n '/## Acceptance Criteria/,/^## /p' | sed '$d')

# If Gherkin is empty or just contains the header, report blocker
if [ -z "$GHERKIN" ] || ! echo "$GHERKIN" | grep -q "Feature:\|Scenario:"; then
    echo "BLOCKER: No Gherkin scenarios found in Acceptance Criteria section"
    exit 1
fi

# Create prompt for Claude
PROMPT=$(cat <<'EOF_PROMPT'
You are the Test Strategy Agent for vault67, a multi-agent ticket refinement system.

Your job is to analyze Gherkin acceptance criteria and repository context to generate a comprehensive test strategy.

# INPUTS

## Gherkin Acceptance Criteria:
```gherkin
GHERKIN_PLACEHOLDER
```

## Repository Context:
```markdown
REPO_CONTEXT_PLACEHOLDER
```

# YOUR TASK

Generate a test strategy that includes:

1. **Golden build command**: The command to build the project (from repo context, or infer from common patterns)
2. **Golden test command**: The command to run tests (from repo context, or infer from common patterns)
3. **Scenario to test mapping**: For EACH Gherkin scenario, provide:
   - Scenario name
   - Test type (unit/integration/e2e/manual)
   - Suggested location (folder/file path based on repo structure)
   - Brief rationale for the test type choice

# RULES

- If repo_context.md already has golden commands filled in, USE THOSE EXACTLY
- If golden commands are missing, infer from repo structure (package.json, Makefile, go.mod, etc.)
- If you cannot determine golden commands, output: "BLOCKER: Unable to determine build/test commands"
- Map each scenario to the most appropriate test type:
  - **unit**: Tests single functions/methods in isolation
  - **integration**: Tests interaction between components/modules
  - **e2e**: Tests full user workflows through the system
  - **manual**: Tests that require human interaction (UI/UX verification, etc.)
- Suggest realistic file paths based on the repo structure from repo_context
- If repo structure is unclear, use common conventions for the language/framework

# OUTPUT FORMAT

Provide ONLY the following YAML structure (no markdown code fences, no extra text):

golden_build_command: <command or "BLOCKER: reason">
golden_test_command: <command or "BLOCKER: reason">
scenarios:
  - name: <scenario name>
    test_type: <unit|integration|e2e|manual>
    location: <suggested folder/file path>
    rationale: <brief explanation>
  - name: <next scenario name>
    test_type: <unit|integration|e2e|manual>
    location: <suggested folder/file path>
    rationale: <brief explanation>

EOF_PROMPT
)

# Replace placeholders in prompt
PROMPT="${PROMPT//GHERKIN_PLACEHOLDER/$GHERKIN}"
PROMPT="${PROMPT//REPO_CONTEXT_PLACEHOLDER/$REPO_CONTEXT}"

# Call Claude CLI to generate test strategy
echo "→ Analyzing scenarios and generating test strategy..." >&2

CLAUDE_RESPONSE=$(echo "$PROMPT" | claude -p --model sonnet 2>&1) || {
    echo "Error: Claude CLI failed" >&2
    echo "Response: $CLAUDE_RESPONSE" >&2
    exit 1
}

# Check if response contains BLOCKER
if echo "$CLAUDE_RESPONSE" | grep -q "BLOCKER:"; then
    echo "BLOCKER: $(echo "$CLAUDE_RESPONSE" | grep "BLOCKER:" | head -1)" >&2
    exit 1
fi

# Parse the YAML response
GOLDEN_BUILD=$(echo "$CLAUDE_RESPONSE" | grep "^golden_build_command:" | sed 's/^golden_build_command: //' || echo "")
GOLDEN_TEST=$(echo "$CLAUDE_RESPONSE" | grep "^golden_test_command:" | sed 's/^golden_test_command: //' || echo "")

# Extract scenarios section
SCENARIOS=$(echo "$CLAUDE_RESPONSE" | sed -n '/^scenarios:/,$p')

# Build the test strategy section content
TEST_STRATEGY=$(cat <<EOF
## Test strategy
- Golden build command: ${GOLDEN_BUILD:-"(to be determined)"}
- Golden test command: ${GOLDEN_TEST:-"(to be determined)"}
- Scenario to test mapping:
EOF
)

# Parse and format each scenario
echo "$SCENARIOS" | grep -A 4 "  - name:" | while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]name:[[:space:]](.+)$ ]]; then
        TEST_STRATEGY="$TEST_STRATEGY
  - Scenario: ${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^[[:space:]]*test_type:[[:space:]](.+)$ ]]; then
        TEST_STRATEGY="$TEST_STRATEGY
    - Test type: ${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^[[:space:]]*location:[[:space:]](.+)$ ]]; then
        TEST_STRATEGY="$TEST_STRATEGY
    - Suggested location: ${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^[[:space:]]*rationale:[[:space:]](.+)$ ]]; then
        TEST_STRATEGY="$TEST_STRATEGY
    - Rationale: ${BASH_REMATCH[1]}"
    fi
done

# Update spec.md by replacing the Test strategy section
# Find the line number where "## Test strategy" starts
START_LINE=$(grep -n "^## Test strategy" "$SPEC_FILE" | cut -d: -f1)

if [ -z "$START_LINE" ]; then
    echo "Error: Could not find '## Test strategy' section in spec.md" >&2
    exit 1
fi

# Find the next section after Test strategy (next line starting with ##)
END_LINE=$(tail -n +$((START_LINE + 1)) "$SPEC_FILE" | grep -n "^## " | head -1 | cut -d: -f1)

if [ -n "$END_LINE" ]; then
    # Calculate actual line number
    END_LINE=$((START_LINE + END_LINE))
    # Replace the section
    {
        head -n $((START_LINE - 1)) "$SPEC_FILE"
        echo "$TEST_STRATEGY"
        echo ""
        tail -n +$END_LINE "$SPEC_FILE"
    } > "$SPEC_FILE.tmp"
else
    # Test strategy section is at the end of file
    {
        head -n $((START_LINE - 1)) "$SPEC_FILE"
        echo "$TEST_STRATEGY"
    } > "$SPEC_FILE.tmp"
fi

# Replace original file
mv "$SPEC_FILE.tmp" "$SPEC_FILE"

echo "✓ Test strategy updated in spec.md" >&2
exit 0
