# Virus Check on File Upload

## Context
Currently, files are added to `selectedFiles` via `addFile()`, then all S3 uploads happen in bulk inside `createSubmission()` via `Promise.all()`. We want to upload each file to S3 **immediately when added** and run a virus check via polling before the file is considered ready. This gives earlier feedback and prevents infected files from reaching submission.

## New Flow (per file, triggered on add)
1. User selects file → validation → `addFile()` adds file to store with `uploadStatus: 'uploading'`
2. Upload to S3 (existing logic: POST `/design-upload-url` → `uploadFileToS3()`)
3. Set `uploadStatus: 'scanning'`, poll `GET /design-checks/design-upload-status?awsKey={s3_key}`
4. **Success** (`response.data.status === 'success'`): set `awsKey` + `uploadStatus: 'done'`
5. **Failure** (infected or timeout): remove file from store, show error toast

---

## Changes

### 1. Store — `client/src/store/modules/echeckUpload.store.ts`
- Extend `ADD_SELECTED_FILE` to include `uploadStatus: 'uploading'` and `awsKey: ''` in initial object
- Add mutation `UPDATE_FILE_UPLOAD_STATUS(state, { key, uploadStatus })` — finds file by key, sets `uploadStatus`
- Add mutation `UPDATE_FILE_AWS_KEY(state, { key, awsKey })` — finds file by key, sets `awsKey`

### 2. Upload component — `client/src/components/Echeck/CreateSubmission/UploadCustom.vue`
- Import `APIHelper` from `@archistarai/auth-frontend`, `Poll` class from `@/classes/Utilities/Global/Poll`, `Notify`/`NotifyType` from `@/classes/Notify`
- Move `uploadFileToS3()` method from `UploadStepCustom.vue` into this component
- In `addFile()`: after store commit, call new async method `uploadAndScanFile(fileKey)`
- New method `uploadAndScanFile(fileKey: string)`:
  ```
  try {
    1. Get file object from store by key
    2. POST /design-upload-url → get signed URL
    3. uploadFileToS3(file.file, response.data) → get s3_key
    4. Commit UPDATE_FILE_UPLOAD_STATUS → 'scanning'
    5. Create Poll instance, poll GET /design-checks/design-upload-status?awsKey={s3_key}
       - validate: response.data.status === 'success'
       - interval: 3000, maxAttempts: 50
    6. On resolve: commit UPDATE_FILE_AWS_KEY + UPDATE_FILE_UPLOAD_STATUS → 'done'
  } catch {
    Commit REMOVE_SELECTED_FILE
    Notify.show('File "{name}" failed the security check and has been removed.', NotifyType.error)
  }
  ```

### 3. Parent component — `client/src/components/Echeck/CreateSubmission/UploadStepCustom.vue`
- **Remove** the `Promise.all()` block (lines 322-340) from `createSubmission()`
- **Remove** `uploadFileToS3()` method (lines 290-313) — moved to UploadCustom.vue
- Update `createSubmissionDisabled` computed: add check that no file has `uploadStatus !== 'done'` (all files must be fully uploaded and scanned)

### 4. File list — `client/src/components/Echeck/CreateSubmission/UploadStepCustomFileList.vue`
- Next to each file's name/size, show upload status when not `'done'`:
  - `uploadStatus === 'uploading'` → show spinner + "Uploading..."
  - `uploadStatus === 'scanning'` → show spinner + "Scanning..."
- Use `ai-progress-circular` (or a simple CSS spinner) for the loading indicator
- Disable the remove button while a file is uploading/scanning (optional — or allow cancellation)

---

## Verification
1. Upload a file → confirm it uploads to S3 immediately, file list shows "Uploading..." then "Scanning..."
2. Confirm network tab shows polling to `/design-checks/design-upload-status?awsKey=...`
3. On scan success: file shows as ready (no spinner), awsKey is set on the file object
4. On scan failure: file is removed from list, error toast appears
5. "Submit for Processing" button stays disabled while any file is uploading/scanning
6. Submit works correctly — payload built from awsKeys already set on files, no duplicate S3 uploads
