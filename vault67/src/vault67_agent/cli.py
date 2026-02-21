"""Command-line interface for the Lead Developer Agent."""

import sys
from collections import Counter
from datetime import datetime
from pathlib import Path

import click

from vault67_agent.analyzer.ast_analyzer import analyze_directory as ast_analyze
from vault67_agent.analyzer.mypy_analyzer import MypyAnalyzer
from vault67_agent.analyzer.ruff_analyzer import RuffAnalyzer
from vault67_agent.git.repo_analyzer import analyze_git_repo
from vault67_agent.models.schemas import (
    AnalysisResult,
    AnalysisSummary,
    FindingType,
    Priority,
    Recommendation,
    Severity,
)


@click.group()
def main() -> None:
    """Lead Developer Agent - Automated code analysis and recommendations."""
    pass


@main.command()
@click.argument("repo_path", type=click.Path(exists=True, path_type=Path))
@click.option(
    "--output",
    "-o",
    type=click.Path(path_type=Path),
    help="Output file for JSON results (default: stdout)",
)
@click.option(
    "--complexity-threshold",
    type=int,
    default=10,
    help="Cyclomatic complexity threshold for warnings (default: 10)",
)
@click.option(
    "--skip-git",
    is_flag=True,
    help="Skip git repository analysis",
)
@click.option(
    "--skip-ruff",
    is_flag=True,
    help="Skip ruff linter analysis",
)
@click.option(
    "--skip-mypy",
    is_flag=True,
    help="Skip mypy type checker analysis",
)
@click.option(
    "--skip-ast",
    is_flag=True,
    help="Skip AST complexity analysis",
)
def analyze(
    repo_path: Path,
    output: Path | None,
    complexity_threshold: int,
    skip_git: bool,
    skip_ruff: bool,
    skip_mypy: bool,
    skip_ast: bool,
) -> None:
    """
    Analyze a Python repository for code quality issues and provide recommendations.

    REPO_PATH: Path to the repository to analyze
    """
    click.echo(f"🔍 Analyzing repository: {repo_path}")

    # Collect all findings
    all_findings = []

    # Run AST analysis
    if not skip_ast:
        click.echo("📊 Running AST complexity analysis...")
        try:
            ast_findings = ast_analyze(repo_path, complexity_threshold=complexity_threshold)
            all_findings.extend(ast_findings)
            click.echo(f"  Found {len(ast_findings)} issues via AST analysis")
        except Exception as e:
            click.echo(f"  ⚠️  AST analysis failed: {str(e)}", err=True)

    # Run Ruff analysis
    if not skip_ruff:
        click.echo("🔧 Running Ruff linter...")
        try:
            ruff_analyzer = RuffAnalyzer()
            ruff_findings = ruff_analyzer.analyze_directory(repo_path)
            all_findings.extend(ruff_findings)
            click.echo(f"  Found {len(ruff_findings)} issues via Ruff")
        except Exception as e:
            click.echo(f"  ⚠️  Ruff analysis failed: {str(e)}", err=True)

    # Run Mypy analysis
    if not skip_mypy:
        click.echo("🔍 Running Mypy type checker...")
        try:
            mypy_analyzer = MypyAnalyzer()
            mypy_findings = mypy_analyzer.analyze_directory(repo_path)
            all_findings.extend(mypy_findings)
            click.echo(f"  Found {len(mypy_findings)} issues via Mypy")
        except Exception as e:
            click.echo(f"  ⚠️  Mypy analysis failed: {str(e)}", err=True)

    # Analyze git repository
    git_metrics = None
    if not skip_git:
        click.echo("📈 Analyzing git repository...")
        try:
            git_metrics = analyze_git_repo(repo_path)
            if git_metrics:
                click.echo(f"  Repository has {git_metrics.total_commits} commits")
            else:
                click.echo("  Not a git repository or GitPython not available")
        except Exception as e:
            click.echo(f"  ⚠️  Git analysis failed: {str(e)}", err=True)

    # Count Python files
    python_files = list(repo_path.rglob("*.py"))
    python_files = [
        f
        for f in python_files
        if not any(
            part.startswith(".")
            or part in {"__pycache__", "venv", "env", ".venv", "node_modules"}
            for part in f.parts
        )
    ]

    # Generate summary
    summary = _generate_summary(all_findings, len(python_files))

    # Generate recommendations
    recommendations = _generate_recommendations(all_findings, git_metrics)

    # Create result object
    result = AnalysisResult(
        repo_path=str(repo_path.absolute()),
        analysis_timestamp=datetime.utcnow().isoformat() + "Z",
        summary=summary,
        findings=all_findings,
        recommendations=recommendations,
        git_metrics=git_metrics,
    )

    # Output results
    json_output = result.to_json()

    if output:
        output.write_text(json_output)
        click.echo(f"\n✅ Analysis complete! Results written to: {output}")
    else:
        click.echo("\n" + "=" * 80)
        click.echo(json_output)

    # Exit with error code if critical issues found
    critical_count = sum(1 for f in all_findings if f.severity == Severity.CRITICAL)
    if critical_count > 0:
        click.echo(f"\n❌ Found {critical_count} critical issues", err=True)
        sys.exit(1)


