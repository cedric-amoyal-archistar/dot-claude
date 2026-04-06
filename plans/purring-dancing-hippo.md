# Plan: Add national-level module access

## Context
The backend added `level` (`'city' | 'national'`) and `level_key` fields to all modules. The frontend needs to branch its access-check and registration logic based on module level. National modules skip disabled/reg-code checks and use a different endpoint to grant access.

## Files to modify
1. `src/types/module.ts`
2. `src/stores/cities.ts`
3. `src/components/ModulesList.vue`

## Changes

### 1. `src/types/module.ts` — Add new fields
```ts
level: 'city' | 'national';
level_key: string;
```

### 2. `src/stores/cities.ts` — Add `addAccessToCountry` method
- Model after `addAccessToCity` (lines 47-76)
- Endpoint: `POST /users/{guid}/add-access-to-country`
- No `code` param (national modules skip reg code)
- Headers: `X-As-Country-Code` from the module's `level_key`
- Reuse `addAccessToCityLoading` ref (only one access request at a time)
- Expose in the store return (line 173)

### 3. `src/components/ModulesList.vue` — Rewrite access logic
- **Replace `canAccessCity` computed** with a `canAccessModule(module)` function:
  - If `module.level === 'national'` → check `module.level_key` in `AuthUser?.nationalAccessList?.countries || []`
  - Else (city / fallback) → check `module.level_key` in `AuthUser?.cityAccessList?.cities || []`
- **Rewrite `openModule`**:
  - If already has access → open directly (unchanged)
  - If `module.level === 'national'` → call `addAccessToCountry(module.url, module.level_key)` (skip disabled/reg-code gates)
  - If city-level → existing flow unchanged (disabled check → reg code check → free add)
- Destructure `addAccessToCountry` from the store alongside `addAccessToCity`

## Edge cases
- Modules without `level` field (backward compat): fallback to city behavior
- `AuthUser.nationalAccessList` may not exist yet on the auth lib object — the `|| []` fallback prevents crashes; access check returns false → triggers `addAccessToCountry` which is the correct behavior

## Verification
- `npm run type-check` — confirms types compile
- `npm run lint` — confirms code style
- Manual test: load a city with both city and national modules, verify city modules go through existing flow, national modules skip disabled/reg-code and hit the country endpoint
