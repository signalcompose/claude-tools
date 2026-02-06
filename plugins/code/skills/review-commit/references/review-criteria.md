# Code Review Criteria

Standards and criteria used by the code-reviewer agent when reviewing commits.

## Code Quality
- Readability and maintainability
- Proper error handling
- No hardcoded sensitive values (API keys, passwords, tokens)
- Appropriate use of types and interfaces

## Security
- No exposed secrets or credentials
- No SQL injection vulnerabilities
- No XSS vulnerabilities
- Input validation where needed
- Secure handling of user data

## Best Practices
- Project conventions (CLAUDE.md compliance)
- Consistent naming conventions
- No unnecessary duplication
- Appropriate code comments

## Logic
- No obvious bugs
- Edge cases handled
- Correct algorithm usage
- Proper null/undefined handling

## Confidence Threshold

Only issues with **confidence >= 80%** should be reported to the user.
