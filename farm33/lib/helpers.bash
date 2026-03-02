#!/usr/bin/env bash
# farm33 helper functions — extracted for testability

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

error()   { echo -e "${RED}Error: $*${NC}" >&2; exit 1; }
success() { echo -e "${GREEN}✓ $*${NC}"; }
info()    { echo -e "${BLUE}→ $*${NC}"; }
warn()    { echo -e "${YELLOW}⚠ $*${NC}" >&2; }

log_worker() {
    local worker_id="${WORKER_ID:-main}"
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] [worker-${worker_id}] $*" >&2
}

extract_issue_title() {
    python3 -c "import sys,json; print(json.load(sys.stdin)['title'])"
}

extract_issue_body() {
    python3 -c "import sys,json; print(json.load(sys.stdin)['body'])"
}

extract_issue_labels() {
    python3 -c "import sys,json; print(' '.join([l['name'] for l in json.load(sys.stdin)['labels']]))"
}

# Validate and execute a command safely — rejects shell injection patterns
# Usage: safe_eval_cmd <working_dir> <command_string>
# Returns: exit code of the command, or 1 if rejected
safe_eval_cmd() {
    local wt_dir="$1"
    local cmd="$2"

    # Reject dangerous patterns
    if echo "$cmd" | grep -qE '\$\(|`|;|&&|\|\|'; then
        echo "ERROR: Rejected command with shell metacharacters: $cmd" >&2
        return 1
    fi

    (cd "$wt_dir" && eval "$cmd")
}

# Extract golden build/test commands from promptpack text
# Returns two lines: BUILD_CMD=... and TEST_CMD=...
extract_golden_commands() {
    local promptpack="$1"
    python3 -c "
import sys, re

text = sys.argv[1]
build_cmd = ''
test_cmd = ''

for line in text.split('\n'):
    stripped = line.strip()
    if stripped.startswith('- ') or stripped.startswith('* '):
        stripped = stripped[2:]
    if 'Golden build command:' in stripped:
        build_cmd = stripped.split('Golden build command:')[-1].strip()
        build_cmd = build_cmd.strip('\`')
    elif 'Golden test command:' in stripped:
        test_cmd = stripped.split('Golden test command:')[-1].strip()
        test_cmd = test_cmd.strip('\`')

for section_name, var_name in [('How to build', 'build'), ('How to test', 'test')]:
    match = re.search(rf'### {section_name}.*?\n(.*?)(?=\n###|\n##|\Z)', text, re.DOTALL)
    if match:
        content = match.group(1).strip()
        if content and content != '(see parent issue)':
            if var_name == 'build' and not build_cmd:
                build_cmd = content.strip('\`').strip()
            elif var_name == 'test' and not test_cmd:
                test_cmd = content.strip('\`').strip()

print(f'BUILD_CMD={build_cmd}')
print(f'TEST_CMD={test_cmd}')
" "$promptpack"
}

# Extract git base ref from promptpack text
# Returns branch name (defaults to "main")
extract_base_ref() {
    local promptpack="$1"
    python3 -c "
import sys, re
text = sys.argv[1]

m = re.search(r'Base ref:\s*\x60([^\x60]+)\x60', text)
if m:
    print(m.group(1))
    sys.exit(0)

m = re.search(r'### Base ref\n-\s*(\S+)', text)
if m:
    print(m.group(1))
    sys.exit(0)

print('main')
" "$promptpack"
}

# Parse JSON object from LLM response (strips markdown fences)
# Reads from file path $1, validates key in $2 (optional)
# Returns valid JSON or exits 1
parse_llm_json_object() {
    local input_file="$1"
    local required_key="${2:-}"
    python3 -c '
import json, re, sys

text = open(sys.argv[1]).read()
required_key = sys.argv[2] if len(sys.argv) > 2 else ""

text = re.sub(r"^```\w*\s*\n", "", text)
text = re.sub(r"\n```\s*$", "", text)
text = text.strip()

try:
    obj = json.loads(text)
    if not required_key or required_key in obj:
        print(json.dumps(obj))
        sys.exit(0)
except SystemExit:
    raise
except Exception:
    pass

# Fallback: brace-matching
search_key = required_key if required_key else ""
for m in re.finditer(r"\{", text):
    start = m.start()
    depth = 0
    for i in range(start, len(text)):
        if text[i] == "{": depth += 1
        elif text[i] == "}": depth -= 1
        if depth == 0:
            candidate = text[start:i+1]
            try:
                obj = json.loads(candidate)
                if not search_key or search_key in obj:
                    print(json.dumps(obj))
                    sys.exit(0)
            except SystemExit:
                raise
            except Exception:
                pass
            break

sys.exit(1)
' "$input_file" "$required_key"
}

# Parse JSON array from LLM response (strips markdown fences)
# Reads from file path $1
# Returns valid JSON array or exits 1
parse_llm_json_array() {
    local input_file="$1"
    python3 -c '
import json, re, sys

text = open(sys.argv[1]).read()
text = re.sub(r"^```\w*\s*\n", "", text)
text = re.sub(r"\n```\s*$", "", text)
text = text.strip()

try:
    arr = json.loads(text)
    if isinstance(arr, list):
        print(json.dumps(arr))
        sys.exit(0)
except Exception:
    pass

match = re.search(r"\[[\s\S]*?\]", text)
if match:
    try:
        arr = json.loads(match.group(0))
        print(json.dumps(arr))
        sys.exit(0)
    except Exception:
        pass

sys.exit(1)
' "$input_file"
}

# Temp file tracking for safe cleanup
_FARM33_TEMP_FILES=()

register_temp_file() {
    _FARM33_TEMP_FILES+=("$1")
}

safe_cleanup() {
    local f
    for f in "${_FARM33_TEMP_FILES[@]+"${_FARM33_TEMP_FILES[@]}"}"; do
        if [ -d "$f" ]; then
            rm -rf "$f" 2>/dev/null || true
        elif [ -f "$f" ]; then
            rm -f "$f" 2>/dev/null || true
        fi
    done
}
