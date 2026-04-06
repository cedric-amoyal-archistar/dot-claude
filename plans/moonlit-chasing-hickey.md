# Improve CLAUDE.md Coding Instructions

## Context

The current `## Coding instructions` section (lines 92-101) is a rough draft with typos and missing detail. The goal is to rewrite it into a clear, actionable set of instructions that align with the actual project setup (ESLint flat config, Vuetify 3 defaults, Tailwind 3, Pinia composition API) and add relevant Vue 3 / Vuetify 3 / Tailwind best practices.

## Key findings from project analysis

Before writing, these project realities must be respected:

| Area | Actual setup |
|------|-------------|
| `any` types | ESLint has `no-explicit-any: "off"` — `any` IS allowed. The existing CLAUDE.md incorrectly says "no `any` allowed" (line 74). This should be corrected. |
| Vuetify defaults | Outlined variant, compact density, hideDetails=true for all form inputs (configured in vuetify.ts) |
| Vuetify icons | FontAwesome (`fa`) is the default icon set — not mdi |
| Vuetify utilities | Disabled via `settings.scss` (`$utilities: false`) — use Tailwind for utilities instead |
| Tailwind | Vanilla setup, no custom theme extensions, no plugins |
| ESLint | Flat config (v9), 2-space indent, single quotes, unused imports auto-removed |
| Stores | Pinia Composition API only. `cities.ts` is 143KB — the central store |
| Composables | `client/src/composables/` exists with `useCompareTableItems.ts` as pattern |
| Global styles | `app.scss` (custom field styles), `settings.scss` (Vuetify config), `typography.scss` |

## Plan

### Step 1: Fix the inaccuracy in Code Conventions (line 74)

Change:
```
no `any` allowed
```
To:
```
prefer explicit types over `any` where practical (ESLint allows `any` but strive for type safety)
```

### Step 2: Rewrite `## Coding instructions` section (lines 92-101)

Replace the current section with the improved version below. Organized into clear subsections: Components & UI, State Management, Code Quality, and Workflow.

```markdown
## Coding Instructions

### Components & UI
- Use Vuetify 3 components as the primary building blocks for all new UI. Avoid raw HTML elements when a Vuetify equivalent exists (e.g., `v-btn`, `v-card`, `v-dialog`, `v-data-table`).
- Vuetify form inputs are pre-configured with outlined variant, compact density, and hideDetails in `plugins/vuetify.ts` — do not override these defaults unless the design requires it.
- Icons: use FontAwesome classes (`fa-solid fa-*`, `fa-regular fa-*`). Do not use `mdi-*` icons.
- Use Tailwind utilities for layout, spacing, and one-off styling. Vuetify utility classes are disabled in this project.
- When Vuetify component styling needs global adjustment, update `client/src/assets/styles/app.scss` or `client/src/plugins/vuetify.ts` (component defaults) rather than adding one-off overrides in individual components.
- Use `<style scoped>` in SFCs. Only use unscoped styles for global overrides in the `assets/styles/` directory.

### State Management & Logic
- Business logic lives in Pinia stores, not in components. The central store is `client/src/stores/cities.ts` — always read and understand the relevant store before starting a task.
- Use Pinia Composition API style (`ref`, `computed`, functions inside `defineStore`). Never use Options API.
- Always destructure store state with `storeToRefs()` to preserve reactivity.
- Extract reusable logic into composables (`client/src/composables/`). Follow the existing pattern in `useCompareTableItems.ts`.

### Code Quality
- Before creating new components, utilities, or helpers, search for existing ones that can be reused or extended. Check `components/common/`, `classes/Utils.ts`, and `composables/`.
- Prefer explicit TypeScript types over `any` where practical. Use interfaces or type aliases for complex objects.
- Run `npm run lint` and `npm run type-check` from `client/` before considering a task complete.
- Review and refactor your code before finishing — remove dead code, consolidate duplicated logic, simplify where possible.

### Workflow
- Always plan multi-step tasks before starting implementation.
- Use conventional commits (`type(scope): description`).
```

## Files to modify

- `/Users/cedricamoyal/dev/archistar/frontend/citymanager/CLAUDE.md` — lines 74 and 92-101

## Verification

1. Read the final CLAUDE.md to ensure formatting is correct and no sections are broken
2. Confirm no contradictions between the Coding Instructions and the Code Conventions section
3. Run `npm run lint` from `client/` to ensure the CLAUDE.md changes don't affect any linting (they shouldn't — it's markdown)
