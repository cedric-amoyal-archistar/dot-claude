# Plan: Deduplicate CitySimple.vue Step Sections

## Context
`CitySimple.vue` has 11 wizard steps, 8 of which share an identical structure: card wrapper, card-header with description, optional step-tag, section component, and Back/Continue buttons. This repeated pattern spans ~500 lines of template. We'll extract it into a `SectionWrapper` component and create new section components for steps that currently have inline content.

**Current state:** Section files are already in `sections/` subfolder (already staged). The new component files (`SectionWrapper.vue`, `CreateSection.vue`, `GettingStartedSection.vue`, `DetailsSection.vue`) already exist from a previous attempt but CitySimple.vue was reverted to its original state.

## Pre-step: Cleanup

Remove dead code in CitySimple.vue:
- `searchQuery` ref (line 101) — written but never read anywhere

Fix bugs:
- Restrictions tag (line 838): `wizardSteps[2]?.complete` → `wizardSteps.find(s => s.key === 'restrictions')?.complete`
- Branding tag (line 816): `wizardSteps[2]?.complete` → `wizardSteps.find(s => s.key === 'branding')?.complete`

## Step 1: Create new section components for steps with inline content

These already exist in `sections/` from the previous attempt. Verify they're correct, or recreate:

### `sections/CreateSection.vue`
Self-contained component — owns all create-mode state (`mapboxSearchIsActive`, `mapboxSelectedResponse`, `searchResults`, `mapboxSearchLoading`, `createForm`) and functions (`searchMapbox`, `onSearchInput`, `onItemSelect`, `switchSearchMode`, `createCity`). Gets `filterTypes`, `filterCountries`, `createNewCityIsLoading`, `createNewCityError` from the store directly via `storeToRefs`.

### `sections/GettingStartedSection.vue`
Receives `wizardSteps` as prop. Gets `selectedCity`, `settingsForm`, `filterCountries` from store. Emits `goToStep` and `nextStep`.

### `sections/DetailsSection.vue`
Gets `selectedCity`, `settingsForm`, `filterCountries` from store. Just renders content — no wrapper (SectionWrapper handles that).

## Step 2: Verify/update `SectionWrapper.vue`

Already exists. Props: `header`, `tag`, `complete`, `action`. Emits: `next`, `back`. Slots: `default`, `actions`.

## Step 3: Refactor CitySimple.vue

1. **Add imports** for `SectionWrapper`, `CreateSection`, `GettingStartedSection`, `DetailsSection`
2. **Remove** create-mode state/functions (lines 98-156) — moved to CreateSection
3. **Remove** unused store refs: `filterCountries`, `filterTypes`, `createNewCityIsLoading`, `createNewCityError`
4. **Replace** template step sections with SectionWrapper usage:
   - Create → `<CreateSection v-if="..." />`
   - Getting Started → `<GettingStartedSection v-if="..." />`
   - Details through Environments → `<SectionWrapper>` with section component in default slot
   - Publish → `<SectionWrapper :action="false">` with `#actions` slot for Back-only button

## Files to modify
1. `client/src/components/citySimple/sections/SectionWrapper.vue` — verify existing
2. `client/src/components/citySimple/sections/CreateSection.vue` — verify existing
3. `client/src/components/citySimple/sections/GettingStartedSection.vue` — verify existing
4. `client/src/components/citySimple/sections/DetailsSection.vue` — verify existing
5. `client/src/views/CitySimple.vue` — update imports, remove dead code, replace template

## Verification
1. `cd client && npm run type-check` — no TypeScript errors
2. `npm run dev` — manually test each wizard step
