# Restyle CityDetailsCompareTable to be more compact and GitLab MR-like

## Context
The compare table is visually bulky with large rows, inconsistent column widths, and garish background colors. Need to make it more compact and style the diff colors closer to GitLab merge request diffs.

## File to modify
`client/src/components/restrictionsCityDetails/CityDetailsCompareTable.vue`

## Changes

### 1. Template: add `word-break` and equal column widths
Add `table-layout: fixed` via a class on `v-data-table` and set each `<td>` to allow text wrapping.

Add `width` to tableHeaders: each column gets `width: '33%'`.

### 2. CSS overrides (`:deep(.v-data-table)`)

**Row height / padding:**
- `td { padding: 4px 12px !important; font-size: 12px; }` (down from default ~16px padding)
- `th { font-size: 12px; padding: 6px 12px !important; }` (smaller headers)

**Column width:**
- Add `table-layout: fixed` on the `table` element so 33% widths are respected
- `td, th { word-wrap: break-word; overflow-wrap: break-word; }`

**GitLab-style diff colors** (replace current bright colors):
- **Added (staging has value, prod empty):** `background: #ddfbe6` (soft green, like GitLab's addition)
- **Removed (staging empty, prod has value):** `background: #f9d7dc` (soft red/pink, like GitLab's deletion)
- **Changed (both have different values):** `background: #fdf5e6` (soft amber/yellow)
- **Unchanged:** no background
- **Group header:** `background: #f5f5f5` (keep as-is, it's fine)

### 3. Update `getRowColor` return values
Change the class names to new ones matching the GitLab-style colors:
- `'red-lighten-4'` → `'diff-removed'`
- `'green-lighten-4'` → `'diff-added'`
- `'yellow-lighten-4'` → `'diff-changed'`

Then update the CSS to use `.diff-added`, `.diff-removed`, `.diff-changed`.

## Verification
- `npm run type-check`
- Visually inspect compare table in the Publish step and Restrictions page
- Rows should be noticeably thinner, text smaller (12px), columns equal width with wrapping
