# Plan: Replace "3 Drawings" Button with Condition Thumbnail Carousel

## Context

In the mobile view of Rules.vue, there's a hardcoded "3 Drawings" button (line 316-326) that just opens the canvas view. The goal is to replace it with an inline thumbnail carousel showing the actual views/drawings available for each condition, similar to the mockup image. Clicking a thumbnail should select that condition (via `showCondition`) and navigate to the clicked view.

## Approach

### Step 1: Make `buildViewDataForCondition` logic reusable

**File:** `client/src/lib/managers/ViewManager.ts`

The `buildViewDataForCondition` method (line 575) is `private`. We need to either:
- Make it `public` (or `static`), OR
- Extract the logic into a standalone utility function

**Recommended:** Extract into a standalone function since it only depends on `processor.bindingIdAndIdToViewAndElements`. This avoids needing a ViewManager instance reference in Rules.vue.

Create a utility function (can live in ViewManager.ts or a separate file) that takes `complyElements` and `bindingIdAndIdToViewAndElements` and returns `Record<string, ViewData>`.

### Step 2: Pre-compute views for all conditions

**File:** `client/src/stores/results.ts`

Add a new state to the results store:
```ts
const viewsForConditions = ref<Record<string, Record<string, ViewData>>>({});
```

This maps `condition.id → Record<string, ViewData>` (the views available for that condition).

### Step 3: Populate `viewsForConditions` after data loads

**File:** `client/src/views/main-viewer/Home.vue` (around line 719, after ViewManager initializes)

After the processor and conditions are available, iterate over all conditions and build the view data:

```ts
// After ViewManager is initialized and conditions are loaded
for (const section of conditions.value) {
  for (const rule of section.rules) {
    for (const condition of rule.conditions) {
      const complyElements = [
        ...(condition.metadata_rich_info?.elements || []),
        ...(condition.metadata_rich_info?.node_stylings || []),
      ];
      const views = buildViewDataForConditionUtil(
        complyElements,
        processor.value.bindingIdAndIdToViewAndElements
      );
      resultsStore.viewsForConditions[condition.id] = views;
    }
  }
}
```

The `conditions` ref is populated by `useSubmissionLoader` and contains sections with rules and conditions. Need to verify the exact shape.

### Step 4: Replace "3 Drawings" button with thumbnail carousel in Rules.vue

**File:** `client/src/views/main-viewer/components/results/Rules.vue`

Replace lines 316-326 (the "3 Drawings" button) with inline thumbnails:

```vue
<div
  v-if="smallSizeScreen && showPanelOnMobile && viewsForConditions[condition.id]"
>
  <p class="text-sm font-semibold text-slate-700 mb-1">
    {{ Object.keys(viewsForConditions[condition.id]).length }} Drawings
  </p>
  <div class="flex flex-row gap-2 overflow-x-auto">
    <div
      v-for="view in viewsForConditions[condition.id]"
      :key="view.key"
      class="flex flex-col gap-1 items-center shrink-0 size-20 border p-1 rounded-md justify-end bg-white cursor-pointer hover:border-primary hover:shadow-md relative group/thumbnail overflow-hidden"
      :class="{
        'border-2 border-primary shadow-md': view.key === currentView?.key,
      }"
      @click="onThumbnailClick(condition, view)"
    >
      <img
        v-if="thumbnailImages[view.key]"
        :src="thumbnailImages[view.key]"
        :alt="view.displayName"
        class="absolute inset-0 transition-all duration-300 group-hover/thumbnail:scale-120 grayscale"
      />
      <div
        v-else
        class="absolute inset-0 flex items-center justify-center bg-gray-100"
      >
        <Skeleton class="h-12 w-12 rounded" />
      </div>
      <div class="text-xs line-clamp-2 z-9 text-center bg-white/80 font-semibold px-1 rounded">
        {{ view.displayName }}
      </div>
    </div>
  </div>
</div>
```

### Step 5: Handle thumbnail click in Rules.vue

Add `onThumbnailClick` method that:
1. Calls `showCondition(condition)` (already exists in Rules.vue at line 644)
2. Switches to canvas view via `openCanvasView()` (already imported)
3. Emits view selection — need to add an emit for `showView` or use the existing condition update mechanism

The flow: `showCondition(condition)` updates `currentCondition` via v-model, which triggers the parent chain → ViewManager.showCondition → which sets viewDataForCondition and renders. Then we need to also switch to the specific view.

**Key question:** How to trigger a specific view switch from Rules.vue? The `showCondition` event propagates up to Home.vue which calls `viewManagerResult.showCondition(condition, view?)`. Looking at the ViewManager:

```ts
// Home.vue line 919:
await showCondition(condition);
```

The `showCondition` from useViewManager accepts `(condition, view?)`. If we pass the view, it should switch to that view. The emit chain is:
- Rules.vue `showCondition()` → sets `currentCondition.value = condition` (v-model)
- Parent results/Home.vue catches `@update:condition` → emits `showCondition`
- Main.vue catches → emits `showCondition` up
- Home.vue catches → calls `await showCondition(condition)`

We need to also pass the target view. Looking at the current emit chain, it only passes the condition. We have two options:
1. Add a separate emit/mechanism for "show condition + view"
2. Store the target view in the results store and have Home.vue read it

**Recommended:** Add a `targetView` ref to the results store. When a thumbnail is clicked in Rules.vue, set `resultsStore.targetView = view` before updating the condition. In Home.vue, when handling `showCondition`, check if `targetView` is set and pass it along.

### Step 6: Load thumbnail images

Reuse the `useImageCache` composable (from `@/views/main-viewer/composables/useImageCache`) in Rules.vue to load thumbnail images for the condition views. Watch `viewsForConditions` and load images as they become available.

## Files to Modify

1. **`client/src/lib/managers/ViewManager.ts`** — Extract `buildViewDataForCondition` logic into an exported utility function
2. **`client/src/stores/results.ts`** — Add `viewsForConditions` and `targetView` state
3. **`client/src/views/main-viewer/Home.vue`** — Compute viewsForConditions after data loads; handle targetView on showCondition
4. **`client/src/views/main-viewer/components/results/Rules.vue`** — Replace "3 Drawings" button with thumbnail carousel; add onThumbnailClick handler; load images

## Existing Code to Reuse

- `buildViewDataForCondition` logic from `ViewManager.ts:575-606`
- `useImageCache` composable from `@/views/main-viewer/composables/useImageCache`
- Thumbnail rendering pattern from `ThumbnailNavigation.vue:72-109` (styling, image loading, skeleton)
- `showCondition()` in Rules.vue (line 644)
- `openCanvasView()` from screenSizeStore (already imported in Rules.vue)

## Verification

1. Run `bun run build` from `client/` to verify no type errors
2. Run `bun run lint` to check code style
3. Manual testing:
   - Open the app on mobile (or resize browser to small screen)
   - Navigate to a section with conditions
   - Verify each condition shows thumbnail carousel instead of "3 Drawings" button
   - Verify thumbnail count label matches actual number of views
   - Click a thumbnail → should switch to that condition + view on the canvas
   - Verify thumbnail images load (with skeleton placeholders while loading)
   - Verify the selected thumbnail has the highlighted border matching `currentView`
