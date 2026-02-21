# Lead Developer Agent

Automated code analysis tool for Python repositories. The Lead Developer Agent analyzes your codebase using multiple tools (AST analysis, Ruff, Mypy) and provides actionable recommendations.

## Features

- **AST Analysis**: Detects code complexity, long functions, and code smells
- **Ruff Integration**: Comprehensive linting for code quality and style
- **Mypy Integration**: Static type checking for type safety
- **Git Analysis**: Identifies code hot spots and large files
- **JSON Output**: Structured findings and recommendations

## Installation

```bash
# Install from source
cd vault67
pip install -e .

# Or install with development dependencies
pip install -e ".[dev]"
```

## Usage

### Basic Analysis

```bash
lead-dev-agent analyze /path/to/repo
```

### Save Results to File

```bash
lead-dev-agent analyze /path/to/repo --output results.json
```

### Skip Specific Analyzers

```bash
# Skip git analysis
lead-dev-agent analyze /path/to/repo --skip-git

# Skip mypy (type checking)
lead-dev-agent analyze /path/to/repo --skip-mypy

# Skip ruff (linting)
lead-dev-agent analyze /path/to/repo --skip-ruff

# Skip AST analysis
lead-dev-agent analyze /path/to/repo --skip-ast
```

### Adjust Complexity Threshold

```bash
# Set complexity threshold to 15 (default is 10)
lead-dev-agent analyze /path/to/repo --complexity-threshold 15
```

## Output Schema

The tool outputs JSON with the following structure:

```json
{
  "repo_path": "/path/to/repo",
  "analysis_timestamp": "2026-02-21T17:00:00Z",
  "summary": {
    "total_files": 50,
    "python_files": 45,
    "total_findings": 120,
    "findings_by_severity": {
      "critical": 2,
      "high": 15,
      "medium": 45,
      "low": 48,
      "info": 10
    },
    "findings_by_type": {
      "style": 30,
      "type_error": 20,
      "complexity": 15,
      "code_smell": 25,
      "bug": 10
    },
    "total_recommendations": 8
  },
  "findings": [
    {
      "type": "complexity",
      "severity": "high",
      "location": {
        "file": "src/main.py",
        "line": 42,
        "column": 0,
        "function": "process_data"
      },
      "message": "Function 'process_data' has high cyclomatic complexity (25)",
      "rule_id": "AST100",
      "fix_available": false
    }
  ],
  "recommendations": [
    {
      "priority": "urgent",
      "category": "Critical Issues",
      "action": "Fix 2 critical issue(s) immediately",
      "rationale": "Critical issues can cause runtime failures or security vulnerabilities",
      "impact": "Prevents potential system failures and security breaches",
      "effort": "medium"
    }
  ],
  "git_metrics": {
    "total_commits": 542,
    "total_contributors": 8,
    "hot_spots": ["src/main.py", "src/utils.py"],
    "large_files": ["src/legacy.py (823 lines)"],
    "last_commit_date": "2026-02-21T16:30:00Z"
  }
}
```

## Finding Types

- **style**: Code style and formatting issues
- **type_error**: Type checking errors (from mypy)
- **complexity**: High cyclomatic complexity
- **security**: Security vulnerabilities
- **performance**: Performance issues
- **maintainability**: Maintainability concerns
- **bug**: Potential bugs
- **code_smell**: Code smells and anti-patterns

## Severity Levels

- **critical**: Must be fixed immediately (syntax errors, critical bugs)
- **high**: Should be fixed soon (bugs, important type errors)
- **medium**: Should be addressed (style violations, moderate complexity)
- **low**: Nice to fix (minor style issues, suggestions)
- **info**: Informational only

## Requirements

- Python 3.10 or higher
- Git (for git analysis)
- Ruff (for linting)
- Mypy (for type checking)

## Development

### Running Tests

```bash
pytest
```

### Type Checking

```bash
mypy src/vault67_agent
```

### Linting

```bash
ruff check src/vault67_agent
```

## License

MIT

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.
