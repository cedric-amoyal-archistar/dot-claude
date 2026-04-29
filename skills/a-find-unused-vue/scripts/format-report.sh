#!/usr/bin/env bash
# find-unused-vue/scripts/format-report.sh
#
# Reads knip JSON from $1, prints human-readable markdown to stdout.
# Sanitizes file paths (drops anything with control chars), groups by
# top-level directory, and caps output at MAX_FILES with a truncation
# notice.
#
# For each candidate, runs a basename cross-reference grep against the
# project source tree. Files whose basename appears nowhere outside
# their own definition are reported as "high confidence unused".
# Files whose basename appears as a string elsewhere are bucketed as
# "needs review" (likely string-ref / dynamic-import false positives).

set -euo pipefail
IFS=$'\n\t'

JSON_FILE="${1:?missing knip JSON path}"
PROJECT_NAME="${2:-project}"
PROJECT_TYPE="${3:-Vue.js}"
PROJECT_ROOT="${4:-$PWD}"

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

FILES=()
if [[ -n "$SAFE_FILES" ]]; then
    while IFS= read -r line; do
        FILES+=("$line")
    done <<< "$SAFE_FILES"
fi

TOTAL=${#FILES[@]}

TRUNCATED=0
if (( TOTAL > MAX_FILES )); then
    FILES=("${FILES[@]:0:$MAX_FILES}")
    TRUNCATED=1
fi

# ============================================================
# Basename cross-reference
# ============================================================
# For each candidate, derive a "useful basename" and grep the project
# for it. If the basename appears as a whole word anywhere outside the
# candidate file itself, the candidate is bucketed as "needs review".
# Otherwise it's "high confidence unused".
basename_no_ext() {
    local f="$1"
    local b="${f##*/}"
    if [[ "$b" == *.d.ts ]]; then
        b="${b%.d.ts}"
    else
        b="${b%.*}"
    fi
    # `index.ts` / `index.vue` are too generic — fall back to parent dir name.
    if [[ "$b" == "index" ]]; then
        local parent="${f%/*}"
        parent="${parent##*/}"
        [[ -n "$parent" && "$parent" != "$f" ]] && b="$parent"
    fi
    printf '%s' "$b"
}

HIGH_CONFIDENCE=()
NEEDS_REVIEW=()
NEEDS_REVIEW_HITS=()  # parallel to NEEDS_REVIEW; pipe-separated rel paths

if (( TOTAL > 0 )) && [[ -d "$PROJECT_ROOT" ]]; then
    for f in "${FILES[@]}"; do
        bn=$(basename_no_ext "$f")
        self_abs="$PROJECT_ROOT/$f"

        # Names shorter than 3 chars are too generic to grep safely.
        if [[ ${#bn} -lt 3 ]]; then
            NEEDS_REVIEW+=("$f")
            NEEDS_REVIEW_HITS+=("(basename '$bn' too short — review manually)")
            continue
        fi

        hits=$(grep -rwlF \
            --include='*.ts' --include='*.tsx' \
            --include='*.js' --include='*.jsx' --include='*.mjs' --include='*.cjs' \
            --include='*.vue' --include='*.json' --include='*.html' \
            --exclude-dir=node_modules --exclude-dir=dist --exclude-dir=.nuxt \
            --exclude-dir=.output --exclude-dir=build --exclude-dir=coverage \
            --exclude-dir=.git --exclude-dir=.cache --exclude-dir=.vite \
            -- "$bn" "$PROJECT_ROOT" 2>/dev/null \
            | grep -v -F -x -- "$self_abs" \
            | head -3 \
            || true)

        if [[ -n "$hits" ]]; then
            # Convert absolute hit paths to project-relative for display.
            relhits=$(printf '%s\n' "$hits" | sed "s|^${PROJECT_ROOT}/||" | tr '\n' '|' | sed 's/|$//')
            NEEDS_REVIEW+=("$f")
            NEEDS_REVIEW_HITS+=("$relhits")
        else
            HIGH_CONFIDENCE+=("$f")
        fi
    done
else
    # No project root or no candidates — fall back to all-needs-review.
    for f in "${FILES[@]}"; do
        NEEDS_REVIEW+=("$f")
        NEEDS_REVIEW_HITS+=("(skipped basename check)")
    done
fi

HC_TOTAL=${#HIGH_CONFIDENCE[@]}
NR_TOTAL=${#NEEDS_REVIEW[@]}

# ============================================================
# Render report
# ============================================================
print_grouped() {
    # $1 = array name (eval'd via indirection) — bash 3.2 compatible
    local arr_name="$1"
    eval "local items=(\"\${${arr_name}[@]}\")"
    local current_dir=""
    local f dir
    for f in "${items[@]}"; do
        if [[ "$f" == */* ]]; then
            dir="${f%%/*}"
        else
            dir="(root)"
        fi
        if [[ "$dir" != "$current_dir" ]]; then
            [[ -n "$current_dir" ]] && printf '\n'
            printf '#### `%s/`\n\n' "$dir"
            current_dir="$dir"
        fi
        printf -- '- `%s`\n' "$f"
    done
    printf '\n'
}

printf '# Vue Dead-Code Scan Report\n\n'
printf '**Project:** %s (%s)\n' "$PROJECT_NAME" "$PROJECT_TYPE"
printf '**Tool:** vendored knip + basename cross-reference\n'
printf '**Unused files detected:** %d (high confidence: %d, needs review: %d)\n\n' \
    "$TOTAL" "$HC_TOTAL" "$NR_TOTAL"

if (( TOTAL == 0 )); then
    printf 'No unused files detected. (False-positive disclaimers below still apply.)\n\n'
fi

if (( HC_TOTAL > 0 )); then
    printf '## High-confidence unused (%d)\n\n' "$HC_TOTAL"
    printf 'Knip flagged these and the basename appears nowhere else in the source tree.\n\n'
    print_grouped HIGH_CONFIDENCE
fi

if (( NR_TOTAL > 0 )); then
    printf '## Needs review (%d)\n\n' "$NR_TOTAL"
    printf 'Knip flagged these, but the basename was found as a whole-word string in other files. Likely runtime/dynamic refs (`<component :is="X">`, `app.component('"'"'X'"'"', ...)`, route configs, dynamic imports). Showing up to 3 hit files per candidate.\n\n'
    i=0
    while (( i < NR_TOTAL )); do
        f="${NEEDS_REVIEW[$i]}"
        h="${NEEDS_REVIEW_HITS[$i]}"
        printf -- '- `%s`\n' "$f"
        # Split hits on `|` and print each indented.
        IFS='|' read -r -a hit_arr <<< "$h"
        for hh in "${hit_arr[@]}"; do
            [[ -n "$hh" ]] && printf -- '    - found in `%s`\n' "$hh"
        done
        i=$((i + 1))
    done
    printf '\n'
fi

if (( TRUNCATED )); then
    printf '_Output truncated to %d files. The full list is longer; consider grouping by directory and reviewing in batches._\n\n' "$MAX_FILES"
fi

cat <<'DISCLAIMER'
## Known false-positive categories (review before deleting)

- Files matched only by `import.meta.glob` lazy patterns may appear here.
- `<component :is="...">` runtime string refs are statically undetectable.
- `app.component('Name', X)` global registration: the file may show as unused if its only references are via the runtime string name.
- Pinia stores accessed only via `useStore()` with no direct import.
- Nuxt auto-import conventions outside the standard directories (`pages/`, `components/`, `composables/`, `layouts/`, `middleware/`, `plugins/`, `utils/`, `server/`, `stores/`).
- Template-string paths (e.g. `` `./components/${name}.vue` ``) defeat basename grep entirely.

The basename cross-reference catches most of the first three categories. The "high-confidence" bucket is **much** safer to delete from, but the disclaimer above still applies — **always grep the filename basename across the repo before deleting**.
DISCLAIMER
