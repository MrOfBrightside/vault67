# vault67 CLI

Multi-agent ticket refinement system integrated with Forgejo (Gitea-compatible API).

## Overview

vault67 is a CLI tool that helps refine software development tickets through a multi-agent pipeline. It uses Forgejo issues as the backend, enabling better collaboration and tracking.

## Quick Start

### 1. Configuration

Copy the example config file and add your Forgejo API token:

```bash
cp .vault67.conf.example .vault67.conf
# Edit .vault67.conf and add your FORGEJO_TOKEN
```

Get your API token from your Forgejo instance (Settings > Applications).

### 2. Create an Issue

```bash
vault67 create --title "Add user authentication" --repo "/path/to/repo"
```

This creates a new issue on Forgejo with the spec template as the body.

### 3. Refine the Issue

Edit the issue on Forgejo to fill in the specification sections, then:

```bash
vault67 refine <issue-number>
```

This runs the multi-agent refinement pipeline (Architecture, Security, Test Strategy, Judge agents) and updates labels based on readiness.

### 4. Answer Questions (if needed)

If the issue is marked as `state:NEEDS_INFO`, add answers as comments on Forgejo, then:

```bash
vault67 answer <issue-number>
```

This transitions the issue back to `state:REFINING` so you can refine again.

### 5. Check Implementation Status

Before handing off, check if implementation already exists:

```bash
vault67 check <issue-number>
```

### 6. Implement

When the issue reaches `state:READY_TO_IMPLEMENT`:

```bash
vault67 implement <issue-number>
```

This checks for existing implementation, updates the label to `state:IMPLEMENTING`, and adds a promptpack comment for Gas Town handoff. Use `--force` to bypass the implementation check.

## State Labels

Issues progress through these states (managed as Forgejo labels):

- `state:NEW` - Just created, needs specification
- `state:REFINING` - Being refined by agents
- `state:NEEDS_INFO` - Blocked on questions, needs human input
- `state:READY_TO_IMPLEMENT` - Refinement complete, ready for development
- `state:IMPLEMENTING` - Handed off to Gas Town for implementation
- `state:DONE` - Implementation complete

## Configuration Options

Set in `.vault67.conf` or as environment variables:

- **FORGEJO_TOKEN** (required) - Your Forgejo API token
- **FORGEJO_API** (optional) - API base URL (default: https://git.logikfabriken.se/api/v1)
- **FORGEJO_REPO** (optional) - Target repo in format Owner/Repo (default: jesper/Vault67)

## Architecture

### API Integration

All commands interact with the Forgejo API:

- **create**: POST /repos/{owner}/{repo}/issues
- **refine**: GET issue, run agent pipeline, PATCH issue body, update labels
- **answer**: GET issue, check comments, update labels
- **check**: Detect existing implementation via local repo signals
- **implement**: GET issue, check status, update labels, add comment
- **done**: Close issue, update labels, report unblocked downstream

### Issue Body Structure

Issues contain the full specification as markdown:

- Metadata (repo, base ref, spec version)
- Specification sections (context, goals, scope, etc.)
- Acceptance criteria (Gherkin format)
- Architecture alignment
- Security and compliance requirements
- Test strategy
- Definition of Ready checklist

### Local Files

The `tickets/` directory is used as a local cache for repo context and spec files. The source of truth is the Forgejo issue.

## Commands

### create

Create a new issue with spec template:

```bash
vault67 create --title "Feature title" --repo "/path/to/repo" [--base-ref "main"]
```

### refine

Run refinement pipeline on an issue:

```bash
vault67 refine <issue-number>
```

Runs Architecture, Security, Test Strategy, and Judge agents on the issue spec.

### answer

Mark questions as answered and resume refinement:

```bash
vault67 answer <issue-number>
```

### check

Check if implementation already exists for an issue:

```bash
vault67 check <issue-number>
```

Reports signals: diff, test files, branch, test pass. Verdict: COMPLETE, PARTIAL, or NOT_STARTED.

### implement

Hand off to Gas Town for implementation:

```bash
vault67 implement <issue-number> [--executor gastown] [--force]
```

Gates on implementation status check. Use `--force` to bypass.

### done

Mark issue as complete:

```bash
vault67 done <issue-number>
```

### list

List issues:

```bash
vault67 list [--all]
```

### status

Show pipeline overview or single issue details:

```bash
vault67 status [issue-number]
```

### project

Manage projects:

```bash
vault67 project create <name> <description>
vault67 project run <name> <description>
vault67 project list [--all]
vault67 project status <milestone-id>
```

### deps

Manage issue dependencies:

```bash
vault67 deps add <issue> <depends-on>
vault67 deps remove <issue> <depends-on>
vault67 deps show <issue>
```

## Contributing

This tool is part of the Gas Town ecosystem. See the main Gas Town documentation for contribution guidelines.
