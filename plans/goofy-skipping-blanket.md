# Feedback Modal Plan

## Context
Add a feedback modal accessible from the navbar so users can submit bug reports and feature suggestions via the service desk API.

## Files to Create
- `client/src/views/common/components/FeedbackModal.vue` — new component with Dialog, Textarea, Button, loading state, and API call

## Files to Modify
- `client/src/views/common/components/Header.vue` — add question mark icon (left of avatar) that opens the feedback modal

## Implementation

### 1. Create `FeedbackModal.vue`

Single-file component with template, script, and style in one file.

**Template:**
- `Dialog` with `v-model:open` controlling visibility
- `DialogHeader` with `DialogTitle`: "We love feedback!"
- `DialogDescription`: the description text provided
- `Textarea` with `v-model="message"` and placeholder
- `Button` in `DialogFooter` with loading spinner on submit
- Close button is built into `DialogContent`

**Script:**
- Props: `open` (boolean), `address` (string, optional)
- Emits: `update:open`
- `message` ref for textarea v-model
- `loading` ref for submit state
- `handleSubmit` async function:
  - Set loading true
  - Build payload with `components`, `address`, `message`, `request_type`, `severity`, `url` (from `window.location.href`)
  - Call `APIHelper.AdminAPI.post('/service-desk/tickets', payload)`
  - On success: `toast.success(...)`, reset message, close modal
  - On error: `toast.error(...)`
  - Set loading false in finally block

**Imports:**
- `Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter` from `@/components/ui/dialog`
- `Button` from `@/components/ui/button`
- `Textarea` from `@/components/ui/textarea`
- `toast` from `vue-sonner`
- `APIHelper` from `@archistarai/auth-frontend`
- `Loader2` from `lucide-vue-next` (for spinning loading icon)

### 2. Modify `Header.vue`

- Import `CircleHelp` from `lucide-vue-next`
- Import `FeedbackModal` from `./FeedbackModal.vue`
- Add `showFeedbackModal` ref
- In the right-side div (line 31, `flex items-center gap-4 pr-4`), add before the `<Avatar>`:
  - `<button>` with `CircleHelp` icon, styled to match navbar text color (`currentColor`), with `@click="showFeedbackModal = true"`
- Add `<FeedbackModal v-model:open="showFeedbackModal" :address="submission?.address" />` at end of template
- The `submission` prop is already passed to Header from Home.vue; it's not passed in ProjectsLayout — that's fine, address will be undefined there

## Existing utilities to reuse
- `Dialog` + sub-components from `@/components/ui/dialog` (pattern: `RunCompletenessCheckModal.vue`)
- `Button` from `@/components/ui/button`
- `Textarea` from `@/components/ui/textarea`
- `toast` from `vue-sonner` (already mounted as `<Toaster>` in App.vue)
- `APIHelper.AdminAPI.post()` from `@archistarai/auth-frontend` (pattern: `stores/comments.ts`)

## Verification
1. `bun run build` from `client/` — ensure no type errors
2. `bun run lint` from `client/` — ensure no lint errors
3. Manual testing: open the app in city mode, click the `?` icon in navbar, fill out feedback, submit, verify toast appears
