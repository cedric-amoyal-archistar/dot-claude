# Combine Archistar & Mapbox search results into a single dropdown

## Context
The search dropdown in `Search.vue` renders two separate `<ul>` elements (`archistar-search-results` and `mapbox-search-results`), each independently absolutely positioned. They need to be combined into a single dropdown container where Archistar results appear first, followed by a separator, then Mapbox results.

## File to modify
- `client/src/components/Search.vue` (template section, lines ~151-189)

## Plan

1. **Wrap both `<ul>` lists in a single absolutely-positioned dropdown container** (`<div>`) that has the shared styles (`absolute z-10 mt-1 max-h-60 w-full overflow-y-auto rounded-md border border-border bg-popover shadow-lg`). Show this container when either list has results.

2. **Remove `absolute` positioning and border/shadow styles from each individual `<ul>`** — they become simple lists inside the shared container.

3. **Add a separator between the two lists** — a simple `<hr>` or `<div>` with `border-t border-border my-1` classes, shown only when both lists have results.

4. **Add section labels** (optional but nice) — small muted text headers like "Archistar cities" and "Other results" above each section, only when both sections are visible.

## Verification
- Run `npm run dev` and type in the search box
- Confirm Archistar results appear above Mapbox results in a single dropdown
- Confirm a separator is visible between the two sections when both have results
- Confirm the dropdown works correctly when only one section has results
