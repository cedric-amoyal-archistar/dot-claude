#!/usr/bin/env bash
# find-unused-vue/scripts/format-report.sh
#
# Reads knip JSON from $1, prints human-readable markdown to stdout.
# Sanitizes file paths (drops anything with control chars), groups by
# top-level directory, and caps output at MAX_FILES with a truncation
# notice.

set -euo pipefail
IFS=$'\n\t'

JSON_FILE="${1:?missing knip JSON path}"
PROJECT_NAME="${2:-project}"
PROJECT_TYPE="${3:-Vue.js}"

MAX_FILES=500

# Knip JSON schemas vary across versions. Try the modern shape
# (`{files: [...], issues: [...]}`) first, fall back to issue-array shape.
RAW_FILES=$(jq -r '
    if type == "object" and has("files") then .files
    elif type == "array" then [.[] | (.file // empty)]
    else []
    end
    | map(select(type == "string"))
    | unique
    | .[]
' "$JSON_FILE" 2>/dev/null || true)

# Drop any line containing control chars or non-printable bytes.
if [[ -n "$RAW_FILES" ]]; then
    SAFE_FILES=$(printf '%s\n' "$RAW_FILES" | LC_ALL=C grep -E '^[[:print:]]+$' || true)
else
    SAFE_FILES=""
fi

if [[ -z "$SAFE_FILES" ]]; then
    FILES=()
else
    mapfile -t FILES <<< "$SAFE_FILES"
fi

TOTAL=${#FILES[@]}

TRUNCATED=0
if (( TOTAL > MAX_FILES )); then
    FILES=("${FILES[@]:0:$MAX_FILES}")
    TRUNCATED=1
fi

printf '# Vue Dead-Code Scan Report\n\n'
printf '**Project:** %s (%s)\n' "$PROJECT_NAME" "$PROJECT_TYPE"
printf '**Tool:** vendored knip\n'
printf '**Unused files detected:** %d\n\n' "$TOTAL"

if (( TOTAL == 0 )); then
    printf 'No unused files detected. (False-positive disclaimers below still apply.)\n\n'
else
    printf '## Likely unused\n\n'
    current_dir=""
    for f in "${FILES[@]}"; do
        if [[ "$f" == */* ]]; then
            dir="${f%%/*}"
        else
            dir="(root)"
        fi
        if [[ "$dir" != "$current_dir" ]]; then
            [[ -n "$current_dir" ]] && printf '\n'
            printf '### `%s/`\n\n' "$dir"
            current_dir="$dir"
        fi
        printf -- '- `%s`\n' "$f"
    done
    printf '\n'
    if (( TRUNCATED )); then
        printf '_Output truncated to %d files. The full list is longer; consider grouping by directory and reviewing in batches._\n\n' "$MAX_FILES"
    fi
fi

cat <<'DISCLAIMER'
## Known false-positive categories (review before deleting)

- Files matched only by `import.meta.glob` lazy patterns may appear here.
- `<component :is="...">` runtime string refs are statically undetectable.
- `app.component('Name', X)` global registration: the file may show as unused if its only references are via the runtime string name.
- Pinia stores accessed only via `useStore()` with no direct import.
- Nuxt auto-import conventions outside the standard directories (`pages/`, `components/`, `composables/`, `layouts/`, `middleware/`, `plugins/`, `utils/`, `server/`, `stores/`).

**Always grep for the filename basename across the repo before deleting.**
DISCLAIMER
