# Extract tableItems logic from CityDetailsCompareTable

## Context
`CityDetailsCompareTable.vue` computes `tableItems` internally from two props (`endPointUrlEnd` and `inputsList`) plus store data. This logic needs to be reusable — specifically in `PublishSection.vue` for a proper `hasPendingChanges` computed that checks whether the compare table actually has diff items, instead of the current naive full-config JSON stringify comparison.

## Plan

### Step 1: Create composable `useCompareBranchTableItems`
**New file:** `client/src/composables/useCompareBranchTableItems.ts`

Extract from `CityDetailsCompareTable.vue`:
- `TableItem` and `GroupItem` interfaces
- `hasChanged()` helper
- `formatGroupKey()` helper
- The `tableItems` computed logic (lines 96-160)

The composable signature:
```ts
export function useCompareBranchTableItems(
  endPointUrlEnd: Ref<string> | string,
  inputsList: Ref<any> | any
) => { compareBranchTableItems: ComputedRef<TableItem[]> }
```

It will internally access `selectedCity` from the cities store (same as current code). It should use `toRef`/`toValue` to handle both ref and plain value inputs.

**Note:** The `onlyShowChanges` toggle stays inside `CityDetailsCompareTable` — the extracted composable should always return ALL changed items (not filtered by `onlyShowChanges`). This way `PublishSection` gets the full list for `hasPendingChanges`. The `CityDetailsCompareTable` will apply its own `onlyShowChanges` filter on the passed-in items.

**Wait — re-reading the requirement:** The user wants to pass `compareBranchTableItems` as a **prop** to `CityDetailsCompareTable`, not use the composable inside it. So the composable computes the items at the parent level, and the table just renders them.

Revised approach: The composable returns items that are **only the changed items** (matching current `hasChanged` filter behavior when `onlyShowChanges=true`). The `onlyShowChanges` toggle in `CityDetailsCompareTable` will filter the prop locally — when `onlyShowChanges=false`, show all items (need full list too).

**Simplest approach:** The composable returns **all items** (no filtering). `CityDetailsCompareTable` receives this as a prop and applies `onlyShowChanges` filtering locally. `PublishSection` uses `.length > 0` on a filtered version (only changed items) for `hasPendingChanges`.

Actually, looking more carefully: the composable needs to return **two things** or the parent needs to compute both. Let me simplify:

**Final approach:**
- Composable returns `compareBranchTableItems` — ALL items with their staging/production values (including headers, sub-headers)
- `CityDetailsCompareTable` receives `compareBranchTableItems` as a prop, applies `onlyShowChanges` filter internally using `getRowColor`/`hasChanged` on the rendered items
- `PublishSection` uses the same `compareBranchTableItems` to check if any non-header items have changes → `hasPendingChanges`

### Step 2: Update `CityDetailsCompareTable.vue`
- Remove props `endPointUrlEnd` and `inputsList`
- Add prop `compareBranchTableItems: TableItem[]`
- Remove the internal `tableItems` computed, `GroupItem` interface, and store access
- Keep `onlyShowChanges`, `getRowColor`, `hasChanged`, `tableHeaders`, `formatGroupKey` locally
- Add a local computed that filters `compareBranchTableItems` based on `onlyShowChanges`
- Keep `TableItem` interface (or import from composable)

### Step 3: Update `CompareBranches.vue`
- Import and use `useCompareBranchTableItems(endPointUrlEnd, inputsList)`
- Pass `compareBranchTableItems` as prop to `CityDetailsCompareTable`
- Remove direct `endPointUrlEnd` and `inputsList` props from template

### Step 4: Update `PublishSection.vue`
- Import and use `useCompareBranchTableItems('params', cityDetailsInputsList)`
- Pass `compareBranchTableItems` as prop to `CityDetailsCompareTable`
- Replace `hasPendingChanges` with:
  ```ts
  const hasPendingChanges = computed(() =>
    compareBranchTableItems.value && compareBranchTableItems.value.length > 0
  );
  ```
- Remove `stagingConfig`, `prodConfig`, and old `hasPendingChanges`

## Files to modify
1. **NEW** `client/src/composables/useCompareBranchTableItems.ts` — composable with extracted logic
2. **EDIT** `client/src/components/restrictionsCityDetails/CityDetailsCompareTable.vue` — receive `compareBranchTableItems` prop instead of computing internally
3. **EDIT** `client/src/components/city/CompareBranches.vue` — use composable, pass prop
4. **EDIT** `client/src/components/citySimple/sections/PublishSection.vue` — use composable, pass prop, fix `hasPendingChanges`

## Verification
- Run `cd client && npm run type-check` to verify no TS errors
- Run `cd client && npm run lint` to verify no lint errors
- Manual: open CompareBranches modal — table should render identically
- Manual: PublishSection should show "pending changes" indicator based on actual field-level diffs
