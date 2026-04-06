# Plan: Remove myClaudeMd files from merge request

## Context
5 files from `client/src/myClaudeMd/` were accidentally committed and pushed to the `feature/mobile-view` branch (in commits `9195e4c`, `1387570`, `4b271f5`). A later commit (`5554305`) added `myClaudeMd` to `.gitignore`, but the files are still tracked by git and show up in the MR diff.

## Files to remove from tracking
- `client/src/myClaudeMd/mobileView/CanvaView - Floor Plan and Legend closed.png`
- `client/src/myClaudeMd/mobileView/CanvaView - Floor Plan open and Legend Closed.png`
- `client/src/myClaudeMd/mobileView/CanvaView- Legend Open and Floor Plan Closed.png`
- `client/src/myClaudeMd/mobileView/PanelView.png`
- `client/src/myClaudeMd/mobileView/mobileView.md`

## Steps

1. **Run `git rm --cached -r client/src/myClaudeMd/`** — removes the files from git's index (tracking) but keeps them on disk locally.
2. **Commit** with message: `chore: remove myClaudeMd files from git tracking`
3. **Push** to the remote branch.

Since these files don't exist on `master`, removing them from tracking means the MR diff will show no net change for them (added then deleted = nothing).

## Verification
- Run `git diff master...HEAD --name-only | grep claudemd` — should return nothing.
- Check the MR on GitLab to confirm the files no longer appear in the diff.
