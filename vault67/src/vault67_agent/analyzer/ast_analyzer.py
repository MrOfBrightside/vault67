"""AST-based code analysis for complexity and patterns."""

import ast
from pathlib import Path
from typing import Optional

from vault67_agent.models.schemas import (
    Finding,
    FindingType,
    Location,
    Severity,
)


class ComplexityVisitor(ast.NodeVisitor):
    """AST visitor to calculate cyclomatic complexity."""

    def __init__(self) -> None:
        self.complexity = 1

    def visit_If(self, node: ast.If) -> None:
        self.complexity += 1
        self.generic_visit(node)

    def visit_For(self, node: ast.For) -> None:
        self.complexity += 1
        self.generic_visit(node)

    def visit_While(self, node: ast.While) -> None:
        self.complexity += 1
        self.generic_visit(node)

    def visit_ExceptHandler(self, node: ast.ExceptHandler) -> None:
        self.complexity += 1
        self.generic_visit(node)

    def visit_With(self, node: ast.With) -> None:
        self.complexity += 1
        self.generic_visit(node)

    def visit_BoolOp(self, node: ast.BoolOp) -> None:
        self.complexity += len(node.values) - 1
        self.generic_visit(node)


class ASTAnalyzer:
    """Analyzes Python code using AST parsing."""

    def __init__(self, complexity_threshold: int = 10) -> None:
        """
        Initialize AST analyzer.

        Args:
            complexity_threshold: Cyclomatic complexity threshold for warnings
        """
        self.complexity_threshold = complexity_threshold

    def analyze_file(self, file_path: Path) -> list[Finding]:
        """
        Analyze a single Python file.

        Args:
            file_path: Path to the Python file

        Returns:
            List of findings from the analysis
        """
        findings: list[Finding] = []

        try:
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()

            tree = ast.parse(content, filename=str(file_path))
            findings.extend(self._analyze_tree(tree, file_path))

        except SyntaxError as e:
            findings.append(
                Finding(
                    type=FindingType.BUG,
                    severity=Severity.CRITICAL,
                    location=Location(
                        file=str(file_path),
                        line=e.lineno or 0,
                        column=e.offset or 0,
                    ),
                    message=f"Syntax error: {e.msg}",
                    rule_id="AST001",
                )
            )
        except Exception as e:
            # If we can't parse the file, log it but don't fail
            findings.append(
                Finding(
                    type=FindingType.BUG,
                    severity=Severity.HIGH,
                    location=Location(file=str(file_path)),
                    message=f"Failed to analyze file: {str(e)}",
                    rule_id="AST000",
                )
            )

        return findings

    def _analyze_tree(self, tree: ast.AST, file_path: Path) -> list[Finding]:
        """Analyze AST tree for issues."""
        findings: list[Finding] = []

        for node in ast.walk(tree):
            if isinstance(node, ast.FunctionDef):
                findings.extend(self._analyze_function(node, file_path))
            elif isinstance(node, ast.ClassDef):
                findings.extend(self._analyze_class(node, file_path))

        return findings

    def _analyze_function(self, node: ast.FunctionDef, file_path: Path) -> list[Finding]:
        """Analyze a function definition."""
        findings: list[Finding] = []

        # Calculate complexity
        visitor = ComplexityVisitor()
        visitor.visit(node)
        complexity = visitor.complexity

        if complexity > self.complexity_threshold:
            severity = (
                Severity.HIGH
                if complexity > self.complexity_threshold * 2
                else Severity.MEDIUM
            )
            findings.append(
                Finding(
                    type=FindingType.COMPLEXITY,
                    severity=severity,
                    location=Location(
                        file=str(file_path),
                        line=node.lineno,
                        column=node.col_offset,
                        function=node.name,
                    ),
                    message=f"Function '{node.name}' has high cyclomatic complexity ({complexity})",
                    rule_id="AST100",
                )
            )

        # Check for too many arguments
        arg_count = len(node.args.args)
        if arg_count > 7:
            findings.append(
                Finding(
                    type=FindingType.CODE_SMELL,
                    severity=Severity.MEDIUM,
                    location=Location(
                        file=str(file_path),
                        line=node.lineno,
                        column=node.col_offset,
                        function=node.name,
                    ),
                    message=f"Function '{node.name}' has too many arguments ({arg_count})",
                    rule_id="AST101",
                )
            )

        # Check function length
        if hasattr(node, "end_lineno") and node.end_lineno:
            func_length = node.end_lineno - node.lineno
            if func_length > 50:
                findings.append(
                    Finding(
                        type=FindingType.MAINTAINABILITY,
                        severity=Severity.LOW,
                        location=Location(
                            file=str(file_path),
                            line=node.lineno,
                            column=node.col_offset,
                            end_line=node.end_lineno,
                            function=node.name,
                        ),
                        message=f"Function '{node.name}' is very long ({func_length} lines)",
                        rule_id="AST102",
                    )
                )

        return findings

    def _analyze_class(self, node: ast.ClassDef, file_path: Path) -> list[Finding]:
        """Analyze a class definition."""
        findings: list[Finding] = []

        # Count methods
        methods = [n for n in node.body if isinstance(n, ast.FunctionDef)]
        if len(methods) > 20:
            findings.append(
                Finding(
                    type=FindingType.CODE_SMELL,
                    severity=Severity.MEDIUM,
                    location=Location(
                        file=str(file_path),
                        line=node.lineno,
                        column=node.col_offset,
                    ),
                    message=f"Class '{node.name}' has too many methods ({len(methods)}). "
                    "Consider splitting it.",
                    rule_id="AST200",
                )
            )

        return findings


def analyze_directory(directory: Path, complexity_threshold: int = 10) -> list[Finding]:
    """
    Analyze all Python files in a directory.

    Args:
        directory: Root directory to analyze
        complexity_threshold: Cyclomatic complexity threshold

    Returns:
        List of all findings
    """
    analyzer = ASTAnalyzer(complexity_threshold=complexity_threshold)
    findings: list[Finding] = []

    for py_file in directory.rglob("*.py"):
        # Skip hidden directories and common non-source directories
        if any(part.startswith(".") for part in py_file.parts):
            continue
        if any(
            part in {"__pycache__", "venv", "env", ".venv", "node_modules"}
            for part in py_file.parts
        ):
            continue

        findings.extend(analyzer.analyze_file(py_file))

    return findings
