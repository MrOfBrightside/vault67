#!/usr/bin/env bash
set -euo pipefail

# BA Translator Agent v2
# Transforms raw BA requirements into Gherkin acceptance criteria
# Uses Claude Code directly for better integration
#
# Usage: ba-translator-v2.sh <ticket_dir>

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
[ $# -eq 0 ] && error "Usage: ba-translator-v2.sh <ticket_dir>"

TICKET_DIR="$1"
[ ! -d "$TICKET_DIR" ] && error "Ticket directory not found: $TICKET_DIR"

SPEC_FILE="$TICKET_DIR/spec.md"
QUESTIONS_FILE="$TICKET_DIR/questions.md"

# Validate required files
[ ! -f "$SPEC_FILE" ] && error "spec.md not found in $TICKET_DIR"
[ ! -f "$QUESTIONS_FILE" ] && error "questions.md not found in $TICKET_DIR"

info "BA Translator Agent v2 starting..."
info "Ticket directory: $TICKET_DIR"

# Extract raw requirements from spec.md
extract_section() {
    local file="$1"
    local section_header="$2"
    local stop_pattern="${3:-^##}"

    awk -v header="$section_header" -v stop="$stop_pattern" '
        $0 ~ header {
            found=1
            next
        }
        found && $0 ~ stop {
            exit
        }
        found {
            print
        }
    ' "$file"
}

RAW_REQUIREMENTS=$(extract_section "$SPEC_FILE" "^## Requirements \\(Raw, BA input\\)")
CONTEXT=$(extract_section "$SPEC_FILE" "^## Context")
GOAL=$(extract_section "$SPEC_FILE" "^## Goal")

# Check if requirements are empty or just template
if [ -z "$(echo "$RAW_REQUIREMENTS" | grep -v '^-$' | grep -v '^$' | tr -d ' \n')" ]; then
    warn "No raw requirements found in spec.md"
    warn "Adding blocking question to questions.md"

    cat >> "$QUESTIONS_FILE" <<EOF

## Blocking question (added by BA Translator Agent)
1) The "Requirements (Raw, BA input)" section in spec.md is empty or contains only placeholders. What are the actual requirements for this ticket?
   - Answer: [Please provide detailed requirements]
EOF

    success "Added blocking question to questions.md"
    exit 0
fi

info "Found requirements, generating Gherkin scenarios..."

# For this implementation, we'll generate a prompt that can be used with Claude
# Since we're running inside Claude Code, we can actually call ourselves!

PROMPT_FILE="$TICKET_DIR/ba-translator-prompt.txt"

cat > "$PROMPT_FILE" <<EOF
You are a Business Analyst Translator Agent. Transform the following raw business requirements into clear, testable Gherkin acceptance criteria.

Context:
$CONTEXT

Goal:
$GOAL

Raw Requirements:
$RAW_REQUIREMENTS

Generate Gherkin scenarios in this format:

Feature: <clear feature name>

  Scenario: <specific scenario name>
    Given <preconditions>
    When <action/trigger>
    Then <expected outcome>

Guidelines:
1. Create scenarios that cover all the requirements
2. Each scenario should be independently testable
3. Use concrete examples rather than abstractions
4. Be implementation-agnostic (describe WHAT, not HOW)
5. If requirements are unclear, note questions separately

Provide ONLY the Gherkin scenarios in your response.
EOF

info "Prompt file created: $PROMPT_FILE"
info "To complete this step, either:"
echo "  1. Run Claude Code with the prompt file"
echo "  2. Or manually paste the scenarios into spec.md"

# Since we're already in Claude Code context, we can note this for manual intervention
# or the refine command can handle this differently

success "BA Translator Agent v2 prepared prompt"
warn "Manual step required: Apply Gherkin scenarios to spec.md"

exit 0
