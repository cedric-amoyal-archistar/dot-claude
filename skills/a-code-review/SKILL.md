---
name: a-code-review
description: Reviews unstaged git changes for correctness, security, consistency, and code quality. Use when the user asks to review code, check changes before committing, or wants feedback on modified files.
---

# Code Review

Reviews all unstaged changes in the current repository with a careful, thorough approach.

## Workflow

1. **Gather changes**: Run `git diff` to collect all unstaged changes. If staged changes also exist, run `git diff --cached` separately and review those too.

2. **Read full files**: For each changed file, read the entire file to understand surrounding context, existing patterns, and conventions — not just the diff.

3. **Review each change** against the criteria below.

4. **Present findings** grouped by file, sorted by severity.

5. **Summarize** with a commit-readiness verdict.

## Review criteria

### Correctness
- Logic errors, off-by-one mistakes, wrong conditions
- Missing null/undefined checks at system boundaries (user input, external APIs)
- Race conditions or concurrency issues
- Incorrect error handling (swallowed errors, wrong error types)

### Security
- OWASP top 10: injection, XSS, CSRF, broken auth, sensitive data exposure
- Hardcoded secrets, credentials, or API keys
- Unsafe deserialization or eval usage
- Missing input validation at trust boundaries

### Consistency with existing patterns
- Match the file's existing code style (naming, formatting, indentation)
- Follow established patterns in the codebase (error handling, logging, test structure)
- Use the same abstractions and utilities already present — do not reinvent
- Match import style and ordering conventions

### Code quality
- Dead code or unreachable branches introduced
- Unnecessary complexity — could the change be simpler?
- Missing or broken type annotations (if the project uses them)
- Performance regressions (N+1 queries, unnecessary re-renders, redundant computation)

### Tests
- Are new code paths covered by tests?
- Do existing tests still make sense after the change?
- Are test assertions meaningful (not just snapshot dumps)?

## Output format

Present findings grouped by file, sorted by severity:

```
## <file_path>

### Critical
- <line number> — <issue explanation> — <suggested fix>

### Warning
- <line number> — <issue explanation> — <suggested fix>

### Nit
- <line number> — <issue explanation>
```

- Only include severity sections that have findings
- Include the specific line number and a concrete suggestion for each issue
- Omit files with no issues entirely

End with a brief overall assessment: is this safe to commit as-is, or does it need fixes first?

## Rules
- Do NOT nitpick formatting if a formatter/linter is configured in the project
- Do NOT suggest adding comments, docstrings, or type annotations to unchanged code
- Do NOT suggest refactoring code outside the scope of the diff
- Focus on real problems, not style preferences
- If the changes look good, say so briefly — do not invent issues
