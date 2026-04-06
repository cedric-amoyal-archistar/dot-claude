# Plan: Implement `getLabelFromCityDetailsInputsList`

## Context
`getLabelFromCityDetailsInputsList` in `useCompareTableItems.ts:52` is a stub that just returns the key as-is. It's used in the compare table to display human-readable labels instead of raw object keys. The labels already exist in `cityDetailsInputsList` (defined in `cities.ts:211`), which is a computed object structured as:

```
{
  system: [ { key: 'systemUserOnly', label: 'System User Only', ... }, ... ],
  <group>: [ { key: '...', label: '...', ... }, ... ],
  ...
}
```

## Changes

### File: `src/composables/useCompareTableItems.ts`

1. **Add `cityDetailsInputsList` to the `storeToRefs` destructure** (line 35):
   - Change `{ selectedCity, onlyShowChanges, enums }` to `{ selectedCity, onlyShowChanges, enums, cityDetailsInputsList }`

2. **Implement `getLabelFromCityDetailsInputsList`** (line 52-54):
   - Iterate over all groups in `cityDetailsInputsList.value`
   - For each group (array of inputs), find an item where `item.key === key`
   - Return `item.label` if found, otherwise return `key` as fallback

## Verification
- Run `npm run lint` and `npm run type-check` from `client/`
- Visually confirm in the compare table that keys now show human-readable labels
