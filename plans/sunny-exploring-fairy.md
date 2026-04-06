# Make SubmissionSnapshot buttons behave as proper links

## Context
The three action buttons ("View details", "Open Viewer", "Open Submission") in `SubmissionSnapshot.vue` currently use `@click` handlers with `window.open()`. This means they don't behave like real links — no right-click "Open in new tab", no cmd/ctrl+click, no link preview on hover. Vuetify's `v-btn` supports `:to` (Vue Router) and `:href` (external) props which render the button as an `<a>` tag.

## File to modify
- `client/src/components/echeck/dashboard/submissionDetails/SubmissionSnapshot.vue`

## Changes

### 1. "View details" button (line ~636) — internal route, use `:to`
- Replace `@click.exact="goToSubmissionDetails()"` with `:to` and `target="_blank"`
- Use the route object directly: `:to="{ name: 'eCheck Submission Details', params: { region: currentRegion, id: submission.id } }"`
- Add `target="_blank"` to open in new tab

### 2. "Open Viewer" button (line ~649) — external link, use `:href`
- Replace `@click="openViewer()"` with `:href="submission.viewer_link"` and `target="_blank"`

### 3. "Open Submission" button (line ~661) — external link, use `:href`
- Replace `@click="viewInteractiveApplicationAction()"` with a computed href and `target="_blank"`
- Add a computed property `openSubmissionLink` that returns `submission.submission_link` (if status is done) or `submission.submissions_list_link`
- Use `:href="openSubmissionLink"` on the button

### 4. Clean up unused methods
- Remove `goToSubmissionDetails()`, `openViewer()`, `viewInteractiveApplicationAction()`, and `goToLink()` since they're no longer called

## Verification
- Run `bun run lint` to check for unused imports/methods
- Run `bun run type-check` to verify TypeScript
- Manual: confirm buttons render as `<a>` tags, right-click shows "Open in new tab", cmd+click works
