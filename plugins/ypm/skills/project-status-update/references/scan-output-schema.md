# scan_projects.py JSON Output Schema

This document describes the JSON output format of the `scan_projects.py` script used by the project-status-update skill.

## Script Location

```
${CLAUDE_PLUGIN_ROOT}/scripts/scan_projects.py
```

## Invocation

```bash
python ${CLAUDE_PLUGIN_ROOT}/scripts/scan_projects.py
```

The script reads `~/.ypm/config.yml` to determine scan directories and settings.

## Output Format

The script outputs a JSON object to stdout:

```json
{
  "scan_date": "2026-01-15T10:30:00",
  "projects": [
    {
      "name": "project-name",
      "path": "/Users/username/Projects/project-name",
      "is_git": true,
      "is_worktree": false,
      "current_branch": "main",
      "last_commit_date": "2026-01-15",
      "last_commit_message": "feat: add new feature",
      "status": "active",
      "has_claude_md": true,
      "has_readme": true
    }
  ]
}
```

## Field Descriptions

### Top-Level Fields

| Field | Type | Description |
|-------|------|-------------|
| `scan_date` | string (ISO 8601) | Timestamp when the scan was performed |
| `projects` | array | List of discovered project objects |

### Project Object Fields

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Directory name of the project |
| `path` | string | Absolute path to the project directory |
| `is_git` | boolean | Whether the directory contains a git repository |
| `is_worktree` | boolean | Whether the project is a git worktree (`.git` is a file, not a directory) |
| `current_branch` | string | Current git branch name (empty if not a git repo) |
| `last_commit_date` | string | Date of the most recent commit (YYYY-MM-DD format) |
| `last_commit_message` | string | Subject line of the most recent commit |
| `status` | string | Classification: `"active"`, `"developing"`, or `"inactive"` |
| `has_claude_md` | boolean | Whether `CLAUDE.md` exists in the project root |
| `has_readme` | boolean | Whether `README.md` exists in the project root |

## Status Classification

The `status` field is determined by the `last_commit_date`:

| Status | Criteria |
|--------|----------|
| `active` | Last commit within configured active threshold (default: 7 days) |
| `developing` | Last commit within configured developing threshold (default: 30 days) |
| `inactive` | Last commit older than developing threshold |

## Error Handling

If the script encounters errors:
- Non-git directories are included with `is_git: false`
- Inaccessible directories are skipped silently
- The script exits with code 0 on success, non-zero on fatal errors
- Error messages are written to stderr
