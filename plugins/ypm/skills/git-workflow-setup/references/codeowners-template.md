# CODEOWNERS Template

Place this file at `.github/CODEOWNERS` in your project repository.

Replace `<OWNER>` with the repository owner's GitHub username.

## Template

```
# CODEOWNERS
# Important file changes require approval

# Global
* @<OWNER>

# GitHub config
/.github/ @<OWNER>

# CI/CD
/.github/workflows/ @<OWNER>

# Dependencies
/package.json @<OWNER>
/requirements.txt @<OWNER>
/Cargo.toml @<OWNER>
/go.mod @<OWNER>

# Security
/.gitignore @<OWNER>
```

## Notes

- Add project-specific paths as needed (e.g., `/src/auth/` for authentication code)
- For team projects, assign different owners to different directories
- CODEOWNERS requires "Require review from Code Owners" enabled in branch protection settings
