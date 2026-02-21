"""Tests for AST analyzer."""

import tempfile
from pathlib import Path

from vault67_agent.analyzer.ast_analyzer import ASTAnalyzer, analyze_directory
from vault67_agent.models.schemas import FindingType, Severity


def test_analyze_simple_function() -> None:
    """Test analyzing a simple function."""
    code = """
def simple_function(x):
    return x + 1
"""

    with tempfile.NamedTemporaryFile(mode="w", suffix=".py", delete=False) as f:
        f.write(code)
        f.flush()
        temp_path = Path(f.name)

    try:
        analyzer = ASTAnalyzer(complexity_threshold=10)
        findings = analyzer.analyze_file(temp_path)

        # Simple function should have no findings
        assert len(findings) == 0
    finally:
        temp_path.unlink()


def test_analyze_complex_function() -> None:
    """Test analyzing a complex function."""
    code = """
def complex_function(x):
    if x > 0:
        if x > 10:
            if x > 20:
                if x > 30:
                    if x > 40:
                        if x > 50:
                            return "very high"
                        return "high"
                    return "medium-high"
                return "medium"
            return "low-medium"
        return "low"
    return "zero or negative"
"""

    with tempfile.NamedTemporaryFile(mode="w", suffix=".py", delete=False) as f:
        f.write(code)
        f.flush()
        temp_path = Path(f.name)

    try:
        analyzer = ASTAnalyzer(complexity_threshold=5)
        findings = analyzer.analyze_file(temp_path)

        # Should detect high complexity
        complexity_findings = [f for f in findings if f.type == FindingType.COMPLEXITY]
        assert len(complexity_findings) > 0
        assert complexity_findings[0].location.function == "complex_function"
    finally:
        temp_path.unlink()


def test_analyze_function_with_many_args() -> None:
    """Test analyzing a function with too many arguments."""
    code = """
def many_args(a, b, c, d, e, f, g, h, i):
    return a + b + c + d + e + f + g + h + i
"""

    with tempfile.NamedTemporaryFile(mode="w", suffix=".py", delete=False) as f:
        f.write(code)
        f.flush()
        temp_path = Path(f.name)

    try:
        analyzer = ASTAnalyzer()
        findings = analyzer.analyze_file(temp_path)

        # Should detect too many arguments
        code_smell_findings = [f for f in findings if f.type == FindingType.CODE_SMELL]
        assert len(code_smell_findings) > 0
        assert "too many arguments" in code_smell_findings[0].message.lower()
    finally:
        temp_path.unlink()


def test_analyze_syntax_error() -> None:
    """Test analyzing a file with syntax errors."""
    code = """
def broken_function(
    return "incomplete"
"""

    with tempfile.NamedTemporaryFile(mode="w", suffix=".py", delete=False) as f:
        f.write(code)
        f.flush()
        temp_path = Path(f.name)

    try:
        analyzer = ASTAnalyzer()
        findings = analyzer.analyze_file(temp_path)

        # Should detect syntax error
        assert len(findings) > 0
        assert findings[0].severity == Severity.CRITICAL
        assert findings[0].type == FindingType.BUG
    finally:
        temp_path.unlink()


def test_analyze_directory() -> None:
    """Test analyzing a directory of Python files."""
    with tempfile.TemporaryDirectory() as tmpdir:
        temp_path = Path(tmpdir)

        # Create a simple Python file
        (temp_path / "test.py").write_text("def simple(): pass")

        # Create a complex Python file
        (temp_path / "complex.py").write_text("""
def complex_func(x):
    if x > 0:
        if x > 10:
            if x > 20:
                return "high"
            return "medium"
        return "low"
    return "negative"
""")

        findings = analyze_directory(temp_path, complexity_threshold=5)

        # Should find at least the complexity issue
        assert len(findings) > 0
