# Plan: Replace "eCheck" with "AI PreCheck" in HTML display text

## Context
Rebrand "eCheck" to "AI PreCheck" across all Vue component and view templates. Only visible display text (headings, labels, button text, placeholders, table headers) will be changed. Route names in `router.push()`, `:to` bindings, and `@click` handlers will be left untouched since they are functional identifiers tied to router definitions.

## Files to modify (display text only)

### Components
1. **`client/src/components/echeck/dashboard/submissionDetails/SubmissionSnapshot.vue`**
   - Lines 351, 361: "eCheck Report" → "AI PreCheck Report"

### Views - echeck
2. **`client/src/views/echeck/SubmissionDifferOld.vue`**
   - Line 273: "eCheck Submission Differ" → "AI PreCheck Submission Differ"

3. **`client/src/views/echeck/SubmissionDetails.vue`**
   - Line 569: "eCheck Report" → "AI PreCheck Report"

4. **`client/src/views/echeck/DashboardHome.vue`**
   - Line 55: "View All eCheck Reports" → "View All AI PreCheck Reports"

5. **`client/src/views/echeck/DesignCheckDetails.vue`**
   - Line 186: "eCheck Design Check Details" → "AI PreCheck Design Check Details"

6. **`client/src/views/echeck/SubmissionDiffer.vue`**
   - Line 262: "eCheck Submission Differ" → "AI PreCheck Submission Differ"

### Views - cities
7. **`client/src/views/cities/CitiesDashboard.vue`**
   - Line 397: title: 'eCheck' → title: 'AI PreCheck'

### Views - configuration
8. **`client/src/views/configuration/ConfigurationHome.vue`**
   - Line 143: "eCheck Netcore Mgmt - Library Versions" → "AI PreCheck Netcore Mgmt - Library Versions"

### Views - reports
9. **`client/src/views/reports/ReportHome.vue`**
   - Line 52: section heading "eCheck" → "AI PreCheck"
   - Line 61: "eCheck Reports List" → "AI PreCheck Reports List"
   - Line 71: "eCheck Excluded Reports List" → "AI PreCheck Excluded Reports List"
   - Line 81: "eCheck Submissions Processing Stats" → "AI PreCheck Submissions Processing Stats"
   - Line 90: "eCheck AI Chatbots List" → "AI PreCheck AI Chatbots List"
   - Line 93: comment "eCheck Reports Counts" → "AI PreCheck Reports Counts"
   - Line 116: "eCheck Insights" → "AI PreCheck Insights"
   - Line 132: "eCheck Adoption" → "AI PreCheck Adoption"

10. **`client/src/views/reports/echeck/SubmissionsReport.vue`**
    - Line 789: "eCheck Excluded Reports" → "AI PreCheck Excluded Reports"
    - Line 790: "eCheck AI Chatbots" → "AI PreCheck AI Chatbots"
    - Line 791: "eCheck Reports" → "AI PreCheck Reports"

11. **`client/src/views/reports/echeck/SubmissionsProcessingStats.vue`**
    - Line 576: "eCheck Submission Processing Stats" → "AI PreCheck Submission Processing Stats"

12. **`client/src/views/reports/echeck/ClauseReport.vue`**
    - Line 291: "eCheck Insights" → "AI PreCheck Insights"
    - Line 316: placeholder "Select an eCheck Report" → "Select an AI PreCheck Report"
    - Line 317: label "eCheck Report" → "AI PreCheck Report"

13. **`client/src/views/reports/echeck/DesignChecksReport.vue`**
    - Line 527: "eCheck Design Checks" → "AI PreCheck Design Checks"

14. **`client/src/views/reports/echeck/adoption/AdoptionReport.vue`**
    - Line 27: "eCheck Adoption" → "AI PreCheck Adoption"

15. **`client/src/views/reports/echeck/ProjectsReport.vue`**
    - Line 437: "eCheck Project" → "AI PreCheck Project"

16. **`client/src/views/reports/echeck/FeedbacksList.vue`**
    - Line 622: "eCheck Feedbacks" → "AI PreCheck Feedbacks"

## What will NOT be changed
- Route names in `router.push()`, `:to`, `@click` handlers (e.g., `name: 'eCheck Submissions Report'`)
- Script/logic sections
- Router definitions in `router/index.ts`
- Store names, variable names, file names

## Verification
- Run `bun run type-check` from `/client` to verify no TypeScript errors
- Run `bun run lint` from `/client` to verify no lint errors
- Grep for remaining "eCheck" in templates to confirm only route names remain
