"""Mypy type checker integration for static type analysis."""

import json
import re
import subprocess
from pathlib import Path
from typing import Any

from vault67_agent.models.schemas import (
    Finding,
    FindingType,
    Location,
    Severity,
)


class MypyAnalyzer:
    """Analyzes code using the mypy type checker."""

    # Mapping of mypy error codes to severity
    SEVERITY_MAP: dict[str, Severity] = {
        "syntax": Severity.CRITICAL,
        "attr-defined": Severity.HIGH,
        "name-defined": Severity.HIGH,
        "call-arg": Severity.HIGH,
        "arg-type": Severity.MEDIUM,
        "return-value": Severity.MEDIUM,
        "assignment": Severity.MEDIUM,
        "type-arg": Severity.MEDIUM,
        "no-untyped-def": Severity.LOW,
        "no-any-return": Severity.LOW,
        "unused-ignore": Severity.INFO,
    }

    def analyze_directory(self, directory: Path) -> list[Finding]:
        """
        Run mypy on a directory and parse results.

        Args:
            directory: Path to the directory to analyze

        Returns:
            List of findings from mypy
        """
        findings: list[Finding] = []

        try:
            # Run mypy with JSON output
            # Use --show-column-numbers and --show-error-codes for better output
            result = subprocess.run(
                [
                    "mypy",
                    str(directory),
                    "--show-column-numbers",
                    "--show-error-codes",
                    "--no-error-summary",
                    "--no-pretty",
                ],
                capture_output=True,
                text=True,
                timeout=600,  # 10 minute timeout for large codebases
            )

            # mypy returns non-zero when it finds issues, which is expected
            if result.stdout:
                findings.extend(self._parse_mypy_output(result.stdout))

        except subprocess.TimeoutExpired:
            findings.append(
                Finding(
                    type=FindingType.BUG,
                    severity=Severity.HIGH,
                    location=Location(file=str(directory)),
                    message="Mypy analysis timed out after 10 minutes",
                    rule_id="MYPY000",
                )
            )
        except FileNotFoundError:
            findings.append(
                Finding(
                    type=FindingType.BUG,
                    severity=Severity.MEDIUM,
                    location=Location(file=str(directory)),
                    message="Mypy not found. Install with: pip install mypy",
                    rule_id="MYPY001",
                )
            )
        except Exception as e:
            findings.append(
                Finding(
                    type=FindingType.BUG,
                    severity=Severity.HIGH,
                    location=Location(file=str(directory)),
                    message=f"Failed to run mypy: {str(e)}",
                    rule_id="MYPY002",
                )
            )

        return findings

    def _parse_mypy_output(self, output: str) -> list[Finding]:
        """Parse mypy text output into Finding objects."""
        findings: list[Finding] = []

        # Mypy output format: file.py:line:col: error: message [error-code]
        # Example: src/main.py:10:5: error: Name 'foo' is not defined [name-defined]
        pattern = re.compile(
            r"^(?P<file>[^:]+):(?P<line>\d+):(?P<col>\d+): "
            r"(?P<level>\w+): (?P<message>.+?)(?:\s+\[(?P<code>[\w-]+)\])?$",
            re.MULTILINE,
        )

        for match in pattern.finditer(output):
            findings.append(self._convert_mypy_match(match.groupdict()))

        return findings

    def _convert_mypy_match(self, match_dict: dict[str, str]) -> Finding:
        """Convert a mypy regex match to a Finding object."""
        file_path = match_dict["file"]
        line = int(match_dict["line"])
        column = int(match_dict["col"])
        level = match_dict["level"]
        message = match_dict["message"]
        error_code = match_dict.get("code", "")

        # Determine severity
        if level == "error":
            severity = self._get_severity_for_code(error_code)
        elif level == "warning":
            severity = Severity.LOW
        elif level == "note":
            severity = Severity.INFO
        else:
            severity = Severity.MEDIUM

        location = Location(
            file=file_path,
            line=line,
            column=column,
        )

        return Finding(
            type=FindingType.TYPE_ERROR,
            severity=severity,
            location=location,
            message=message,
            rule_id=f"mypy:{error_code}" if error_code else "mypy",
            fix_available=False,
        )

    def _get_severity_for_code(self, error_code: str) -> Severity:
        """Map a mypy error code to a severity level."""
        return self.SEVERITY_MAP.get(error_code, Severity.MEDIUM)