def _generate_summary(findings: list, python_files_count: int) -> AnalysisSummary:
    """Generate analysis summary statistics."""
    # Count findings by severity
    severity_counts: Counter[Severity] = Counter()
    for finding in findings:
        severity_counts[finding.severity] += 1

    # Count findings by type
    type_counts: Counter[FindingType] = Counter()
    for finding in findings:
        type_counts[finding.type] += 1

    # Count total files (approximate - could have duplicates)
    files_with_findings = set(f.location.file for f in findings)

    return AnalysisSummary(
        total_files=len(files_with_findings) if files_with_findings else python_files_count,
        python_files=python_files_count,
        total_findings=len(findings),
        findings_by_severity=dict(severity_counts),
        findings_by_type=dict(type_counts),
        total_recommendations=0,  # Will be updated after recommendations are generated
    )


def _generate_recommendations(findings: list, git_metrics) -> list[Recommendation]:
    """Generate recommendations based on findings and metrics."""
    recommendations = []

    # Count critical and high severity issues
    critical_count = sum(1 for f in findings if f.severity == Severity.CRITICAL)
    high_count = sum(1 for f in findings if f.severity == Severity.HIGH)

    if critical_count > 0:
        recommendations.append(
            Recommendation(
                priority=Priority.URGENT,
                category="Critical Issues",
                action=f"Fix {critical_count} critical issue(s) immediately",
                rationale="Critical issues can cause runtime failures or security vulnerabilities",
                impact="Prevents potential system failures and security breaches",
                effort="high" if critical_count > 10 else "medium",
            )
        )

    if high_count > 5:
        recommendations.append(
            Recommendation(
                priority=Priority.HIGH,
                category="High Severity Issues",
                action=f"Address {high_count} high-severity issues",
                rationale="High-severity issues indicate bugs or type errors that should be fixed",
                impact="Improves code reliability and reduces bug risk",
                effort="high" if high_count > 20 else "medium",
            )
        )

    # Check for complexity issues
    complexity_issues = [f for f in findings if f.type == FindingType.COMPLEXITY]
    if len(complexity_issues) > 5:
        recommendations.append(
            Recommendation(
                priority=Priority.MEDIUM,
                category="Code Complexity",
                action=f"Refactor {len(complexity_issues)} complex functions",
                rationale="High complexity makes code harder to understand, test, and maintain",
                impact="Improves code maintainability and reduces bug introduction risk",
                effort="high",
            )
        )

    # Check for type errors
    type_errors = [f for f in findings if f.type == FindingType.TYPE_ERROR]
    if len(type_errors) > 10:
        recommendations.append(
            Recommendation(
                priority=Priority.HIGH,
                category="Type Safety",
                action="Improve type annotations and fix type errors",
                rationale="Type safety helps catch bugs early and improves code documentation",
                impact="Reduces runtime errors and improves IDE support",
                effort="medium",
            )
        )

    # Git-based recommendations
    if git_metrics and git_metrics.hot_spots:
        recommendations.append(
            Recommendation(
                priority=Priority.MEDIUM,
                category="Code Hot Spots",
                action=f"Review and potentially refactor {len(git_metrics.hot_spots)} "
                "frequently-changed files",
                rationale="Files that change frequently may indicate design issues or "
                "insufficient abstraction",
                impact="Reduces future change frequency and improves design",
                effort="high",
            )
        )

    if git_metrics and git_metrics.large_files:
        recommendations.append(
            Recommendation(
                priority=Priority.LOW,
                category="Large Files",
                action=f"Consider splitting {len(git_metrics.large_files)} large files",
                rationale="Large files are harder to navigate and may indicate low cohesion",
                impact="Improves code organization and maintainability",
                effort="medium",
            )
        )

    # Auto-fixable issues
    fixable_count = sum(1 for f in findings if f.fix_available)
    if fixable_count > 0:
        recommendations.append(
            Recommendation(
                priority=Priority.LOW,
                category="Quick Wins",
                action=f"Run auto-fix for {fixable_count} fixable issues",
                rationale="Many linting issues can be automatically fixed",
                impact="Quick improvement in code quality with minimal effort",
                effort="low",
            )
        )

    return recommendations


if __name__ == "__main__":
    main()
