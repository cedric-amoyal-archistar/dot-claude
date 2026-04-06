# Plan: Migrate SubmissionUserResponses.vue from Vue 2 to Vue 3

## Context
This file was brought from a Vue 2 + Vuetify 2 repo. It needs three incremental updates to work with Vue 3 + Vuetify 3. The user wants to review after each step.

**File:** `client/src/components/echeck/dashboard/submissionDetails/SubmissionUserResponses.vue`

---

## Step 1: Replace `Vue.set()` with direct property assignment

In Vue 3, reactivity is proxy-based — direct property assignment on reactive objects is automatically tracked. `Vue.set()` no longer exists.

**7 occurrences to replace:**

| Line | Current | Replacement |
|------|---------|-------------|
| 73 | `Vue.set(showSystemUserOverride.value, fieldName, true)` | `showSystemUserOverride.value[fieldName] = true` |
| 86 | `Vue.set(formCalculatedConditions.value, field.name, true)` | `formCalculatedConditions.value[field.name] = true` |
| 93 | `Vue.set(formCalculatedConditions.value, field.name, true)` | `formCalculatedConditions.value[field.name] = true` |
| 108 | `Vue.set(formCalculatedConditions.value, field.name, true)` | `formCalculatedConditions.value[field.name] = true` |
| 123 | `Vue.set(formCalculatedConditions.value, field.name, result)` | `formCalculatedConditions.value[field.name] = result` |
| 135 | `Vue.set(formCalculatedConditions.value, field.name, true)` | `formCalculatedConditions.value[field.name] = true` |
| 150 | `Vue.set(formCalculatedConditions.value, field.name, result)` | `formCalculatedConditions.value[field.name] = result` |

---

## Step 2: Fix TypeScript errors

**2 implicit `any` errors** (lines 157, 161) — add `: any` type annotation to lambda parameters:

| Line | Current | Fix |
|------|---------|-----|
| 157 | `step.fields.find(field => ...)` | `step.fields.find((field: any) => ...)` |
| 161 | `form.value[stepIndex].fields.findIndex(field => ...)` | `form.value[stepIndex].fields.findIndex((field: any) => ...)` |

After Step 1, the 7 "Cannot find name 'Vue'" errors will also be resolved.

---

## Step 3: Replace `ai-` components with Vuetify 3 `v-` equivalents

Reference file for Vuetify 3 patterns: `WizardProperty.vue` (same directory's subfolder).

| `ai-` component | `v-` replacement | Key prop changes |
|------------------|------------------|------------------|
| `ai-tooltip` | `v-tooltip` | Slot: `#activator="{ props }"` + `v-bind="props"` (replaces `{ on, attrs }` + `v-on`/`v-bind` pattern) |
| `ai-radio-group` | `v-radio-group` | `dense` → `density="compact"`, `hide-details` stays |
| `ai-radio` | `v-radio` | `:value` → `:value` (same), label slot stays |
| `ai-text-field` | `v-text-field` | `outlined` → `variant="outlined"`, `dense` → `density="compact"` |
| `ai-autocomplete` | `v-autocomplete` | `outlined` → `variant="outlined"`, `dense` → `density="compact"`, `item-text` → `item-title` |
| `ai-checkbox` | `v-checkbox` | `dense` → `density="compact"` |

### Tooltip slot pattern change (biggest change):
```vue
<!-- OLD (Vue 2) -->
<ai-tooltip top>
  <template #activator="{ on, attrs }">
    <button v-bind="attrs" v-on="on">...</button>
  </template>
  <div>tooltip content</div>
</ai-tooltip>

<!-- NEW (Vue 3 Vuetify 3) -->
<v-tooltip location="top">
  <template #activator="{ props }">
    <button v-bind="props">...</button>
  </template>
  <div>tooltip content</div>
</v-tooltip>
```

---

## Verification
After each step, check for TypeScript/IDE errors using diagnostics and visually confirm the modal renders correctly in the browser.
