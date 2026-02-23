#!/usr/bin/env bash
set -euo pipefail

# BA Translator Agent
# Transforms raw BA requirements into Gherkin acceptance criteria
#
# Usage: ba-translator.sh <ticket_dir>
#
# Input:
#   - spec.md: Raw BA requirements in "Requirements (Raw, BA input)" section
#   - repo_context.md: Repository context
#
# Output:
#   - Updates spec.md: Fills in "Acceptance Criteria (Gherkin)" section
#   - Updates questions.md: Adds blocking questions if requirements unclear

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

error() {
    echo -e "${RED}Error: $*${NC}" >&2
    exit 1
}

success() {
    echo -e "${GREEN}✓ $*${NC}"
}

info() {
    echo -e "${BLUE}→ $*${NC}"
}

warn() {
    echo -e "${YELLOW}⚠ $*${NC}"
}

# Validate arguments
[ $# -eq 0 ] && error "Usage: ba-translator.sh <ticket_dir>"

TICKET_DIR="$1"
[ ! -d "$TICKET_DIR" ] && error "Ticket directory not found: $TICKET_DIR"

SPEC_FILE="$TICKET_DIR/spec.md"
REPO_CONTEXT_FILE="$TICKET_DIR/repo_context.md"
QUESTIONS_FILE="$TICKET_DIR/questions.md"

# Validate required files
[ ! -f "$SPEC_FILE" ] && error "spec.md not found in $TICKET_DIR"
[ ! -f "$REPO_CONTEXT_FILE" ] && error "repo_context.md not found in $TICKET_DIR"
[ ! -f "$QUESTIONS_FILE" ] && error "questions.md not found in $TICKET_DIR"

info "BA Translator Agent starting..."
info "Ticket directory: $TICKET_DIR"

# Extract section from spec.md
extract_section() {
    local file="$1"
    local section="$2"

    awk -v section="$section" '
        BEGIN {
            # Escape special regex characters in the section variable
            gsub(/[()[\]{}.*+?^$|\\]/, "\\\\&", section)
            pattern = "^## " section
        }
        $0 ~ pattern {
            found=1
            next
        }
        found && /^##/ {
            exit
        }
        found {
            print
        }
    ' "$file"
}

# Read sections from spec.md
RAW_REQUIREMENTS=$(extract_section "$SPEC_FILE" "Requirements (Raw, BA input)")
CONTEXT=$(extract_section "$SPEC_FILE" "Context")
GOAL=$(extract_section "$SPEC_FILE" "Goal")
SCOPE=$(extract_section "$SPEC_FILE" "Scope")

# Check if requirements are empty or just placeholders
if [ -z "$(echo "$RAW_REQUIREMENTS" | grep -v '^-$' | grep -v '^$' | tr -d ' \n')" ]; then
    warn "No raw requirements found in spec.md"
    warn "Adding blocking question to questions.md"

    cat >> "$QUESTIONS_FILE" <<'EOF'

## Blocking questions (added by BA Translator Agent)
1) The "Requirements (Raw, BA input)" section in spec.md is empty or contains only placeholders. What are the actual requirements for this ticket?
   - Answer: [Please provide detailed requirements]
EOF

    success "Added blocking question to questions.md"
    exit 0
fi

# Read repo context
REPO_CONTEXT=$(cat "$REPO_CONTEXT_FILE")

info "Generating Gherkin scenarios from requirements..."

# Create prompt for Claude
PROMPT=$(cat <<'EOF_PROMPT'
You are a Business Analyst Translator Agent. Your job is to transform raw business requirements into clear, testable Gherkin acceptance criteria.

# CONTEXT

CONTEXT_PLACEHOLDER

# GOAL

GOAL_PLACEHOLDER

# SCOPE

SCOPE_PLACEHOLDER

# RAW REQUIREMENTS (from BA)

REQUIREMENTS_PLACEHOLDER

# REPOSITORY CONTEXT

REPO_CONTEXT_PLACEHOLDER

# YOUR TASK

Transform the raw requirements into precise Gherkin scenarios following this format:

Feature: <clear feature name>

  Scenario: <specific scenario name>
    Given <preconditions>
    When <action/trigger>
    Then <expected outcome>

# GUIDELINES

1. Create one or more scenarios that cover all the requirements
2. Each scenario should be independently testable
3. Use concrete examples rather than abstract descriptions
4. Scenarios should be implementation-agnostic (describe WHAT, not HOW)
5. Include Given-When-Then clauses for each scenario
6. Use "And" to add additional conditions when needed
7. If requirements are unclear or incomplete, you can still generate scenarios but note specific questions

# OUTPUT FORMAT

If you have questions about unclear requirements, provide them first in this format:

QUESTIONS:
1. [Specific question about requirement]
2. [Another question if needed]

SCENARIOS:

Then provide the Gherkin scenarios (even if you have questions, provide your best interpretation).

If requirements are clear, provide ONLY the Gherkin scenarios without any markdown code fences, explanatory text, or other formatting.

Begin your response now:
EOF_PROMPT
)

