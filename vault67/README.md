# vault67 CLI

Multi-agent ticket refinement system integrated with Codeberg (Forgejo/Gitea API).

## Overview

vault67 is a CLI tool that helps refine software development tickets through a multi-agent pipeline. It now uses Codeberg issues as the backend instead of local MD files, enabling better collaboration and tracking.

## Quick Start

### 1. Configuration

Copy the example config file and add your Codeberg API token:

```bash
cp .vault67.conf.example .vault67.conf
# Edit .vault67.conf and add your CODEBERG_TOKEN
```

Get your API token from: https://codeberg.org/user/settings/applications

### 2. Create an Issue

```bash
vault67 create --title "Add user authentication" --repo "https://github.com/myorg/myrepo"
```

This creates a new issue on Codeberg with the spec template as the body.

### 3. Refine the Issue

Edit the issue on Codeberg to fill in the specification sections, then:

```bash
vault67 refine <issue-number>
```

This runs the refinement pipeline (simplified version currently) and updates labels based on readiness.

### 4. Answer Questions (if needed)

If the issue is marked as `state:NEEDS_INFO`, add answers as comments on Codeberg, then:

```bash
vault67 answer <issue-number>
```

This transitions the issue back to `state:REFINING` so you can refine again.

### 5. Implement

When the issue reaches `state:READY_TO_IMPLEMENT`:

```bash
vault67 implement <issue-number>
```

This updates the label to `state:IMPLEMENTING` and adds a promptpack comment for Gas Town handoff.

## State Labels

Issues progress through these states (managed as Codeberg labels):

- `state:NEW` - Just created, needs specification
- `state:REFINING` - Being refined by agents
- `state:NEEDS_INFO` - Blocked on questions, needs human input
- `state:READY_TO_IMPLEMENT` - Refinement complete, ready for development
- `state:IMPLEMENTING` - Handed off to Gas Town for implementation
- `state:DONE` - Implementation complete

## Configuration Options

Set in `.vault67.conf` or as environment variables:

- **CODEBERG_TOKEN** (required) - Your Codeberg API token
- **CODEBERG_API** (optional) - API base URL (default: https://codeberg.org/api/v1)
- **CODEBERG_REPO** (optional) - Target repo in format Owner/Repo (default: Logikfabriken/Vault67)

## Architecture

### API Integration

All commands now interact with the Codeberg API:

- **create**: POST /repos/{owner}/{repo}/issues
- **refine**: GET issue, validate, PATCH issue body, update labels
- **answer**: GET issue, check comments, update labels
- **implement**: GET issue, update labels, add comment

### Issue Body Structure

Issues contain the full specification as markdown:

- Metadata (repo, base ref, spec version)
- Specification sections (context, goals, scope, etc.)
- Acceptance criteria (Gherkin format)
- Architecture alignment
- Security and compliance requirements
- Test strategy
- Definition of Ready checklist
- Repo context

### Local Files

The `tickets/` directory is now optional and can be used as a local cache if needed. The source of truth is the Codeberg issue.

## Migration Notes

This version represents a **migration from local MD files to Codeberg API**:

- ✅ Commands rewired to use API (create, answer, implement)
- ✅ API helper functions implemented
- ✅ Basic refine command with validation
- ⚠️ Full agent pipeline integration in progress
- ⚠️ Agents (Architecture, Security, Test Strategy, Judge) need to be adapted to work with issue bodies

The current `refine` command performs basic validation and state transitions. Full agent integration (running Architecture Compliance Agent, Security & Compliance Agent, Test Strategy Agent, and Judge Agent on issue content) is the next phase.

## Commands

### create

Create a new issue with spec template:

```bash
vault67 create --title "Feature title" --repo "/path/to/repo" [--base-ref "main"]
```

Returns the issue number and URL.

### refine

Run refinement pipeline on an issue:

```bash
vault67 refine <issue-number>
```

Currently performs basic validation. Full agent pipeline integration pending.

### answer

Mark questions as answered and resume refinement:

```bash
vault67 answer <issue-number>
```

Checks for comments (answers), then transitions from `state:NEEDS_INFO` to `state:REFINING`.

### implement

Hand off to Gas Town for implementation:

```bash
vault67 implement <issue-number>
```

Updates label to `state:IMPLEMENTING` and adds promptpack comment.

## Future Enhancements

- [ ] Full agent pipeline integration (Architecture, Security, Test Strategy, Judge)
- [ ] Agent functions working directly with issue bodies
- [ ] Automated repo scanning and context extraction
- [ ] Generate promptpack directly in issue comments
- [ ] Link with Gas Town beads for seamless handoff
- [ ] Support for multiple Codeberg instances
- [ ] Local caching of issue data for offline work

## Contributing

This tool is part of the Gas Town ecosystem. See the main Gas Town documentation for contribution guidelines.

## License

(Add license information here)
