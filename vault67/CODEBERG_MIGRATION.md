# Codeberg API Migration

## Summary

The vault67 CLI has been successfully rewired to use the Codeberg/Forgejo API as the ticket backend instead of local MD files.

## Changes Made

### 1. Configuration System
- Added `.vault67.conf` configuration file support (see `.vault67.conf.example`)
- Configuration can be set via environment variables or config file
- Required settings:
  - `CODEBERG_TOKEN`: Personal access token for Codeberg API
  - `CODEBERG_API`: API base URL (default: https://codeberg.org/api/v1)
  - `CODEBERG_REPO`: Repository in format `owner/repo` (default: Logikfabriken/Vault67)

### 2. API Helper Functions
Added comprehensive Forgejo/Gitea API functions:
- `api_request()`: Base HTTP request handler with auth
- `api_create_issue()`: Create new issue
- `api_get_issue()`: Get issue by number
- `api_update_issue()`: Update issue body/title
- `api_replace_labels()`: Set issue labels
- `api_add_comment()`: Add comment to issue
- `api_get_comments()`: Get all comments
- Extract helpers for parsing JSON responses

### 3. Command Rewiring

#### `vault67 create`
- Creates issue on Codeberg with spec template as body
- Adds `state:NEW` label
- Returns issue number and URL
- No longer creates local ticket directories

#### `vault67 refine`
- Fetches issue from API
- Runs agent pipeline using temporary files
- Updates issue body with refined spec
- Manages label transitions: `NEW/NEEDS_INFO/REFINING` → `READY_TO_IMPLEMENT/NEEDS_INFO/REFINING`
- Adds comments for:
  - Blocking questions (when `state:NEEDS_INFO`)
  - Promptpack (when `state:READY_TO_IMPLEMENT`)
  - Status updates

#### `vault67 answer`
- Checks issue is in `state:NEEDS_INFO`
- Verifies comments contain answers
- Changes label to `state:REFINING`
- Adds status comment

#### `vault67 implement`
- Checks issue is in `state:READY_TO_IMPLEMENT`
- Changes label to `state:IMPLEMENTING`
- Adds implementation status comment with Gas Town handoff instructions
- Returns issue URL and next steps

### 4. Agent Compatibility
- Agents still work with temporary files for simplicity
- `cmd_refine` creates temp directory, extracts issue body to files
- Agents run on temp files
- Updated spec is read back and PATCH'd to API
- Temp directory is cleaned up after processing

## Testing

### Syntax Check
```bash
bash -n vault67
# ✓ No syntax errors
```

### Error Handling
```bash
vault67 create --title "Test" --repo "/test"
# ✓ Correctly errors: "CODEBERG_TOKEN not set"
```

### Full Test (requires token)
```bash
# Set up config
cat > .vault67.conf <<CONF
CODEBERG_TOKEN=your_token_here
CODEBERG_API=https://codeberg.org/api/v1
CODEBERG_REPO=Logikfabriken/Vault67
CONF

# Test workflow
vault67 create --title "Add rate limiting" --repo "/repos/my-service"
# Should create issue and return: Issue #X created

vault67 refine X
# Should run agents and update issue

vault67 answer X  # if NEEDS_INFO
# Should change state to REFINING

vault67 implement X  # if READY_TO_IMPLEMENT
# Should change state to IMPLEMENTING
```

## Files Modified

- `vault67`: Main CLI script - fully rewired
- `.gitignore`: Added `.vault67.conf`
- `.vault67.conf.example`: Created config example

## Files Backed Up

- `vault67.backup`: Original script backup

## Repository

- Codeberg repo: https://codeberg.org/Logikfabriken/Vault67
- API docs: https://codeberg.org/api/swagger
- Labels available: `state:NEW`, `state:REFINING`, `state:NEEDS_INFO`, `state:READY_TO_IMPLEMENT`, `state:IMPLEMENTING`, `state:DONE`

## Next Steps

1. Set up Codeberg token and config
2. Test full workflow with real issues
3. Update any external documentation
4. Consider caching: optionally sync issues to local files for offline access
5. Enhanced comment parsing for better answer verification in `cmd_answer`

## Notes

- The local `tickets/` directory is no longer used by default
- All state is now stored in Codeberg issues and labels
- Comments provide audit trail and human communication
- Agents are unchanged - they still work with temporary files
- API rate limits apply - be mindful of repeated calls
