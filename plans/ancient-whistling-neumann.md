# Replace v-switch with v-btn-toggle (Monthly | Cumulative)

## Context
The `AdoptionReportDetails.vue` component has 3 `v-switch` instances that toggle `isCumulative` (boolean) to switch between cumulative and monthly chart views. The user wants to replace these with a Vuetify `v-btn-toggle` button group showing "Monthly" and "Cumulative" options for a better UX.

## File to modify
`src/components/echeck/reports/adoption/AdoptionReportDetails.vue`

## Changes

### 1. Update the reactive state (script section)
- Change `const isCumulative = ref<boolean>(true)` to `const chartMode = ref<'monthly' | 'cumulative'>('cumulative')`
- Add a computed: `const isCumulative = computed(() => chartMode.value === 'cumulative')` to keep backward compatibility with all existing `isCumulative` references in `dashboardCards` computed and template bindings

### 2. Replace v-switch instance #1 (line ~727-733) — "Signups vs Submissions" card title
Replace:
```vue
<v-switch
  v-if="!getSignUpsMonthlyIsLoading && !getSubmissionsDataIsLoading['monthly']"
  v-model="isCumulative"
  label="Cumulative"
  hide-details
  color="secondary"
/>
```
With:
```vue
<v-btn-toggle
  v-if="!getSignUpsMonthlyIsLoading && !getSubmissionsDataIsLoading['monthly']"
  v-model="chartMode"
  mandatory
  density="compact"
  color="secondary"
>
  <v-btn value="monthly" size="small">Monthly</v-btn>
  <v-btn value="cumulative" size="small">Cumulative</v-btn>
</v-btn-toggle>
```

### 3. Replace v-switch instance #2 (line ~984-990) — dashboard format
Same replacement pattern as above.

### 4. Replace v-switch instance #3 (line ~1009-1015) — stats format
Same replacement pattern, keeping the wrapping `<div class="flex justify-end">`.

## Verification
- Run the dev server and navigate to the adoption report views in all 3 formats (`default`, `dashboard`, and individual stat views)
- Confirm the button group renders with "Monthly" and "Cumulative" options
- Confirm clicking toggles the chart data correctly
- Confirm default selection is "Cumulative"
