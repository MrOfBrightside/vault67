#!/usr/bin/env bash
set -euo pipefail

# Judge Agent (Gatekeeper)
# Final agent in the refinement pipeline that validates Definition of Ready
#
# Usage: judge.sh <ticket_dir>
#
# Input:
#   - spec.md: All sections filled by previous agents
#   - repo_context.md: Repository context
#   - questions.md: Any blocking questions
#
# Output:
#   - Updates spec.md: Marks DoR checklist items as complete/incomplete
#   - Updates questions.md: Adds blocking questions if DoR fails
#   - Returns exit code: 0 if READY_TO_IMPLEMENT, 1 if NEEDS_INFO

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0;0m'

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
[ $# -eq 0 ] && error "Usage: judge.sh <ticket_dir>"

TICKET_DIR="$1"
[ ! -d "$TICKET_DIR" ] && error "Ticket directory not found: $TICKET_DIR"

SPEC_FILE="$TICKET_DIR/spec.md"
REPO_CONTEXT_FILE="$TICKET_DIR/repo_context.md"
QUESTIONS_FILE="$TICKET_DIR/questions.md"

# Validate required files
[ ! -f "$SPEC_FILE" ] && error "spec.md not found in $TICKET_DIR"
[ ! -f "$REPO_CONTEXT_FILE" ] && error "repo_context.md not found in $TICKET_DIR"
[ ! -f "$QUESTIONS_FILE" ] && error "questions.md not found in $TICKET_DIR"

info "Judge Agent starting..."
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

# Read all sections
CONTEXT=$(extract_section "$SPEC_FILE" "Context")
GOAL=$(extract_section "$SPEC_FILE" "Goal")
SCOPE=$(extract_section "$SPEC_FILE" "Scope")
ACCEPTANCE_CRITERIA=$(extract_section "$SPEC_FILE" "Acceptance Criteria")
ARCHITECTURE=$(extract_section "$SPEC_FILE" "Architecture alignment")
SECURITY=$(extract_section "$SPEC_FILE" "Security and compliance")
TEST_STRATEGY=$(extract_section "$SPEC_FILE" "Test strategy")
REPO_CONTEXT=$(cat "$REPO_CONTEXT_FILE")

# Check for blocking questions
if grep -q "^## Blocking questions" "$QUESTIONS_FILE"; then
    BLOCKING_QUESTIONS_EXIST="true"
else
    BLOCKING_QUESTIONS_EXIST="false"
fi

info "Evaluating Definition of Ready..."

# Create prompt file
PROMPT_FILE=$(mktemp)
cat > "$PROMPT_FILE" <<'PROMPTEOF'
You are the Judge Agent (Gatekeeper) for vault67, a multi-agent ticket refinement system.

Your job is to evaluate whether this ticket meets the Definition of Ready (DoR) and can proceed to READY_TO_IMPLEMENT state.

# DEFINITION OF READY CHECKLIST

A ticket can move to READY_TO_IMPLEMENT only when ALL are true:
1. Scope defined: Clear "In scope" and "Out of scope" items listed
2. Gherkin scenarios present and testable: Concrete Given/When/Then scenarios exist
3. Architecture alignment reviewed: Constraints, allowed/forbidden paths captured
4. Security/compliance reviewed: Security constraints captured (or explicitly not applicable)
5. Test strategy defined: Each scenario has a test approach
6. Repo golden commands known: Build and test commands are documented (or explicitly blocked)
7. No blocking questions: All blocking questions have been answered

# INPUTS

## Context
PROMPTEOF

echo "$CONTEXT" >> "$PROMPT_FILE"

cat >> "$PROMPT_FILE" <<'PROMPTEOF'

## Goal
PROMPTEOF

echo "$GOAL" >> "$PROMPT_FILE"

cat >> "$PROMPT_FILE" <<'PROMPTEOF'

## Scope
PROMPTEOF

echo "$SCOPE" >> "$PROMPT_FILE"

cat >> "$PROMPT_FILE" <<'PROMPTEOF'

## Acceptance Criteria
PROMPTEOF

echo "$ACCEPTANCE_CRITERIA" >> "$PROMPT_FILE"

cat >> "$PROMPT_FILE" <<'PROMPTEOF'

## Architecture Alignment
PROMPTEOF

echo "$ARCHITECTURE" >> "$PROMPT_FILE"

cat >> "$PROMPT_FILE" <<'PROMPTEOF'

## Security and Compliance
PROMPTEOF

echo "$SECURITY" >> "$PROMPT_FILE"

cat >> "$PROMPT_FILE" <<'PROMPTEOF'

## Test Strategy
PROMPTEOF

echo "$TEST_STRATEGY" >> "$PROMPT_FILE"

cat >> "$PROMPT_FILE" <<'PROMPTEOF'

## Repository Context
PROMPTEOF

echo "$REPO_CONTEXT" >> "$PROMPT_FILE"

cat >> "$PROMPT_FILE" <<PROMPTEOF

## Blocking Questions Exist
$BLOCKING_QUESTIONS_EXIST

# YOUR TASK

Evaluate each DoR criterion and provide:
1. A status for each criterion: PASS, FAIL, or PARTIAL
2. If FAIL or PARTIAL, explain what's missing
3. Overall verdict: READY_TO_IMPLEMENT or NEEDS_INFO

# EVALUATION RULES

- Be strict but fair: Empty placeholders or "-" don't count as filled
- Testability matters: Gherkin scenarios must be concrete and testable, not abstract
- Context is key: Use the other sections to inform your evaluation
- Blocking questions: Any unanswered blocking question is an automatic FAIL
- Golden commands: If they're missing but the repo context explains why, that can PASS if explicitly documented

# OUTPUT FORMAT

Return ONLY valid JSON with this exact structure:

{
  "dor_evaluation": {
    "scope_defined": {
      "status": "PASS|FAIL|PARTIAL",
      "reason": "Brief explanation if not PASS"
    },
    "gherkin_scenarios": {
      "status": "PASS|FAIL|PARTIAL",
      "reason": "Brief explanation if not PASS"
    },
    "architecture_reviewed": {
      "status": "PASS|FAIL|PARTIAL",
      "reason": "Brief explanation if not PASS"
    },
    "security_reviewed": {
      "status": "PASS|FAIL|PARTIAL",
      "reason": "Brief explanation if not PASS"
    },
    "test_strategy_defined": {
      "status": "PASS|FAIL|PARTIAL",
      "reason": "Brief explanation if not PASS"
    },
    "golden_commands_known": {
      "status": "PASS|FAIL|PARTIAL",
      "reason": "Brief explanation if not PASS"
    },
    "no_blocking_questions": {
      "status": "PASS|FAIL",
      "reason": "Brief explanation if not PASS"
    }
  },
  "verdict": "READY_TO_IMPLEMENT|NEEDS_INFO",
  "summary": "1-2 sentence summary of the evaluation",
  "blocking_issues": ["List of issues that must be resolved before READY_TO_IMPLEMENT"]
}

Return ONLY the JSON, no additional text.
PROMPTEOF

# Try to use Claude Code's claude command if available
if command -v claude &> /dev/null; then
    info "Using Claude CLI to evaluate DoR..."
    RESPONSE=$(claude -p "$PROMPT_FILE" --model sonnet 2>/dev/null || echo "")

    if [ -z "$RESPONSE" ]; then
        error "Claude CLI returned empty response"
    fi
else
    # Fallback: create a marker file for manual processing
    warn "Claude CLI not available"
    warn "Creating prompt file for manual processing: $TICKET_DIR/judge-prompt.txt"
    cp "$PROMPT_FILE" "$TICKET_DIR/judge-prompt.txt"
    rm -f "$PROMPT_FILE"
    error "Please run Claude manually with the prompt file"
fi

rm -f "$PROMPT_FILE"

# Parse JSON response
info "Parsing DoR evaluation..."

# Extract verdict
VERDICT=$(echo "$RESPONSE" | jq -r '.verdict' 2>/dev/null || echo "NEEDS_INFO")
SUMMARY=$(echo "$RESPONSE" | jq -r '.summary' 2>/dev/null || echo "Unable to parse evaluation")

# Extract DoR evaluation
SCOPE_STATUS=$(echo "$RESPONSE" | jq -r '.dor_evaluation.scope_defined.status' 2>/dev/null || echo "FAIL")
GHERKIN_STATUS=$(echo "$RESPONSE" | jq -r '.dor_evaluation.gherkin_scenarios.status' 2>/dev/null || echo "FAIL")
ARCH_STATUS=$(echo "$RESPONSE" | jq -r '.dor_evaluation.architecture_reviewed.status' 2>/dev/null || echo "FAIL")
SECURITY_STATUS=$(echo "$RESPONSE" | jq -r '.dor_evaluation.security_reviewed.status' 2>/dev/null || echo "FAIL")
TEST_STATUS=$(echo "$RESPONSE" | jq -r '.dor_evaluation.test_strategy_defined.status' 2>/dev/null || echo "FAIL")
GOLDEN_STATUS=$(echo "$RESPONSE" | jq -r '.dor_evaluation.golden_commands_known.status' 2>/dev/null || echo "FAIL")
QUESTIONS_STATUS=$(echo "$RESPONSE" | jq -r '.dor_evaluation.no_blocking_questions.status' 2>/dev/null || echo "FAIL")

# Update DoR checklist in spec.md
info "Updating Definition of Ready checklist in spec.md..."

# Create checkbox based on status
checkbox() {
    local status="$1"
    if [ "$status" = "PASS" ]; then
        echo "[x]"
    else
        echo "[ ]"
    fi
}

# Build the updated DoR section
DOR_SECTION=$(cat <<DOREOF
## Definition of Ready
$(checkbox "$SCOPE_STATUS") Scope in/out defined
$(checkbox "$GHERKIN_STATUS") Gherkin scenarios are present and testable
$(checkbox "$ARCH_STATUS") Architecture alignment reviewed and constraints captured
$(checkbox "$SECURITY_STATUS") Security/compliance reviewed and constraints captured
$(checkbox "$TEST_STATUS") Test strategy defined for each scenario
$(checkbox "$GOLDEN_STATUS") Repo golden commands known or explicitly blocked
$(checkbox "$QUESTIONS_STATUS") No blocking questions remain
DOREOF
)

# Update spec.md with DoR checklist
TMP_SPEC=$(mktemp)

awk -v dor="$DOR_SECTION" '
    /^## Definition of Ready/ {
        print dor
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

mv "$TMP_SPEC" "$SPEC_FILE"
success "Updated Definition of Ready checklist"

# Report results
echo ""
info "DoR Evaluation Results:"
echo -e "  Scope defined: ${SCOPE_STATUS}"
echo -e "  Gherkin scenarios: ${GHERKIN_STATUS}"
echo -e "  Architecture reviewed: ${ARCH_STATUS}"
echo -e "  Security reviewed: ${SECURITY_STATUS}"
echo -e "  Test strategy: ${TEST_STATUS}"
echo -e "  Golden commands: ${GOLDEN_STATUS}"
echo -e "  No blocking questions: ${QUESTIONS_STATUS}"
echo ""

if [ "$VERDICT" = "READY_TO_IMPLEMENT" ]; then
    success "VERDICT: READY_TO_IMPLEMENT"
    success "$SUMMARY"
    exit 0
else
    warn "VERDICT: NEEDS_INFO"
    warn "$SUMMARY"

    # Extract and add blocking issues to questions.md
    BLOCKING_ISSUES=$(echo "$RESPONSE" | jq -r '.blocking_issues[]' 2>/dev/null || echo "")

    if [ -n "$BLOCKING_ISSUES" ]; then
        info "Adding blocking issues to questions.md..."

        cat >> "$QUESTIONS_FILE" <<QEOF

## Blocking issues (added by Judge Agent)
QEOF

        echo "$BLOCKING_ISSUES" | while IFS= read -r issue; do
            if [ -n "$issue" ]; then
                echo "- $issue" >> "$QUESTIONS_FILE"
            fi
        done

        success "Added blocking issues to questions.md"
    fi

    exit 1
fi
