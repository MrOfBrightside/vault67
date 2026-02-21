"""Git repository analysis for understanding codebase evolution."""

from collections import Counter
from datetime import datetime
from pathlib import Path
from typing import Optional

try:
    from git import Repo
    from git.exc import InvalidGitRepositoryError

    GIT_AVAILABLE = True
except ImportError:
    GIT_AVAILABLE = False

from vault67_agent.models.schemas import GitMetrics


class GitRepoAnalyzer:
    """Analyzes git repository history and metrics."""

    def __init__(self, repo_path: Path, hot_spot_threshold: int = 10) -> None:
        """
        Initialize git repository analyzer.

        Args:
            repo_path: Path to the git repository
            hot_spot_threshold: Minimum number of changes to be considered a hot spot
        """
        self.repo_path = repo_path
        self.hot_spot_threshold = hot_spot_threshold

        if not GIT_AVAILABLE:
            raise ImportError(
                "GitPython is not installed. Install with: pip install GitPython"
            )

        try:
            self.repo = Repo(repo_path)
        except InvalidGitRepositoryError:
            raise ValueError(f"{repo_path} is not a valid git repository")

    def analyze(self) -> GitMetrics:
        """
        Analyze the git repository.

        Returns:
            GitMetrics object with repository statistics
        """
        # Get all commits
        commits = list(self.repo.iter_commits())
        total_commits = len(commits)

        # Get contributors
        contributors = set()
        for commit in commits:
            if commit.author:
                contributors.add(commit.author.email)

        # Find hot spots (frequently changed files)
        file_changes: Counter[str] = Counter()
        for commit in commits[:1000]:  # Limit to last 1000 commits for performance
            try:
                for item in commit.stats.files:
                    file_changes[item] += 1
            except Exception:
                # Skip commits we can't analyze
                continue

        # Get files that change most frequently
        hot_spots = [
            file
            for file, count in file_changes.most_common(20)
            if count >= self.hot_spot_threshold
        ]

        # Find large files (> 500 lines)
        large_files = self._find_large_files()

        # Get last commit date
        last_commit_date = None
        if commits:
            try:
                last_commit_date = datetime.fromtimestamp(
                    commits[0].committed_date
                ).isoformat()
            except Exception:
                pass

        return GitMetrics(
            total_commits=total_commits,
            total_contributors=len(contributors),
            hot_spots=hot_spots,
            large_files=large_files,
            last_commit_date=last_commit_date,
        )

    def _find_large_files(self, size_threshold: int = 500) -> list[str]:
        """
        Find files larger than the threshold.

        Args:
            size_threshold: Minimum number of lines to be considered large

        Returns:
            List of file paths that are large
        """
        large_files = []

        try:
            # Get all Python files in the repo
            for py_file in Path(self.repo.working_dir).rglob("*.py"):
                # Skip hidden directories and common non-source directories
                if any(part.startswith(".") for part in py_file.parts):
                    continue
                if any(
                    part in {"__pycache__", "venv", "env", ".venv", "node_modules"}
                    for part in py_file.parts
                ):
                    continue

                try:
                    with open(py_file, "r", encoding="utf-8") as f:
                        lines = sum(1 for _ in f)
                        if lines > size_threshold:
                            # Get relative path
                            rel_path = py_file.relative_to(self.repo.working_dir)
                            large_files.append(f"{rel_path} ({lines} lines)")
                except Exception:
                    # Skip files we can't read
                    continue

        except Exception:
            # If we can't analyze files, return empty list
            pass

        return large_files[:20]  # Limit to top 20


def analyze_git_repo(repo_path: Path) -> Optional[GitMetrics]:
    """
    Analyze a git repository.

    Args:
        repo_path: Path to the repository

    Returns:
        GitMetrics if successful, None if not a git repo or GitPython not available
    """
    if not GIT_AVAILABLE:
        return None

    try:
        analyzer = GitRepoAnalyzer(repo_path)
        return analyzer.analyze()
    except (ValueError, InvalidGitRepositoryError):
        # Not a git repository
        return None
    except Exception:
        # Other errors - return None
        return None