# Replace placeholders
PROMPT="${PROMPT//CONTEXT_PLACEHOLDER/$CONTEXT}"
PROMPT="${PROMPT//GOAL_PLACEHOLDER/$GOAL}"
PROMPT="${PROMPT//SCOPE_PLACEHOLDER/$SCOPE}"
PROMPT="${PROMPT//REQUIREMENTS_PLACEHOLDER/$RAW_REQUIREMENTS}"
PROMPT="${PROMPT//REPO_CONTEXT_PLACEHOLDER/$REPO_CONTEXT}"

# Call Claude CLI to generate Gherkin scenarios
CLAUDE_RESPONSE=$(echo "$PROMPT" | claude -p --model sonnet 2>&1) || {
    error "Claude CLI failed. Response: $CLAUDE_RESPONSE"
}

# Check if response contains questions
if echo "$CLAUDE_RESPONSE" | grep -q "^QUESTIONS:"; then
    info "Agent identified unclear requirements"

    # Extract questions (everything between QUESTIONS: and SCENARIOS:)
    QUESTIONS=$(echo "$CLAUDE_RESPONSE" | awk '/^QUESTIONS:/,/^SCENARIOS:/ {print}' | grep -v "^QUESTIONS:" | grep -v "^SCENARIOS:" | sed '/^$/d')

    if [ -n "$QUESTIONS" ]; then
        warn "Adding clarifying questions to questions.md"
        cat >> "$QUESTIONS_FILE" <<EOF

## Questions (added by BA Translator Agent)
$QUESTIONS
EOF
        success "Added questions to questions.md"
    fi

    # Extract scenarios (everything after SCENARIOS:)
    SCENARIOS=$(echo "$CLAUDE_RESPONSE" | awk '/^SCENARIOS:/,0 {print}' | grep -v "^SCENARIOS:" | sed '/^$/d' | sed 's/^[[:space:]]*//')
else
    # No questions section, entire response is scenarios
    SCENARIOS="$CLAUDE_RESPONSE"
fi

# Clean up scenarios - remove markdown code fences if present
SCENARIOS=$(echo "$SCENARIOS" | sed '/^```/d')

# Validate that we got actual Gherkin scenarios
if ! echo "$SCENARIOS" | grep -q "Feature:\|Scenario:"; then
    error "Generated response does not contain valid Gherkin scenarios. Response: $SCENARIOS"
fi

# Update spec.md with generated scenarios
info "Updating spec.md with generated scenarios..."

# Find the line number where "## Acceptance Criteria (Gherkin)" starts
START_LINE=$(grep -n "^## Acceptance Criteria (Gherkin)" "$SPEC_FILE" | cut -d: -f1)

if [ -z "$START_LINE" ]; then
    # Try alternative header format
    START_LINE=$(grep -n "^## Acceptance Criteria" "$SPEC_FILE" | cut -d: -f1)
fi

if [ -z "$START_LINE" ]; then
    error "Could not find 'Acceptance Criteria' section in spec.md"
fi

# Find the next section after Acceptance Criteria (next line starting with ##)
END_LINE=$(tail -n +$((START_LINE + 1)) "$SPEC_FILE" | grep -n "^## " | head -1 | cut -d: -f1)

if [ -n "$END_LINE" ]; then
    # Calculate actual line number
    END_LINE=$((START_LINE + END_LINE))
    # Replace the section
    {
        head -n "$START_LINE" "$SPEC_FILE"
        echo "$SCENARIOS"
        echo ""
        tail -n +$END_LINE "$SPEC_FILE"
    } > "$SPEC_FILE.tmp"
else
    # Acceptance Criteria section is at the end of file
    {
        head -n "$START_LINE" "$SPEC_FILE"
        echo "$SCENARIOS"
    } > "$SPEC_FILE.tmp"
fi

# Replace original file
mv "$SPEC_FILE.tmp" "$SPEC_FILE"

success "Updated Acceptance Criteria in spec.md"
success "BA Translator Agent completed"
exit 0
