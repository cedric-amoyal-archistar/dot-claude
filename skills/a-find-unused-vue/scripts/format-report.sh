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
# Basename / path-suffix cross-reference
# ============================================================
# For each candidate, derive a "useful basename" and grep the project
# for it. If the basename appears as a whole word anywhere outside the
# candidate file itself, the candidate is bucketed as "needs review".
# Otherwise it's "high confidence unused".
#
# When multiple project files share the same basename (e.g. a refactor
# left two `Foo.vue` files in different directories), basename grep is
# ambiguous: a hit could reference either sibling. In that case, switch
# to a path-suffix grep for the shortest unique trailing path segments
# of this candidate (e.g. `customisationsCityDetails/Foo`). Also fall
# back to a basename grep that excludes hits inside sibling files, so
# template-only usages (`<Foo />`) still surface as ambiguous rather
# than slipping into the high-confidence bucket.
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

# Strip the recognised source extensions, .d.ts first.
strip_source_ext() {
    local p="$1"
    case "$p" in
        *.d.ts) printf '%s' "${p%.d.ts}" ;;
        *.vue|*.tsx|*.ts|*.jsx|*.js|*.mjs|*.cjs) printf '%s' "${p%.*}" ;;
        *) printf '%s' "$p" ;;
    esac
}

# Last $2 path segments of $1 (joined with '/').
path_suffix() {
    local path="$1"
    local depth="$2"
    awk -F'/' -v d="$depth" '{
        n = NF
        if (d > n) d = n
        out = ""
        for (i = n - d + 1; i <= n; i++) {
            if (out == "") out = $i
            else out = out "/" $i
        }
        print out
    }' <<< "$path"
}

# Shortest path suffix of $1 (without extension) that does not also match
# any sibling in "$@" (also without extension). Falls back to the full
# extensionless path if no unique prefix exists within max_depth segments.
shortest_unique_suffix() {
    local self_no_ext="$1"; shift
    local sibs_no_ext=("$@")

    local max_depth
    max_depth=$(awk -F'/' '{print NF}' <<< "$self_no_ext")
    (( max_depth < 2 )) && max_depth=2

    local depth=2 suffix sib o_suffix conflict
    while (( depth <= max_depth )); do
        suffix=$(path_suffix "$self_no_ext" "$depth")
        conflict=0
        for sib in "${sibs_no_ext[@]}"; do
            o_suffix=$(path_suffix "$sib" "$depth")
            if [[ "$o_suffix" == "$suffix" ]]; then
                conflict=1
                break
            fi
        done
        if (( conflict == 0 )); then
            printf '%s' "$suffix"
            return 0
        fi
        depth=$((depth + 1))
    done
    printf '%s' "$self_no_ext"
}

# Shared grep flags for source-file scans.
SRC_GREP_FLAGS=(
    --include='*.ts' --include='*.tsx'
    --include='*.js' --include='*.jsx' --include='*.mjs' --include='*.cjs'
    --include='*.vue' --include='*.json' --include='*.html'
    --exclude-dir=node_modules --exclude-dir=dist --exclude-dir=.nuxt
    --exclude-dir=.output --exclude-dir=build --exclude-dir=coverage
    --exclude-dir=.git --exclude-dir=.cache --exclude-dir=.vite
)

HIGH_CONFIDENCE=()
NEEDS_REVIEW=()
NEEDS_REVIEW_HITS=()   # parallel to NEEDS_REVIEW; pipe-separated rel paths
NEEDS_REVIEW_NOTES=()  # parallel to NEEDS_REVIEW; optional explanation suffix

