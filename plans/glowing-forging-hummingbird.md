# Fix Double Scrollbars on Mobile Panel View

## Context
On mobile, the panel overlay (`absolute inset-0 z-20 bg-white overflow-y-auto pb-20`) scrolls its content. But each tab component (Sections, Rules, SummaryTab, ShareTab, DataTab) contains a `ScrollArea` with a fixed height calculated from `--panel-content-height` CSS variables. This creates **two nested scroll containers** — the outer overlay and the inner ScrollArea — resulting in two visible scrollbars.

CommentsContainer and QAChecklistContainer don't have this problem — they use flexbox with `overflow-y-auto` on a `flex-1 min-h-0` child, which naturally fills available space.

## Root Cause
The `ScrollArea` height calculations (e.g. `h-[calc(var(--panel-content-height)+40px)]`) are designed for the desktop left panel (400px wide, fixed height). On mobile, the parent overlay already handles scrolling, so these fixed heights are wrong.

## Approach
On `smallSizeScreen`, **remove the fixed height from ScrollArea** and let the content flow naturally within the parent overlay's scroll. The overlay (`overflow-y-auto`) becomes the single scroll container.

Each of the 5 tab components needs a third branch in the `:class` binding: when `smallSizeScreen` is true, apply no height constraint (the ScrollArea just wraps content at its natural height, and the parent overlay scrolls).

### Changes per file

| File | Current class logic | Mobile class |
|------|-------------------|-------------|
| `Sections.vue` | `inIframe ? 'h-[calc(...+40px)]' : 'h-[calc(...+40px)]'` | no fixed height |
| `Rules.vue` | `inIframe ? 'h-[calc(...+65px)]' : 'h-[calc(...+65px)]'` | no fixed height |
| `SummaryTab.vue` | `inIframe ? 'h-[calc(...-170px)]' : 'h-[calc(...-170px)]'` | no fixed height |
| `ShareTab.vue` | `inIframe ? 'h-[calc(...+150px)]' : 'h-[calc(...+150px)]'` | no fixed height |
| `DataTab.vue` | `inIframe ? 'h-[calc(...+10px)]' : 'h-[calc(...+10px)]'` | no fixed height |

### Pattern for each file

Add `useScreenSizeStore` import + `smallSizeScreen` ref, then change the `:class` binding:

```vue
:class="
  smallSizeScreen
    ? ''
    : inIframe
      ? 'h-[calc(var(--panel-content-height)+Xpx)]'
      : 'h-[calc(var(--panel-content-height-double-header)+Xpx)]'
"
```

When `smallSizeScreen` is true, no height class is applied → ScrollArea renders at content height → parent overlay is the only scroll container → single scrollbar.

## Files to modify
1. `client/src/views/main-viewer/components/results/Sections.vue`
2. `client/src/views/main-viewer/components/results/Rules.vue`
3. `client/src/views/main-viewer/components/SummaryTab.vue`
4. `client/src/views/main-viewer/components/ShareTab.vue`
5. `client/src/views/main-viewer/components/DataTab.vue`

Each file needs:
- Import `storeToRefs` from `pinia` (most already have it)
- Import `useScreenSizeStore` from `@/stores/screenSize`
- Destructure `smallSizeScreen`
- Update the `:class` on `ScrollArea`

## Verification
- Mobile (small screen): single scrollbar on the panel overlay, no inner ScrollArea scrollbar
- Desktop: unchanged behavior — ScrollArea with fixed height, no outer scrollbar
- iframe mode: unchanged — still uses `--panel-content-height`
