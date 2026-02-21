"""Data models for code analysis findings and recommendations."""

from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


class Severity(str, Enum):
    """Severity levels for findings."""

    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"
    INFO = "info"


class FindingType(str, Enum):
    """Types of code issues that can be found."""

    STYLE = "style"
    TYPE_ERROR = "type_error"
    COMPLEXITY = "complexity"
    SECURITY = "security"
    PERFORMANCE = "performance"
    MAINTAINABILITY = "maintainability"
    BUG = "bug"
    CODE_SMELL = "code_smell"


class Priority(str, Enum):
    """Priority levels for recommendations."""

    URGENT = "urgent"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"


class Location(BaseModel):
    """Location of a finding in the codebase."""

    file: str = Field(..., description="Path to the file relative to repo root")
    line: Optional[int] = Field(None, description="Line number where the issue occurs")
    column: Optional[int] = Field(None, description="Column number where the issue occurs")
    end_line: Optional[int] = Field(None, description="End line for multi-line issues")
    function: Optional[str] = Field(None, description="Function or method name if applicable")


class Finding(BaseModel):
    """A code issue or problem found during analysis."""

    type: FindingType = Field(..., description="Type of issue found")
    severity: Severity = Field(..., description="Severity level of the finding")
    location: Location = Field(..., description="Where in the code the issue was found")
    message: str = Field(..., description="Human-readable description of the issue")
    rule_id: Optional[str] = Field(None, description="Tool-specific rule identifier (e.g., ruff rule)")
    fix_available: bool = Field(default=False, description="Whether an automatic fix is available")


class Recommendation(BaseModel):
    """A recommended action to improve the codebase."""

    priority: Priority = Field(..., description="Priority level of the recommendation")
    category: str = Field(..., description="Category of the recommendation")
    action: str = Field(..., description="What should be done")
    rationale: str = Field(..., description="Why this action is recommended")
    impact: str = Field(..., description="Expected impact of implementing this recommendation")
    effort: Optional[str] = Field(None, description="Estimated effort (e.g., 'low', 'medium', 'high')")
    related_findings: list[str] = Field(
        default_factory=list, description="IDs of related findings"
    )


class AnalysisSummary(BaseModel):
    """Summary statistics for the analysis."""

    total_files: int = Field(..., description="Total number of files analyzed")
    python_files: int = Field(..., description="Number of Python files analyzed")
    total_findings: int = Field(..., description="Total number of findings")
    findings_by_severity: dict[Severity, int] = Field(
        default_factory=dict, description="Count of findings by severity level"
    )
    findings_by_type: dict[FindingType, int] = Field(
        default_factory=dict, description="Count of findings by type"
    )
    total_recommendations: int = Field(..., description="Total number of recommendations")


class GitMetrics(BaseModel):
    """Git repository metrics."""

    total_commits: int = Field(..., description="Total number of commits")
    total_contributors: int = Field(..., description="Total number of contributors")
    hot_spots: list[str] = Field(
        default_factory=list, description="Files that change frequently"
    )
    large_files: list[str] = Field(
        default_factory=list, description="Files that are unusually large"
    )
    last_commit_date: Optional[str] = Field(None, description="Date of last commit")


class AnalysisResult(BaseModel):
    """Complete analysis result for a repository."""

    repo_path: str = Field(..., description="Path to the analyzed repository")
    analysis_timestamp: str = Field(..., description="ISO 8601 timestamp of analysis")
    summary: AnalysisSummary = Field(..., description="Summary statistics")
    findings: list[Finding] = Field(default_factory=list, description="All findings")
    recommendations: list[Recommendation] = Field(
        default_factory=list, description="All recommendations"
    )
    git_metrics: Optional[GitMetrics] = Field(None, description="Git repository metrics")

    def to_json(self) -> str:
        """Export as JSON string."""
        return self.model_dump_json(indent=2)
