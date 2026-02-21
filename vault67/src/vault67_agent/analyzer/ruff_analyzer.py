"""Ruff linter integration for code quality checks."""

import json
import subprocess
from pathlib import Path
from typing import Any

from vault67_agent.models.schemas import (
    Finding,
    FindingType,
    Location,
    Severity,
)


class RuffAnalyzer:
    """Analyzes code using the ruff linter."""

    # Mapping of ruff severity/category to our severity levels
    SEVERITY_MAP = {
        "E": Severity.MEDIUM,  # pycodestyle errors
        "F": Severity.HIGH,  # pyflakes
        "W": Severity.LOW,  # pycodestyle warnings
        "I": Severity.LOW,  # isort
        "N": Severity.LOW,  # pep8-naming
        "UP": Severity.MEDIUM,  # pyupgrade
        "S": Severity.HIGH,  # flake8-bandit (security)
        "B": Severity.MEDIUM,  # flake8-bugbear
        "A": Severity.MEDIUM,  # flake8-builtins
        "C4": Severity.LOW,  # flake8-comprehensions
        "T20": Severity.LOW,  # flake8-print
    }

    def analyze_directory(self, directory: Path) -> list[Finding]:
        """
        Run ruff on a directory and parse results.

        Args:
            directory: Path to the directory to analyze

        Returns:
            List of findings from ruff
        """
        findings: list[Finding] = []

        try:
            # Run ruff with JSON output
            result = subprocess.run(
                ["ruff", "check", str(directory), "--output-format=json"],
                capture_output=True,
                text=True,
                timeout=300,  # 5 minute timeout
            )

            # ruff returns non-zero when it finds issues, which is expected
            if result.stdout:
                findings.extend(self._parse_ruff_output(result.stdout))

        except subprocess.TimeoutExpired:
            findings.append(
                Finding(
                    type=FindingType.BUG,
                    severity=Severity.HIGH,
                    location=Location(file=str(directory)),
                    message="Ruff analysis timed out after 5 minutes",
                    rule_id="RUFF000",
                )
            )
        except FileNotFoundError:
            findings.append(
                Finding(
                    type=FindingType.BUG,
                    severity=Severity.CRITICAL,
                    location=Location(file=str(directory)),
                    message="Ruff not found. Please install: pip install ruff",
                    rule_id="RUFF001",
                )
            )
        except Exception as e:
            findings.append(
                Finding(
                    type=FindingType.BUG,
                    severity=Severity.HIGH,
                    location=Location(file=str(directory)),
                    message=f"Failed to run ruff: {str(e)}",
                    rule_id="RUFF002",
                )
            )

        return findings

    def _parse_ruff_output(self, output: str) -> list[Finding]:
        """Parse ruff JSON output into Finding objects."""
        findings: list[Finding] = []

        try:
            issues = json.loads(output)

            for issue in issues:
                findings.append(self._convert_ruff_issue(issue))

        except json.JSONDecodeError as e:
            # If we can't parse the JSON, create a finding about it
            findings.append(
                Finding(
                    type=FindingType.BUG,
                    severity=Severity.MEDIUM,
                    location=Location(file="ruff_output"),
                    message=f"Failed to parse ruff output: {str(e)}",
                    rule_id="RUFF003",
                )
            )

        return findings

    def _convert_ruff_issue(self, issue: dict[str, Any]) -> Finding:
        """Convert a ruff issue to a Finding object."""
        # Extract location information
        location_data = issue.get("location", {})
        end_location = issue.get("end_location", {})

        location = Location(
            file=issue.get("filename", "unknown"),
            line=location_data.get("row"),
            column=location_data.get("column"),
            end_line=end_location.get("row"),
        )

        # Determine severity based on rule code prefix
        rule_code = issue.get("code", "")
        severity = self._get_severity_for_rule(rule_code)

        # Determine finding type
        finding_type = self._get_finding_type(rule_code)

        # Check if fix is available
        fix_available = issue.get("fix") is not None

        return Finding(
            type=finding_type,
            severity=severity,
            location=location,
            message=issue.get("message", "No message provided"),
            rule_id=rule_code,
            fix_available=fix_available,
        )

    def _get_severity_for_rule(self, rule_code: str) -> Severity:
        """Map a ruff rule code to a severity level."""
        # Get the first letter(s) of the rule code
        prefix = ""
        for char in rule_code:
            if char.isalpha():
                prefix += char
            else:
                break

        return self.SEVERITY_MAP.get(prefix, Severity.MEDIUM)

    def _get_finding_type(self, rule_code: str) -> FindingType:
        """Map a ruff rule code to a finding type."""
        # Security rules (S prefix from bandit)
        if rule_code.startswith("S"):
            return FindingType.SECURITY

        # Error codes (F from pyflakes, E from pycodestyle)
        if rule_code.startswith("F") or rule_code.startswith("E9"):
            return FindingType.BUG

        # Style codes
        if rule_code.startswith(("E", "W", "I", "N")):
            return FindingType.STYLE

        # Performance-related
        if rule_code.startswith("PERF"):
            return FindingType.PERFORMANCE

        # Default to code smell
        return FindingType.CODE_SMELL
