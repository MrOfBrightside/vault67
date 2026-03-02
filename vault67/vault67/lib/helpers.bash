#!/usr/bin/env bash
# vault67 helper functions — extracted for testability

# Source shared helpers (colors, temp file tracking, cleanup)
_HELPERS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../../lib/common.bash
source "${_HELPERS_DIR}/../../../lib/common.bash" 2>/dev/null \
    || source "${_HELPERS_DIR}/../../lib/common.bash" 2>/dev/null \
    || {
    # Fallback: define locally if common.bash not found (e.g., in Docker)
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
    BLUE='\033[0;34m'; NC='\033[0m'
    _COMMON_TEMP_FILES=()
    register_temp_file() { _COMMON_TEMP_FILES+=("$1"); }
    safe_cleanup() {
        local f; for f in "${_COMMON_TEMP_FILES[@]+"${_COMMON_TEMP_FILES[@]}"}"; do
            [ -d "$f" ] && rm -rf "$f" 2>/dev/null || rm -f "$f" 2>/dev/null || true
        done
    }
}

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

# Extract issue number from API response
extract_issue_number() {
    python3 -c "import sys, json; print(json.load(sys.stdin)['number'])"
}

# Extract issue body from API response
extract_issue_body() {
    python3 -c "import sys, json; print(json.load(sys.stdin)['body'])"
}

# Extract issue labels from API response (returns space-separated list)
extract_issue_labels() {
    python3 -c "import sys, json; print(' '.join([label['name'] for label in json.load(sys.stdin)['labels']]))"
}

# Detect placeholder/generic Gherkin content
# Returns 0 if text contains placeholder patterns, 1 if substantive
is_placeholder_gherkin() {
    local text="$1"
    echo "$text" | grep -qiE \
        "works as expected|works as specified|the feature is used|the system is configured|expected behavior occurs|feature name|scenario name|TODO|TBD|to be determined|to be defined|needs clarification|prerequisites are defined|actions are specified|expected outcomes are documented|placeholder|the system works correctly|it should work|the result is correct"
}

# Extract ticket state from YAML frontmatter
# Args: ticket_file
get_ticket_state() {
    local ticket_file="$1"
    [ ! -f "$ticket_file" ] && error "Ticket file not found: $ticket_file"
    sed -n '/^---$/,/^---$/p' "$ticket_file" | grep '^state:' | awk '{print $2}'
}

# Replace a markdown section in a file
# Args: file, header (e.g. "## Context"), new_content
_replace_spec_section() {
    local file="$1"
    local header="$2"
    local content="$3"
    local temp_content
    temp_content=$(mktemp)
    register_temp_file "$temp_content"
    printf '%s\n%s\n' "$header" "$content" > "$temp_content"
    local escaped_header
    escaped_header=$(echo "$header" | sed 's/[[\.*^$()+?{|]/\\&/g')
    awk -v header_re="^${escaped_header}" -v replacement="$temp_content" '
        $0 ~ header_re {
            system("cat " replacement)
            in_section = 1
            next
        }
        /^## / && in_section {
            in_section = 0
        }
        !in_section { print }
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    rm -f "$temp_content"
}

# Extract features from text description
# Returns one feature per line
_extract_features() {
    local text="$1"
    python3 -c "
import sys, re

text = sys.argv[1]
features = []

# Try: 'Feature N: ...' pattern
if re.search(r'Feature\s*\d+[:.]\s*', text, re.IGNORECASE):
    parts = re.split(r'Feature\s*\d+[:.]\s*', text, flags=re.IGNORECASE)
    for p in parts:
        p = p.strip().rstrip('.')
        if p:
            features.append(p)
# Try: numbered list '1. ...' or '1) ...'
elif re.search(r'^\s*\d+[.)]\s+', text, re.MULTILINE):
    num_matches = re.findall(r'^\s*\d+[.)]\s*(.+)', text, re.MULTILINE)
    for f in num_matches:
        features.append(f.strip())
# Try: bullet points '- ...' or '* ...'
elif re.search(r'^\s*[-*]\s+', text, re.MULTILINE):
    bullet_matches = re.findall(r'^\s*[-*]\s+(.+)', text, re.MULTILINE)
    for f in bullet_matches:
        features.append(f.strip())
# Try: sentence splitting on periods
else:
    sentences = [s.strip() for s in text.split('.') if len(s.strip()) > 10]
    if len(sentences) > 1:
        for s in sentences:
            features.append(s.strip())
    else:
        features.append(text.strip())

for f in features:
    print(f)
" "$text"
}

# Detect dependencies between features using keyword analysis
# Args: feature_text_1 feature_text_2 ...
# Output: lines of "FROM_INDEX DEPENDS_ON_INDEX" (0-based)
_detect_feature_dependencies() {
    local -a texts=("$@")
    python3 -c "
import sys, re

texts = sys.argv[1:]
n = len(texts)
if n < 2:
    sys.exit(0)

deps = []

dep_keywords = re.compile(r'\b(after|requires|depends on|once .+ is done|builds on|using|based on|extends|on top of)\b', re.IGNORECASE)

for i in range(n):
    text_i = texts[i].lower()

    if dep_keywords.search(text_i):
        for j in range(i):
            stop_words = {'with', 'that', 'this', 'from', 'will', 'have', 'been', 'should', 'could', 'would', 'into', 'each', 'more', 'also', 'than', 'when', 'then', 'some', 'only'}
            words_j = set(w for w in re.findall(r'[a-z]{4,}', texts[j].lower()) if w not in stop_words)
            words_i = set(w for w in re.findall(r'[a-z]{4,}', text_i) if w not in stop_words)
            overlap = words_j & words_i
            if len(overlap) >= 1:
                deps.append((i, j))
                break

    if i > 0 and (i, i-1) not in deps:
        stop_words = {'with', 'that', 'this', 'from', 'will', 'have', 'been', 'should', 'could', 'would', 'into', 'each', 'more', 'also', 'than', 'when', 'then', 'some', 'only'}
        words_prev = set(w for w in re.findall(r'[a-z]{4,}', texts[i-1].lower()) if w not in stop_words)
        words_curr = set(w for w in re.findall(r'[a-z]{4,}', text_i) if w not in stop_words)
        overlap = words_prev & words_curr
        if len(overlap) >= 2:
            deps.append((i, i-1))

seen = set()
for d in deps:
    if d not in seen:
        seen.add(d)
        print(f'{d[0]} {d[1]}')
" "${texts[@]}"
}

# Clean Gherkin from LLM response (strip markdown fences, extract Feature block)
# Reads from stdin, writes clean Gherkin to stdout
clean_gherkin_response() {
    python3 -c "
import sys, re

text = sys.stdin.read()

# Strip markdown fences if present
fenced = re.search(r'\`\`\`(?:gherkin)?\s*\n(.*?)\`\`\`', text, re.DOTALL)
if fenced:
    text = fenced.group(1)

# Find the Feature: block
lines = text.split('\n')
output = []
in_feature = False
for line in lines:
    stripped = line.strip()
    if stripped.startswith('Feature:'):
        in_feature = True
    if in_feature:
        output.append(line)

if output:
    while output and not output[-1].strip():
        output.pop()
    print('\n'.join(output))
else:
    for line in lines:
        s = line.strip()
        if s and any(s.startswith(kw) for kw in ['Feature:', 'Scenario:', 'Given ', 'When ', 'Then ', 'And ', 'But ']):
            print(line)
" 2>/dev/null
}
