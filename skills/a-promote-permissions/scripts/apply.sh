#!/usr/bin/env bash
# promote-permissions/scripts/apply.sh
#
# Phase 2: read .last-plan.json, re-verify source mtimes (abort on drift),
# back up all affected files, atomically write the planned changes,
# append rationale to permissions.md.

set -euo pipefail
IFS=$'\n\t'

SKILL_ROOT="/Users/cedricamoyal/.claude/skills/a-promote-permissions"
GLOBAL_SETTINGS="$HOME/.claude/settings.json"
PERMISSIONS_DOC="$HOME/.claude/permissions.md"
PLAN_FILE="$SKILL_ROOT/.last-plan.json"
BACKUP_BASE="$HOME/.claude/backups/promote-permissions"

# ============================================================
# Helpers
# ============================================================
fatal() {
    printf 'promote-permissions: %s\n' "$1" >&2
    printf 'promote-permissions: %s\n' "$1"
    exit 2
}

stat_mtime() {
    stat -f "%m" "$1" 2>/dev/null || stat -c "%Y" "$1"
}

# ============================================================
# Preflight
# ============================================================
[[ "$PWD" == "/Users/cedricamoyal/.claude" ]] || \
    fatal "must be run from /Users/cedricamoyal/.claude (current PWD: $PWD)"

command -v jq >/dev/null 2>&1 || fatal "jq not on PATH"

[[ -f "$PLAN_FILE" ]] || fatal "no plan found at $PLAN_FILE — run plan.sh first"
jq -e . "$PLAN_FILE" >/dev/null 2>&1 || fatal "plan file is not valid JSON"

[[ -f "$GLOBAL_SETTINGS" ]] || fatal "global settings missing: $GLOBAL_SETTINGS"

# ============================================================
# Re-verify source mtimes (abort on drift)
# ============================================================
drift_detected=0
while IFS=$'\t' read -r path expected_mtime exists_str; do
    if [[ "$exists_str" == "true" ]]; then
        if [[ ! -f "$path" ]]; then
            echo "DRIFT: $path no longer exists (was present at plan time)" >&2
            drift_detected=1
            continue
        fi
        current_mtime=$(stat_mtime "$path")
        if [[ "$current_mtime" != "$expected_mtime" ]]; then
            echo "DRIFT: $path mtime changed ($expected_mtime → $current_mtime)" >&2
            drift_detected=1
        fi
    else
        if [[ -f "$path" ]]; then
            echo "DRIFT: $path now exists (was absent at plan time)" >&2
            drift_detected=1
        fi
    fi
done < <(jq -r '.sources[] | "\(.path)\t\(.mtime)\t\(.exists)"' "$PLAN_FILE")

# Global settings drift
expected_global_mtime=$(jq -r '.global_settings.mtime' "$PLAN_FILE")
current_global_mtime=$(stat_mtime "$GLOBAL_SETTINGS")
if [[ "$current_global_mtime" != "$expected_global_mtime" ]]; then
    echo "DRIFT: global settings mtime changed ($expected_global_mtime → $current_global_mtime)" >&2
    drift_detected=1
fi

if (( drift_detected != 0 )); then
    fatal "one or more source files changed since plan — re-run plan.sh first"
fi

# ============================================================
# Backup
# ============================================================
TIMESTAMP=$(date -u +%Y%m%d-%H%M%S)
BACKUP_DIR="$BACKUP_BASE/$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

cp "$GLOBAL_SETTINGS" "$BACKUP_DIR/settings.json"
[[ -f "$PERMISSIONS_DOC" ]] && cp "$PERMISSIONS_DOC" "$BACKUP_DIR/permissions.md"

while IFS=$'\t' read -r label path; do
    if [[ -f "$path" ]]; then
        # Use a flat name with the label
        safe_label=$(tr -c '[:alnum:]' '_' <<< "$label" | sed 's/_*$//')
        cp "$path" "$BACKUP_DIR/source__${safe_label}.json"
    fi
done < <(jq -r '.sources[] | select(.exists == true) | "\(.label)\t\(.path)"' "$PLAN_FILE")

