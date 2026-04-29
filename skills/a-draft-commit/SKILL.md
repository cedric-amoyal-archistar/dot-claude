---
name: a-draft-commit
description: Draft a commit message based on currently staged git changes
disable-model-invocation: true
allowed-tools: Bash, Read
---

Draft a commit message based on the currently staged changes.

Instructions:
1. Run `git diff --cached` to see what is staged. If nothing is staged, tell the user and stop.
2. Run `git log --oneline -5` to see the recent commit style for this repo.
3. Analyze the staged changes and write a commit message following Conventional Commits format: `type(scope): description`
4. The message should focus on the "why" not the "what".
5. If the changes are large or span multiple concerns, suggest a multi-line message with a summary line and bullet points.
6. Output the draft message in a code block so the user can easily copy it.
7. Do NOT create the commit — only draft the message.
