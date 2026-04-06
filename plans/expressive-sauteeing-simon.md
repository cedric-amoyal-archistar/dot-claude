# Standardize "AI Precheck" → "AI PreCheck" casing

## Context
The UI already uses "AI PreCheck" / "AI Precheck" instead of "eCheck", but the casing is inconsistent. The user wants to standardize to "AI PreCheck" (capital C) everywhere.

## Changes

4 occurrences of "AI Precheck" → "AI PreCheck":

1. **`client/src/views/common/components/Header.vue:19`** (HTML template)
   - `AI Precheck` → `AI PreCheck`

2. **`client/src/views/main-viewer/Home.vue:534`** (script — document.title)
   - `AI Precheck v${version}` → `AI PreCheck v${version}`

3. **`client/src/views/projects/ProjectDetail.vue:206`** (script — useTitle)
   - `AI Precheck | ${newTitle}` → `AI PreCheck | ${newTitle}`

4. **`client/src/views/projects/ProjectList.vue:339`** (script — useTitle)
   - `AI Precheck | Projects` → `AI PreCheck | Projects`

## Verification
- `bun run build` from `client/` to confirm no build errors
- Visually check Header, Home page title, ProjectList and ProjectDetail page titles
