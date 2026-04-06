# Plan: Hide save bar in CustomiseComponent when used from CitySimple

## Context
`CustomiseComponent` is used in two places. In CitySimple (wizard), saving is handled by auto-save watchers, so the `.cust-save-bar` (Save/Complete/Publish/Discard buttons) is redundant and should be hidden. In `CustomisationsCityDetails`, it should remain visible.

## Changes

### 1. Add `showSaveBar` prop to CustomiseComponent
**File:** `client/src/components/customisationsCityDetails/CustomiseComponent.vue`
- Add prop: `showSaveBar: { type: Boolean, default: true }`
- Add `v-if="showSaveBar"` condition to the existing `v-if="isCityBranchStaging"` on the `.cust-save-bar` div (combine as `v-if="showSaveBar && isCityBranchStaging"`)

### 2. Add `componentProps` to WizardStep interface
**File:** `client/src/types/wizard.ts`
- Add optional field: `componentProps?: Record<string, any>`

### 3. Wire `componentProps` through SectionWrapper
**File:** `client/src/views/CitySimple.vue`
- Pass `:component-props="currentStep.componentProps"` to `<SectionWrapper>` (line ~574)
- Add `componentProps: { showSaveBar: false }` to the customisations wizard step (line ~133)

Note: `SectionWrapper.vue` already accepts `componentProps` and uses `v-bind="componentProps"` on the dynamic `<component>` — no changes needed there.

## Verification
- `npm run type-check` — no TS errors
- Manual: CitySimple → customisations step → no save bar visible
- Manual: CustomisationsCityDetails → save bar still shows