# ============================================================
# Build new contents in staging dir
# ============================================================
STAGE_DIR=$(mktemp -d "$HOME/.claude/.tmp.XXXXXX")
trap 'rm -rf "$STAGE_DIR"' EXIT

# 1. New global settings.json: existing + new additions, deduped, deny untouched
new_global="$STAGE_DIR/settings.json"
jq --argjson plan "$(cat "$PLAN_FILE")" '
    .permissions.allow as $existing
    | ($plan.global_additions | map(.entry) | map(select(. as $e | $existing | index($e) == null))) as $new_entries
    | .permissions.allow += $new_entries
' "$GLOBAL_SETTINGS" > "$new_global"

# Verify it's still valid JSON and preserve key ordering reasonably
jq -e . "$new_global" >/dev/null || fatal "new global settings.json failed JSON validation"

# 2. New per-source files: replace permissions.allow with the `after` array
n_sources=$(jq '.sources | length' "$PLAN_FILE")
declare -a STAGED_PATHS=()
declare -a TARGET_PATHS=()
for ((i = 0; i < n_sources; i++)); do
    exists=$(jq -r ".sources[$i].exists" "$PLAN_FILE")
    [[ "$exists" == "true" ]] || continue

    path=$(jq -r ".sources[$i].path" "$PLAN_FILE")
    after=$(jq -c ".sources[$i].after" "$PLAN_FILE")

    staged="$STAGE_DIR/source_${i}.json"
    jq --argjson after "$after" '.permissions.allow = $after' "$path" > "$staged"
    jq -e . "$staged" >/dev/null || fatal "rebuilt JSON invalid: $path"

    STAGED_PATHS+=("$staged")
    TARGET_PATHS+=("$path")
done

# ============================================================
# Atomic moves
# ============================================================
mv "$new_global" "$GLOBAL_SETTINGS"

for ((i = 0; i < ${#STAGED_PATHS[@]}; i++)); do
    mv "${STAGED_PATHS[$i]}" "${TARGET_PATHS[$i]}"
done

# ============================================================
# Append rationale to permissions.md
# ============================================================
n_additions=$(jq '.global_additions | length' "$PLAN_FILE")
if (( n_additions > 0 )) && [[ -f "$PERMISSIONS_DOC" ]]; then
    {
        echo
        echo "---"
        echo
        echo "## Promoted via promote-permissions skill ($TIMESTAMP)"
        echo
        jq -r '.global_additions[] | "- `\(.entry)` — \(.rationale) (sourced from: \(.sources))"' "$PLAN_FILE"
    } >> "$PERMISSIONS_DOC"
fi

# ============================================================
# Print summary
# ============================================================
echo "# Permission Audit — Applied"
echo
echo "**Timestamp:** $TIMESTAMP"
echo "**Backups:** \`$BACKUP_DIR\`"
echo
echo "## Changes"
echo
echo "- Global \`~/.claude/settings.json\`: +$n_additions allow entries"
if (( n_additions > 0 )); then
    jq -r '.global_additions[] | "  - `\(.entry)`"' "$PLAN_FILE"
fi
echo
echo "## Project files"
echo
for ((i = 0; i < n_sources; i++)); do
    label=$(jq -r ".sources[$i].label" "$PLAN_FILE")
    exists=$(jq -r ".sources[$i].exists" "$PLAN_FILE")
    if [[ "$exists" != "true" ]]; then
        echo "- \`$label\`: skipped (file does not exist)"
        continue
    fi
    before_n=$(jq ".sources[$i].before | length" "$PLAN_FILE")
    after_n=$(jq ".sources[$i].after | length" "$PLAN_FILE")
    echo "- \`$label\`: $before_n → $after_n entries"
done
echo
echo "## To roll back"
echo
echo "\`\`\`"
echo "cp $BACKUP_DIR/settings.json $GLOBAL_SETTINGS"
echo "# Restore each source from $BACKUP_DIR/source__*.json (filenames sanitized from labels)"
echo "\`\`\`"
echo
echo "Run \`git status\` and \`git diff\` to review the changes. Skill does NOT commit."

# Clear the plan file — forces a fresh plan for the next run
rm -f "$PLAN_FILE"
