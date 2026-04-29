---
name: find-unused-vue
description: Scans a Vue.js project for unimported, orphaned, or dead Vue files (.vue, .js, .ts) that are not referenced anywhere in the codebase. Use when the user asks to find unused files, dead code, orphaned components, Vue cleanup, or unreferenced assets in a Vue project.
allowed-tools: Bash, Read
---

# Find Unused Vue Files

Produces a read-only report of likely-unimported `.vue`, `.ts`, and `.js` files in the user's current Vue project. Detection is delegated to a vendored `knip` (no network calls at runtime); the bundled wrapper handles project-type detection (Vite-Vue / Nuxt), runs preflight gates, and formats knip's JSON output as a markdown report with explicit false-positive disclaimers.

## Workflow

1. Run the bundled scan script with no arguments:

   ```
   /Users/cedricamoyal/.claude/skills/find-unused-vue/scripts/scan.sh
   ```

   The script reads `$PWD` and gates on what it finds there. Do NOT `cd` first — the user's invocation cwd is already the project root.

2. The script writes a complete markdown report to stdout. Relay it to the user verbatim. The false-positive disclaimer footer is part of the deliverable.

3. If the script exits non-zero, stdout will contain a single-line human-readable error. Relay it as-is — do not try to "fix" the error or run other tools to investigate.

## Rules

- **Read-only.** The script never deletes, edits, or modifies files in the user's project. Do not propose deletions or run any cleanup commands either.
- **No follow-up tools.** The skill is designed to require zero additional tool calls after the script runs. Do not read project files to "verify" the report. Trust knip's output and the disclaimer footer.
- **Preserve disclaimers.** The report's known-false-positive categories are non-negotiable — always include them in the relay.

## Trust boundary

The vendored `knip` evaluates the project's `knip.config.{ts,js}` if present, which is a JS-eval primitive against the project source. Same trust boundary as `npm install` or `npm test`. Do not run this skill in untrusted repositories.

## Setup (one-time)

The skill ships with a `package.json` pinning `knip`. On first install of the skill, run:

```
cd /Users/cedricamoyal/.claude/skills/find-unused-vue && npm install
```

After that, the skill runs offline against a frozen dependency tree.
