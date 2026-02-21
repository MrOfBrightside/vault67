"""Tests for data models."""

from vault67_agent.models.schemas import (
    AnalysisResult,
    AnalysisSummary,
    Finding,
    FindingType,
    Location,
    Recommendation,
    Priority,
    Severity,
)


def test_location_creation() -> None:
    """Test Location model creation."""
    location = Location(file="test.py", line=10, column=5)
    assert location.file == "test.py"
    assert location.line == 10
    assert location.column == 5
    assert location.function is None


def test_finding_creation() -> None:
    """Test Finding model creation."""
    location = Location(file="test.py", line=10)
    finding = Finding(
        type=FindingType.COMPLEXITY,
        severity=Severity.HIGH,
        location=location,
        message="High complexity detected",
    )
    assert finding.type == FindingType.COMPLEXITY
    assert finding.severity == Severity.HIGH
    assert finding.message == "High complexity detected"
    assert finding.fix_available is False


def test_recommendation_creation() -> None:
    """Test Recommendation model creation."""
    rec = Recommendation(
        priority=Priority.HIGH,
        category="Test",
        action="Do something",
        rationale="Because reasons",
        impact="Positive impact",
    )
    assert rec.priority == Priority.HIGH
    assert rec.category == "Test"
    assert rec.effort is None


def test_analysis_result_creation() -> None:
    """Test AnalysisResult model creation."""
    summary = AnalysisSummary(
        total_files=10,
        python_files=8,
        total_findings=5,
        total_recommendations=2,
    )

    result = AnalysisResult(
        repo_path="/test/repo",
        analysis_timestamp="2026-02-21T10:00:00Z",
        summary=summary,
    )

    assert result.repo_path == "/test/repo"
    assert result.summary.total_files == 10
    assert len(result.findings) == 0
    assert len(result.recommendations) == 0


def test_analysis_result_to_json() -> None:
    """Test AnalysisResult JSON serialization."""
    summary = AnalysisSummary(
        total_files=1,
        python_files=1,
        total_findings=0,
        total_recommendations=0,
    )

    result = AnalysisResult(
        repo_path="/test",
        analysis_timestamp="2026-02-21T10:00:00Z",
        summary=summary,
    )

    json_str = result.to_json()
    assert "repo_path" in json_str
    assert "/test" in json_str
    assert "summary" in json_str
