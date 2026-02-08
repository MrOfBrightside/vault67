#!/usr/bin/env bash
set -euo pipefail

# Engineering Principles Agent
# Analyzes repo conventions and team principles to generate development guardrails and DoD additions
#
# Usage: engineering_principles.sh <ticket_dir>
#
# Input:
#   - spec.md: Context, goal, acceptance criteria, architecture alignment, security constraints
#   - repo_context.md: Repository conventions, coding standards, architecture docs
#
# Output:
#   - Updates spec.md: Fills in "Engineering principles and DoD additions" section
#   - Updates questions.md: Adds blocking questions if conventions are unclear

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
[ $# -eq 0 ] && error "Usage: engineering_principles.sh <ticket_dir>"

TICKET_DIR="$1"
[ ! -d "$TICKET_DIR" ] && error "Ticket directory not found: $TICKET_DIR"

SPEC_FILE="$TICKET_DIR/spec.md"
REPO_CONTEXT_FILE="$TICKET_DIR/repo_context.md"
QUESTIONS_FILE="$TICKET_DIR/questions.md"

# Validate required files
[ ! -f "$SPEC_FILE" ] && error "spec.md not found in $TICKET_DIR"
[ ! -f "$REPO_CONTEXT_FILE" ] && error "repo_context.md not found in $TICKET_DIR"
[ ! -f "$QUESTIONS_FILE" ] && error "questions.md not found in $TICKET_DIR"

info "Engineering Principles Agent starting..."
info "Ticket directory: $TICKET_DIR"

# Extract sections from spec.md
extract_section() {
    local file="$1"
    local section="$2"

    awk -v section="## $section" '
        $0 ~ section {
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

# Read all relevant sections
CONTEXT=$(extract_section "$SPEC_FILE" "Context")
GOAL=$(extract_section "$SPEC_FILE" "Goal")
SCOPE=$(extract_section "$SPEC_FILE" "Scope")
ACCEPTANCE_CRITERIA=$(extract_section "$SPEC_FILE" "Acceptance Criteria (Gherkin)")
ARCHITECTURE=$(extract_section "$SPEC_FILE" "Architecture alignment")
SECURITY=$(extract_section "$SPEC_FILE" "Security and compliance")
TEST_STRATEGY=$(extract_section "$SPEC_FILE" "Test strategy")
REPO_CONTEXT=$(cat "$REPO_CONTEXT_FILE")

# Check if we have sufficient input
if [ -z "$(echo "$CONTEXT$GOAL$ACCEPTANCE_CRITERIA" | tr -d ' \n-')" ]; then
    warn "Insufficient specification data to generate engineering principles"
    warn "Need at least Context, Goal, or Acceptance Criteria filled in"

    cat >> "$QUESTIONS_FILE" <<EOF

## Blocking question (added by Engineering Principles Agent)
1) The spec.md file needs more information before engineering principles can be generated. Please ensure Context, Goal, and/or Acceptance Criteria sections are filled in.
   - Answer: [Complete the required sections]
EOF

    success "Added blocking question to questions.md"
    exit 0
fi

info "Generating engineering principles and DoD additions..."

# Create prompt for Claude
PROMPT=$(cat <<EOF
You are the Engineering Principles Agent for vault67, a multi-agent ticket refinement system.

Your job is to analyze the ticket specification and repository context to generate:
1. Engineering principles - specific guardrails for implementing this ticket
2. Definition of Done additions - extra DoD items beyond the standard checklist

# INPUTS

## Context
$CONTEXT

## Goal
$GOAL

## Scope
$SCOPE

## Acceptance Criteria (Gherkin)
$ACCEPTANCE_CRITERIA

## Architecture Alignment
$ARCHITECTURE

## Security and Compliance
$SECURITY

## Test Strategy
$TEST_STRATEGY

## Repository Context
$REPO_CONTEXT

# YOUR TASK

Generate engineering principles and DoD additions that are:
- **Specific to this ticket** (not generic advice)
- **Actionable** (clear what to do/not do)
- **Relevant** (based on the requirements, architecture, and security constraints)

# RULES

1. **Engineering Principles** should include:
   - Code quality guardrails specific to this implementation
   - Performance considerations (if relevant)
   - Error handling requirements
   - Logging/observability needs
   - Edge cases to handle
   - Anti-patterns to avoid
   - Integration points to be careful with
   - Data validation rules
   - Backward compatibility considerations

2. **DoD Additions** should include:
   - Extra verification steps beyond standard DoD
   - Specific tests that must pass
   - Documentation that must be updated
   - Performance benchmarks to meet (if applicable)
   - Security checks to complete
   - Migration steps (if applicable)
   - Rollback considerations

3. **Keep it concise**: Each principle should be 1-2 sentences
4. **Be specific**: Reference actual components, patterns, or constraints from the inputs
5. **Skip if not applicable**: If the ticket is simple, it's OK to have fewer principles
6. **Focus on risks**: What could go wrong? What mistakes are easy to make here?

# OUTPUT FORMAT

Provide ONLY a bulleted markdown list. No section headers, no extra text. Format:

- **Principle name**: Description
- **Another principle**: Description
- DoD: Specific DoD addition
- DoD: Another DoD addition

Begin your response now:
EOF
)

# Create a temporary file for the prompt
PROMPT_FILE=$(mktemp)
echo "$PROMPT" > "$PROMPT_FILE"

# Try to use Claude Code's claude command if available
if command -v claude &> /dev/null; then
    info "Using Claude CLI to generate principles..."
    RESPONSE=$(claude -p "$PROMPT_FILE" --model sonnet 2>/dev/null || echo "")

    if [ -z "$RESPONSE" ]; then
        error "Claude CLI returned empty response"
    fi
else
    # Fallback: create a marker file for manual processing
    warn "Claude CLI not available"
    warn "Creating prompt file for manual processing: $TICKET_DIR/engineering-principles-prompt.txt"
    cp "$PROMPT_FILE" "$TICKET_DIR/engineering-principles-prompt.txt"
    error "Please run Claude manually with the prompt file and update spec.md"
fi

rm -f "$PROMPT_FILE"

# Update spec.md with generated principles
if [ -n "$RESPONSE" ]; then
    info "Updating spec.md with engineering principles..."

    # Create a temporary file with the updated spec
    TMP_SPEC=$(mktemp)

    # Replace the "Engineering principles and DoD additions" section
    awk -v principles="$RESPONSE" '
        /^## Engineering principles and DoD additions/ {
            print
            print principles
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
    success "Updated 'Engineering principles and DoD additions' in spec.md"
else
    warn "No principles generated"
fi

success "Engineering Principles Agent completed"
