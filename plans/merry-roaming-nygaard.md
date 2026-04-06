# Plan: Extract tableItems logic into composable and improve hasPendingChanges

## Context
`CityDetailsCompareTable.vue` computes `tableItems` internally using `endPointUrlEnd` and `inputsList` props. `PublishSection.vue` needs to know if there are pending changes but currently uses a crude `JSON.stringify` comparison of entire config objects (line 28), which may not align with what the table actually shows. Extracting the `tableItems` logic lets the parent components reuse it for both rendering and change detection.

## Steps

### 1. Create composable `client/src/composables/useCompareTableItems.ts`
- Extract `TableItem`, `GroupItem` interfaces from `CityDetailsCompareTable.vue`
- Extract `hasChanged()` function
- Extract `formatGroupKey()` function
- Export a composable `useCompareTableItems(endPointUrlEnd: Ref<string>, inputsList: Ref<any>)` that returns `{ tableItems: ComputedRef<TableItem[]> }`
- Uses `useCitiesStore()` + `storeToRefs` internally (same as current component)

### 2. Update `CityDetailsCompareTable.vue`
- Remove `endPointUrlEnd` and `inputsList` props
- Add new prop: `items: TableItem[]` (the pre-computed table items)
- Remove internal `tableItems` computed, `hasChanged`, `formatGroupKey`, interfaces, and store usage
- Import `TableItem` type from the composable
- Keep `tableHeaders`, `getRowColor`, and template as-is (just use `props.items` instead of `tableItems`)

### 3. Update `PublishSection.vue`
- Import `useCompareTableItems` composable
- Call it with `ref('params')` and `cityDetailsInputsList` (params only for now)
- Pass result as `items` prop to `CityDetailsCompareTable`
- Replace `hasPendingChanges` (line 28) with: `computed(() => paramsTableItems.value.length > 0)`
- Remove `stagingConfig` and `prodConfig` computeds (no longer needed)
- Remove commented-out code (lines 30-81) — dead code cleanup

### 4. Update `CompareBranches.vue`
- Import `useCompareTableItems` composable
- Call it with existing `endPointUrlEnd` and `inputsList` computeds (could be params or customizations depending on route query)
- Pass result as `items` prop to `CityDetailsCompareTable`

## Files to modify
- **New**: `client/src/composables/useCompareTableItems.ts`
- **Edit**: `client/src/components/restrictionsCityDetails/CityDetailsCompareTable.vue`
- **Edit**: `client/src/components/citySimple/sections/PublishSection.vue`
- **Edit**: `client/src/components/city/CompareBranches.vue`

## Verification
- Run `npm run lint` and `npm run type-check` from `client/`
- Manual test: open a city in the simple UI, go to the Publish section — verify "Staging has unpublished changes" indicator matches what the compare table shows in the dialog
- Manual test: open CompareBranches modal from restrictions-city-details — verify table still renders correctly
