# Add "Generate AI Summary" to Condition Dropdown Menu

## Context
Add a new "Generate AI Summary" button in the condition dropdown menu in Rules.vue. On click, it opens a modal that calls an API endpoint and displays the AI-generated summary HTML and optional widget HTML.

## Files to Modify

1. **`src/api/viewer.ts`** — Add new API method
2. **`src/stores/results.ts`** — Add modal state (show flag + condition ref)
3. **`src/views/main-viewer/components/results/Rules.vue`** — Add dropdown button + open modal logic
4. **`src/views/main-viewer/Home.vue`** — Register the new modal component
5. **NEW: `src/views/main-viewer/components/results/ConditionAiSummaryModal.vue`** — Modal component

## Implementation Steps

### Step 1: Add API method in `src/api/viewer.ts`
Add after `deleteFeedback` (~line 395):
```ts
getConditionAiSummary: (
  shareKey: string,
  conditionId: string,
  payload: {
    rule_name: string;
    rule_description: string;
    condition_name: string;
    condition_description: string;
  }
) =>
  api
    .post(
      `/submissions/${shareKey}/viewer/conditions/${conditionId}/ai-summary`,
      payload
    )
    .then((res) => res.data),
```

### Step 2: Add modal state in `src/stores/results.ts`
Add refs:
- `showConditionAiSummaryModal` (boolean, default false)
- `conditionForAiSummaryModal` (any, null)
- `ruleForAiSummaryModal` (any, null)

Export all three.

### Step 3: Add dropdown button in `Rules.vue`
Inside `<DropdownMenuContent>`, add a new button before the "Help us improve" button (around line 190), gated behind `isSystemOrDesignAdminOrProductTeam()`:
```vue
<div v-if="isSystemOrDesignAdminOrProductTeam()">
  <Button
    @click="
      openConditionAiSummaryModal(rule, condition);
      dropdownOpenStates[condition.id] = false;
    "
    variant="ghost"
    size="sm"
    class="w-full text-left flex items-center justify-start"
  >
    <SparklesIcon class="w-4 h-4" />
    Generate AI Summary
  </Button>
</div>
```
- Import `SparklesIcon` from `lucide-vue-next` (good AI icon)
- Add `openConditionAiSummaryModal` function that sets `showConditionAiSummaryModal = true`, `ruleForAiSummaryModal = rule`, `conditionForAiSummaryModal = condition`
- Import the new store refs: `showConditionAiSummaryModal`, `conditionForAiSummaryModal`, `ruleForAiSummaryModal`

### Step 4: Create `ConditionAiSummaryModal.vue`
Location: `src/views/main-viewer/components/results/ConditionAiSummaryModal.vue`

Structure:
- Props: `shareKey: string`
- Uses `Dialog` from shadcn-vue (same pattern as `CreateFeedbackModal`)
- Controlled by `showConditionAiSummaryModal` from results store
- On mount (via `watch` on `showConditionAiSummaryModal` becoming true), call the API:
  - Payload: `{ rule_name: rule.name, rule_description: rule.description, condition_name: condition.name, condition_description: condition.description }`
- States: `loading` (ref bool), `summaryHtml` (ref string), `widgetHtml` (ref string | null), `error` (ref string | null)
- Template:
  - `DialogHeader` with `DialogTitle` "AI Summary" and close button
  - Loading spinner while fetching
  - Error state if request fails
  - `summaryHtml` rendered via `v-html`
  - `widgetHtml` rendered in a sandboxed `<iframe>` using `srcdoc` attribute (handles HTML/CSS/JS safely)

### Step 5: Register modal in `Home.vue`
After the feedback modals (~line 226), add:
```vue
<ConditionAiSummaryModal :share-key="shareKey" />
```
Import the component.

## Verification
1. Run `bun run build` to type-check
2. Run `bun run lint` to check linting
3. Manual test: open a submission, click the "..." dropdown on a condition, click "Generate AI Summary", verify modal opens and API is called
