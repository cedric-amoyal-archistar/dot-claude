# Replace "eCheck" with "AI PreCheck" — user-visible text

## Context
Rebranding user-visible "eCheck" text to "AI PreCheck" across all Vue components. Changing text in both `<template>` sections and JS display strings (labels, titles, tab names). NOT changing variable names, CSS classes, store keys, AuthFeatures keys, API paths, or S3 URLs.

## Files to modify

### 1. `client/src/components/Echeck/ClauseList.vue` (template)
- Line 61: "eCheck report" → "AI PreCheck report"
- Line 200: "eCheck pre-assessment" → "AI PreCheck pre-assessment"
- Line 220: "Download eCheck Compliance Report" → "Download AI PreCheck Compliance Report"
- Line 237: "Summary eCheck Compliance Report" → "Summary AI PreCheck Compliance Report"
- Line 253: "Full eCheck Compliance Report" → "Full AI PreCheck Compliance Report"

### 2. `client/src/components/Profile/ModalUsersManagement.vue` (template + JS)
- Line 123: `placeholder="eCheck Access Level"` → `placeholder="AI PreCheck Access Level"`
- Line 124: `label="eCheck Access Level"` → `label="AI PreCheck Access Level"`
- Line 643: `text: 'eCheck Access Level'` → `text: 'AI PreCheck Access Level'`
- Line 649: `text: 'eCheck Portal Reporting Access'` → `text: 'AI PreCheck Portal Reporting Access'`

### 3. `client/src/components/Profile/ModalUsersManagementUserEdit.vue` (template)
- Line 51: "eCheck Access Level" → "AI PreCheck Access Level"
- Line 70: "eCheck Portal Reporting Access" → "AI PreCheck Portal Reporting Access"

### 4. `client/src/components/Echeck/ConditionCard.vue` (template)
- Line 57: "eCheck report" → "AI PreCheck report"

### 5. `client/src/components/Echeck/SubmissionCard.vue` (template)
- Line 149: "eCheck report" → "AI PreCheck report"

### 6. `client/src/components/Echeck/CreateSubmission/UploadStep.vue` (template)
- Line 32: "eCheck file" → "AI PreCheck file"

### 7. `client/src/components/Echeck/CreateSubmission/UploadStepCustom.vue` (template, commented out)
- Line 32: "eCheck file" → "AI PreCheck file"

### 8. `client/src/components/Echeck/CreateSubmission/UploadStepOld.vue` (template)
- Line 32: "eCheck file" → "AI PreCheck file"

### 9. `client/src/components/Echeck/CreateSubmission/SelectUploadStep.vue` (JS display strings)
- Line 179: `title: 'eCheck File'` → `title: 'AI PreCheck File'`
- Line 182: "design for eCheck" → "design for AI PreCheck"
- Line 183: "Archistar eCheck file" → "Archistar AI PreCheck file"
- Line 190: `label: 'eCheck'` → `label: 'AI PreCheck'`
- Line 220: `label: 'eCheck'` → `label: 'AI PreCheck'`

### 10. `client/src/components/Echeck/FilteredConditionList.vue` (template)
- Line 39: "eCheck report" → "AI PreCheck report"

### 11. `client/src/components/Profile/MyPlan.vue` (template)
- Line 65: "View eCheck Portal" → "View AI PreCheck Portal"

### 12. `client/src/components/Echeck/EcheckStatusDashboard.vue` (template)
- Line 99: "'eCheck Reports'" → "'AI PreCheck Reports'"

### 13. `client/src/components/Echeck/ChooseCertificateType.vue` (template)
- Line 123: "eCheck report" → "AI PreCheck report"

### 14. `client/src/components/Compliance/Wizard/EditSitePropertiesButton.vue` (template)
- Line 29: "re-upload your design into eCheck" → "re-upload your design into AI PreCheck"

### 15. `client/src/components/Search/DashboardRecenteCheckReports.vue` (JS display strings)
- Line 110: `'Recent eCheck Reports and AI Chatbots'` → `'Recent AI PreCheck Reports and AI Chatbots'`
- Line 114: `'Recent eCheck Reports'` → `'Recent AI PreCheck Reports'`

### 16. `client/src/views/Shared/MySites/Table.vue` (template + JS)
- Line 37: `item === 'eCheck Reports'` → `item === 'AI PreCheck Reports'`
- Line 85: `this.parentTabs.indexOf('eCheck Reports')` → `this.parentTabs.indexOf('AI PreCheck Reports')`
- Line 95: `tabs.push('eCheck Reports')` → `tabs.push('AI PreCheck Reports')`

### 17. `client/src/components/Shared/Site/SiteSummary/SummaryEcheck.vue` (JS display string)
- Line 65: `panel['label'] = 'eCheck Reports'` → `panel['label'] = 'AI PreCheck Reports'`

## NOT changing (intentionally excluded)
- **S3 URLs** (e.g., `How+to+use+the+eCheck+template+with+Rhino.pdf`) — external resource paths
- **Variable/method names** (`onEcheckMode`, `hasEcheckMgmtAccess`, `echeckScopeAccessLevel`, etc.)
- **CSS classes** (`platform-ui-floating-panel-echeck`, etc.)
- **Store references** (`$store.state.echeck.*`, `echeck/getCertificatesTypes`, etc.)
- **AuthFeatures keys** (`AuthFeatures['eCheck Submission']`, `AuthFeatures['eCheck Chatbot']`) — backend-defined feature flags
- **Import paths and component names**
- **Internal keys** (`key: 'eCheck-file'` in SelectUploadStep.vue)
- **Route/nav paths** (`/echeckCreateSubmission`, `/site/nav/echeck*`)

## Verification
- Grep all `.vue` files for remaining user-visible "eCheck" text after changes
- Confirm no build errors (text-only changes, no logic affected)