if (( TOTAL > 0 )) && [[ -d "$PROJECT_ROOT" ]]; then
    # Pre-scan all source files in the project once. Used to find
    # same-basename siblings without spawning find per candidate.
    ALL_SOURCE_FILES=$(find "$PROJECT_ROOT" \
        \( -path "$PROJECT_ROOT/node_modules" -o -path "$PROJECT_ROOT/dist" \
           -o -path "$PROJECT_ROOT/.nuxt" -o -path "$PROJECT_ROOT/.output" \
           -o -path "$PROJECT_ROOT/build" -o -path "$PROJECT_ROOT/coverage" \
           -o -path "$PROJECT_ROOT/.git" -o -path "$PROJECT_ROOT/.cache" \
           -o -path "$PROJECT_ROOT/.vite" \) -prune -o \
        -type f \( -name '*.vue' -o -name '*.ts' -o -name '*.tsx' \
                  -o -name '*.js' -o -name '*.jsx' -o -name '*.mjs' \
                  -o -name '*.cjs' -o -name '*.d.ts' \) -print 2>/dev/null \
        || true)

    for f in "${FILES[@]}"; do
        bn=$(basename_no_ext "$f")
        self_abs="$PROJECT_ROOT/$f"

        # Names shorter than 3 chars are too generic to grep safely.
        if [[ ${#bn} -lt 3 ]]; then
            NEEDS_REVIEW+=("$f")
            NEEDS_REVIEW_HITS+=("")
            NEEDS_REVIEW_NOTES+=("basename '$bn' too short — review manually")
            continue
        fi

        # Find sibling files (same basename, different path) anywhere in
        # the project source tree — not just in the unused-files list.
        siblings_abs=()
        if [[ -n "$ALL_SOURCE_FILES" ]]; then
            same_bn=$(printf '%s\n' "$ALL_SOURCE_FILES" \
                | grep -E "/${bn}\.(vue|ts|tsx|js|jsx|mjs|cjs|d\.ts)\$" \
                || true)
            if [[ -n "$same_bn" ]]; then
                while IFS= read -r line; do
                    [[ -z "$line" || "$line" == "$self_abs" ]] && continue
                    siblings_abs+=("$line")
                done <<< "$same_bn"
            fi
        fi

        if (( ${#siblings_abs[@]} == 0 )); then
            # Unique basename in the project — original fast path.
            hits=$(grep -rwlF "${SRC_GREP_FLAGS[@]}" \
                -- "$bn" "$PROJECT_ROOT" 2>/dev/null \
                | grep -v -F -x -- "$self_abs" \
                | head -3 \
                || true)

            if [[ -n "$hits" ]]; then
                relhits=$(printf '%s\n' "$hits" | sed "s|^${PROJECT_ROOT}/||" | tr '\n' '|' | sed 's/|$//')
                NEEDS_REVIEW+=("$f")
                NEEDS_REVIEW_HITS+=("$relhits")
                NEEDS_REVIEW_NOTES+=("")
            else
                HIGH_CONFIDENCE+=("$f")
            fi
            continue
        fi

        # Multiple files share this basename — disambiguate by path suffix.
        self_no_ext=$(strip_source_ext "$f")
        sibs_no_ext=()
        for sib in "${siblings_abs[@]}"; do
            sib_rel="${sib#${PROJECT_ROOT}/}"
            sibs_no_ext+=("$(strip_source_ext "$sib_rel")")
        done
        suffix=$(shortest_unique_suffix "$self_no_ext" "${sibs_no_ext[@]}")

        # Build a -v filter that drops hits inside self and any siblings;
        # those files trivially mention their own basename / path suffix.
        exclude_flags=(-v -F -x -e "$self_abs")
        for sib in "${siblings_abs[@]}"; do
            exclude_flags+=(-e "$sib")
        done

        suffix_hits=$(grep -rwlF "${SRC_GREP_FLAGS[@]}" \
            -- "$suffix" "$PROJECT_ROOT" 2>/dev/null \
            | grep "${exclude_flags[@]}" \
            | head -3 \
            || true)

        if [[ -n "$suffix_hits" ]]; then
            relhits=$(printf '%s\n' "$suffix_hits" | sed "s|^${PROJECT_ROOT}/||" | tr '\n' '|' | sed 's/|$//')
            NEEDS_REVIEW+=("$f")
            NEEDS_REVIEW_HITS+=("$relhits")
            NEEDS_REVIEW_NOTES+=("matched on path '$suffix' (disambiguated from ${#siblings_abs[@]} same-basename sibling(s))")
            continue
        fi

        # No path-import hit. Look at all basename hits and decide if they
        # are *explained* by a sibling import — i.e. each consumer file
        # also references a sibling by its own unique path suffix. If yes,
        # the candidate is truly unused (HC). If any hit is unexplained,
        # something else (template tag, dynamic ref) might point at us, so
        # surface it as ambiguous needs-review.
        sib_suffixes=()
        for sib_no_ext in "${sibs_no_ext[@]}"; do
            others_for_sib=("$self_no_ext")
            for other_no_ext in "${sibs_no_ext[@]}"; do
                [[ "$other_no_ext" != "$sib_no_ext" ]] && others_for_sib+=("$other_no_ext")
            done
            sib_suffixes+=("$(shortest_unique_suffix "$sib_no_ext" "${others_for_sib[@]}")")
        done

        bn_hits=$(grep -rwlF "${SRC_GREP_FLAGS[@]}" \
            -- "$bn" "$PROJECT_ROOT" 2>/dev/null \
            | grep "${exclude_flags[@]}" \
            || true)

        if [[ -z "$bn_hits" ]]; then
            HIGH_CONFIDENCE+=("$f")
            continue
        fi

        unexplained_hits=()
        while IFS= read -r hit_file; do
            [[ -z "$hit_file" ]] && continue
            explained=0
            for sib_suffix in "${sib_suffixes[@]}"; do
                if grep -wF -q -- "$sib_suffix" "$hit_file" 2>/dev/null; then
                    explained=1
                    break
                fi
            done
            (( explained == 0 )) && unexplained_hits+=("$hit_file")
        done <<< "$bn_hits"

        if (( ${#unexplained_hits[@]} == 0 )); then
            # Every basename hit imports a sibling — this file is truly unused.
            HIGH_CONFIDENCE+=("$f")
        else
            relhits=$(printf '%s\n' "${unexplained_hits[@]}" | head -3 \
                | sed "s|^${PROJECT_ROOT}/||" | tr '\n' '|' | sed 's/|$//')
            NEEDS_REVIEW+=("$f")
            NEEDS_REVIEW_HITS+=("$relhits")
            NEEDS_REVIEW_NOTES+=("basename '$bn' shared with ${#siblings_abs[@]} other file(s); these consumers reference '$bn' but don't import any sibling by path — possibly template/dynamic usage")
        fi
    done
else
    # No project root or no candidates — fall back to all-needs-review.
    for f in "${FILES[@]}"; do
        NEEDS_REVIEW+=("$f")
        NEEDS_REVIEW_HITS+=("")
        NEEDS_REVIEW_NOTES+=("skipped basename check")
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
        n="${NEEDS_REVIEW_NOTES[$i]:-}"
        printf -- '- `%s`\n' "$f"
        # Split hits on `|` and print each indented.
        if [[ -n "$h" ]]; then
            IFS='|' read -r -a hit_arr <<< "$h"
            for hh in "${hit_arr[@]}"; do
                [[ -n "$hh" ]] && printf -- '    - found in `%s`\n' "$hh"
            done
        fi
        [[ -n "$n" ]] && printf -- '    - _%s_\n' "$n"
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
