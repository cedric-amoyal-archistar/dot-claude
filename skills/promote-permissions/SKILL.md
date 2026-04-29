---
name: promote-permissions
description: Audit a fixed set of project .claude/settings.local.json files. Promote safe entries to ~/.claude/settings.json, drop dead one-shots, drop forbidden code-exec primitives, leave project-specific entries in place. Use when the user asks to audit project permissions, consolidate the allowlist, promote permissions to global, clean up local settings, or reduce permission prompts across projects.
allowed-tools: Bash, Read
---

# Promote Permissions

Audit-and-promote workflow for the user's hardcoded list of 4 source project files. Two phases:

1. **Plan** — `plan.sh` reads all sources, classifies each entry against an embedded rules table + dynamic DUP detection against global, writes a plan file, prints a markdown report. **No file is modified.**
2. **Apply** — `apply.sh` re-verifies that source files haven't changed since the plan, backs up all affected files, then atomically writes the changes. Only runs after the user explicitly approves.

## Workflow

1. **Preflight check.** Skill refuses unless `$PWD` is `/Users/cedricamoyal/.claude` exactly.

2. **Run the plan script:**

   ```
   /Users/cedricamoyal/.claude/skills/promote-permissions/scripts/plan.sh
   ```

   It prints a complete markdown report — relay it to the user verbatim. The report includes per-project breakdowns, the items that would be added globally, and the items that would be dropped per global policy.

3. **Ask the user to type `YES` (uppercase) to apply.** Do NOT run apply.sh until the user explicitly types YES. Any other response means abort.

4. **On YES, run the apply script:**

   ```
   /Users/cedricamoyal/.claude/skills/promote-permissions/scripts/apply.sh
   ```

   It re-validates mtimes, backs up to `~/.claude/backups/promote-permissions/<timestamp>/`, and writes atomically. Relay its summary verbatim.

5. **Do NOT commit anything.** The skill never invokes git. The user reviews `git status` / `git diff` themselves and commits manually if they want.

## Rules

- Read-only on the user's project source code. The skill only modifies `.claude/settings.local.json` files and the user's global `~/.claude/settings.json` + `~/.claude/permissions.md`.
- No additional bash beyond the bundled scripts. The skill is self-contained.
- Don't suggest edits, don't propose alternative classifications, don't second-guess the rules table — the user reviews the plan and makes the call.
