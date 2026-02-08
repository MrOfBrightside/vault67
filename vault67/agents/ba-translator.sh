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

# Extract raw requirements from spec.md
extract_raw_requirements() {
    local spec_file="$1"

    # Extract everything from "## Requirements (Raw, BA input)" to the next ## heading
    awk '
        /^## Requirements \(Raw, BA input\)/ {
            found=1
            next
        }
        found && /^##/ {
            exit
        }
        found {
            print
        }
    ' "$spec_file"
}

# Extract context and goal from spec.md
extract_context_goal() {
    local spec_file="$1"
    local section="$2"

    awk -v section="## $section" '
        $0 ~ section {
            found=1
            next
        }
        found && /^##/ {
            exit
        }
        found && NF {
            print
        }
    ' "$spec_file"
}

# Read raw requirements
RAW_REQUIREMENTS=$(extract_raw_requirements "$SPEC_FILE")
CONTEXT=$(extract_context_goal "$SPEC_FILE" "Context")
GOAL=$(extract_context_goal "$SPEC_FILE" "Goal")

# Check if requirements are empty
if [ -z "$(echo "$RAW_REQUIREMENTS" | tr -d ' \n-')" ]; then
    warn "No raw requirements found in spec.md"
    warn "Adding blocking question to questions.md"

    # Add blocking question
    cat >> "$QUESTIONS_FILE" <<EOF

## Blocking question (added by BA Translator Agent)
1) The "Requirements (Raw, BA input)" section in spec.md is empty or contains only placeholders. What are the actual requirements for this ticket?
   - Answer: [Please provide detailed requirements]
EOF

    success "Added blocking question to questions.md"
    exit 0
fi

# Read repo context
REPO_CONTEXT=$(cat "$REPO_CONTEXT_FILE")

info "Generating Gherkin scenarios from requirements..."

# Create prompt for Claude to generate Gherkin scenarios
PROMPT=$(cat <<EOF
You are a Business Analyst Translator Agent. Your job is to transform raw business requirements into clear, testable Gherkin acceptance criteria.

# Context
$CONTEXT

# Goal
$GOAL

# Raw Requirements (from BA)
$RAW_REQUIREMENTS

# Repository Context
$REPO_CONTEXT

# Your Task
Transform the raw requirements into precise Gherkin scenarios following this format:

Feature: <clear feature name>

  Scenario: <specific scenario name>
    Given <preconditions>
    When <action/trigger>
    Then <expected outcome>

# Guidelines
1. Create one or more scenarios that cover all the requirements
2. Each scenario should be independently testable
3. Use concrete examples rather than abstract descriptions
4. Scenarios should be implementation-agnostic (describe WHAT, not HOW)
5. If requirements are unclear, ambiguous, or incomplete, note specific questions

# Output Format
Provide ONLY the Gherkin scenarios in your response, formatted exactly as shown above.
If you have questions about unclear requirements, start your response with "QUESTIONS:" followed by numbered questions, then provide "SCENARIOS:" with your best interpretation.

Begin your response now:
EOF
)

# Create a temporary file for the prompt
PROMPT_FILE=$(mktemp)
echo "$PROMPT" > "$PROMPT_FILE"

# Try to use Claude Code's claude command if available
if command -v claude &> /dev/null; then
    info "Using Claude CLI to generate scenarios..."
    RESPONSE=$(claude -p "$PROMPT_FILE" 2>/dev/null || echo "")
else
    # Fallback: create a marker file for manual processing
    warn "Claude CLI not available"
    warn "Creating prompt file for manual processing: $TICKET_DIR/ba-translator-prompt.txt"
    cp "$PROMPT_FILE" "$TICKET_DIR/ba-translator-prompt.txt"
    error "Please run Claude manually with the prompt file and update spec.md"
fi

rm -f "$PROMPT_FILE"

# Parse response for questions and scenarios
if echo "$RESPONSE" | grep -q "^QUESTIONS:"; then
    info "Agent identified unclear requirements"

    # Extract questions
    QUESTIONS=$(echo "$RESPONSE" | awk '/^QUESTIONS:/,/^SCENARIOS:/ {print}' | grep -v "^QUESTIONS:" | grep -v "^SCENARIOS:")

    if [ -n "$QUESTIONS" ]; then
        warn "Adding blocking questions to questions.md"
        cat >> "$QUESTIONS_FILE" <<EOF

## Blocking questions (added by BA Translator Agent)
$QUESTIONS
EOF
        success "Added questions to questions.md"
    fi

    # Extract scenarios
    SCENARIOS=$(echo "$RESPONSE" | awk '/^SCENARIOS:/,0 {print}' | grep -v "^SCENARIOS:")
else
    SCENARIOS="$RESPONSE"
fi

# Update spec.md with generated scenarios
if [ -n "$SCENARIOS" ]; then
    info "Updating spec.md with generated scenarios..."

    # Create a temporary file with the updated spec
    TMP_SPEC=$(mktemp)

    # Replace the Acceptance Criteria section
    awk -v scenarios="$SCENARIOS" '
        /^## Acceptance Criteria \(Gherkin\)/ {
            print
            print ""
            print scenarios
            skip=1
            next
        }
        skip && /^##/ {
            skip=0
        }
        !skip {
            print
        }
    ' "$SPEC_FILE" > "$TMP_SPEC"

    # Replace the original file
    mv "$TMP_SPEC" "$SPEC_FILE"
    success "Updated Acceptance Criteria in spec.md"
else
    warn "No scenarios generated"
fi

success "BA Translator Agent completed"
