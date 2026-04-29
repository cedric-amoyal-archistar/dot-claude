#!/usr/bin/env bash
# promote-permissions/scripts/plan.sh
#
# Phase 1: read 5 source files + global, classify every entry, write a plan
# JSON to .last-plan.json, print a markdown report. Modifies nothing.

set -euo pipefail
IFS=$'\n\t'

SKILL_ROOT="/Users/cedricamoyal/.claude/skills/promote-permissions"
GLOBAL_SETTINGS="$HOME/.claude/settings.json"
PLAN_FILE="$SKILL_ROOT/.last-plan.json"

# 4 source project files (locked list — no ~/.claude/.claude/ which is deleted)
SOURCES=(
    "portal-frontend|/Users/cedricamoyal/dev/archistar/frontend/portal-frontend/.claude/settings.local.json"
    "start-frontend-client|/Users/cedricamoyal/dev/archistar/frontend/start-frontend/client/.claude/settings.local.json"
    "citymanager-client|/Users/cedricamoyal/dev/archistar/frontend/citymanager/client/.claude/settings.local.json"
    "lineups-vite-react-tailwind-healess-ui|/Users/cedricamoyal/dev/cedric/lineups-vite-react-tailwind-healess-ui/.claude/settings.local.json"
)

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

normalize_pattern() {
    sed 's/:\*)/\ *)/' <<< "$1"
}

# ============================================================
# Preflight
# ============================================================
[[ "$PWD" == "/Users/cedricamoyal/.claude" ]] || \
    fatal "must be run from /Users/cedricamoyal/.claude (current PWD: $PWD)"

command -v jq >/dev/null 2>&1 || fatal "jq not on PATH"

[[ -f "$GLOBAL_SETTINGS" ]] || fatal "global settings not found: $GLOBAL_SETTINGS"
jq -e . "$GLOBAL_SETTINGS" >/dev/null 2>&1 || fatal "global settings is not valid JSON"

# ============================================================
# Rule tables — transparent, hardcoded categorization
# ============================================================

DROP_FORBIDDEN=(
    'Bash(curl:*)'
    'Bash(curl *)'
    'Bash(wget *)'
    'Bash(python3 *)'
    'Bash(python *)'
    'Bash(python3 -c :*)'
    'Bash(python3 -c *)'
    'Bash(python -c *)'
    'Bash(node *)'
    'Bash(node -e *)'
    'Bash(node --eval *)'
    'Bash(bash *)'
    'Bash(bash -c *)'
    'Bash(sh *)'
    'Bash(sh -c *)'
    'Bash(zsh *)'
    'Bash(zsh -c *)'
    'Bash(eval *)'
    'Bash(npx:*)'
    'Bash(npx *)'
)

DROP_DEAD_EXACT=(
    'Bash(npx eslint:*)'
    'Bash(npx eslint *)'
    'Bash(npx vitest:*)'
    'Bash(npx vitest *)'
    'Bash(npx tsc:*)'
    'Bash(npx tsc *)'
    'Bash(npx prettier:*)'
    'Bash(npx prettier *)'
    'Bash(find:*)'
    'Bash(find *)'
    'Bash(grep:*)'
    'Bash(grep *)'
    'Bash(ls:*)'
    'Bash(ls *)'
    'Bash(cat:*)'
    'Bash(cat *)'
    'Bash(git stash *)'
    'WebFetch(domain:img.uefa.com)'
)

# Forbidden by regex — inline-eval flags, shell-state mutators
DROP_FORBIDDEN_REGEX=(
    '^Bash\(python3? -c '
    '^Bash\(node -e '
    '^Bash\(node --eval '
    '^Bash\(bash -c '
    '^Bash\(sh -c '
    '^Bash\(zsh -c '
    '^Bash\(eval '
    '^Bash\(export '
)

# Format: source|target|rationale
PROMOTE_MAP=(
    'Bash(python3 -m json.tool)|Bash(python3 -m json.tool)|JSON pretty-printer; literal exact match, zero exec surface'
    'WebFetch(domain:github.com)|WebFetch(domain:github.com)|Daily-use read-only HTTP; promoting reduces session friction more than it grows risk'
    'Read(//tmp/**)|Read(//tmp/**)|Conventional scratch dir; read-only'
    'Read(//private/tmp/**)|Read(//private/tmp/**)|macOS symlink target of /tmp; read-only'
)

LEAVE_PROJECT_LOCAL=(
    'WebFetch(domain:ma-api.ligue1.fr)'
    'WebFetch(domain:sdp-prem-prod.premier-league-prod.pulselive.com)'
    'WebFetch(domain:www.premierleague.com)'
    'WebFetch(domain:resources.premierleague.com)'
    'WebFetch(domain:resources.premierleague.pulselive.com)'
    'WebFetch(domain:www.api-football.com)'
    'WebFetch(domain:www.sportmonks.com)'
    'WebFetch(domain:api.fifa.com)'
)

DROP_DEAD_REGEX=(
    '^Bash\(curl '
    '^Bash\(cat .*Screenshot'
    '^Bash\(cat .*Desktop'
    '^Bash\(chmod \+x /tmp/'
    '^Bash\(/tmp/'
    '^Bash\(/private/tmp/'
    '/Users/'
    '/tmp/'
    '/private/tmp/'
    'https?://'
)

ALWAYS_DEDUP=(
    'WebSearch'
    'WebSearch(*)'
)

# ============================================================
# Read global allow into normalized lookup
# ============================================================
GLOBAL_ALLOW_NORMALIZED=$(
    jq -r '.permissions.allow // [] | .[]' "$GLOBAL_SETTINGS" \
    | while IFS= read -r line; do normalize_pattern "$line"; done \
    | sort -u
)

is_in_global_allow() {
    local needle
    needle=$(normalize_pattern "$1")
    grep -qxF "$needle" <<< "$GLOBAL_ALLOW_NORMALIZED"
}

# ============================================================
# Categorize one entry. Output: CATEGORY|TARGET|RATIONALE
# ============================================================
categorize() {
    local entry="$1"
    local norm
    norm=$(normalize_pattern "$entry")

    for pat in "${ALWAYS_DEDUP[@]}"; do
        [[ "$entry" == "$pat" ]] && { echo "DUP||default-allowed Claude Code tool"; return; }
    done

    for pat in "${DROP_FORBIDDEN[@]}"; do
        if [[ "$entry" == "$pat" || "$norm" == "$pat" ]]; then
            echo "DROP-FORBIDDEN||code-exec or wide-egress primitive (bypasses safety rules)"
            return
        fi
    done

    for re in "${DROP_FORBIDDEN_REGEX[@]}"; do
        if [[ "$entry" =~ $re ]]; then
            echo "DROP-FORBIDDEN||inline-eval flag or shell-state mutator (anti-pattern)"
            return
        fi
    done

    for pat in "${DROP_DEAD_EXACT[@]}"; do
        if [[ "$entry" == "$pat" || "$norm" == "$pat" ]]; then
            local why
            case "$entry" in
                *npx*)  why="npx version-spec defeats inner-tool pin (\`tool@malicious-version\` attack)";;
                *find*) why="built-in (auto-classified by Claude Code; explicit rule weakens safety)";;
                *grep*) why="built-in (auto-classified by Claude Code)";;
                *ls*)   why="built-in (auto-approved)";;
                *cat*)  why="built-in (auto-approved)";;
                *uefa*) why="no live workflow; assets already scraped";;
                *)      why="dead anti-pattern";;
            esac
            echo "DROP-DEAD||$why"
            return
        fi
    done

    for triple in "${PROMOTE_MAP[@]}"; do
        local src="${triple%%|*}"
        local rest="${triple#*|}"
        local target="${rest%%|*}"
        local reason="${rest#*|}"
        if [[ "$entry" == "$src" ]]; then
            echo "PROMOTE|$target|$reason"
            return
        fi
    done

    for pat in "${LEAVE_PROJECT_LOCAL[@]}"; do
        [[ "$entry" == "$pat" ]] && { echo "LEAVE-PROJECT-LOCAL||project-specific (sport-API WebFetch domain)"; return; }
    done

    if is_in_global_allow "$entry"; then
        echo "DUP||already covered by global allow (after normalization)"
        return
    fi

    for re in "${DROP_DEAD_REGEX[@]}"; do
        if [[ "$entry" =~ $re ]]; then
            echo "DROP-DEAD||one-shot fossil (literal URL/path; will not match again)"
            return
        fi
    done

    echo "LEAVE-UNKNOWN||no rule matched; review manually before next run"
}

# ============================================================
# Build plan
# ============================================================

PLAN_TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

plan_json=$(jq -n --arg ts "$PLAN_TIMESTAMP" '{version: 1, timestamp: $ts, sources: []}')

for src in "${SOURCES[@]}"; do
    label="${src%%|*}"
    path="${src#*|}"

    if [[ ! -f "$path" ]]; then
        plan_json=$(jq --arg label "$label" --arg path "$path" \
            '.sources += [{label: $label, path: $path, exists: false, mtime: null, before: [], after: [], actions: []}]' \
            <<< "$plan_json")
        continue
    fi

    if ! jq -e . "$path" >/dev/null 2>&1; then
        fatal "source file is not valid JSON: $path"
    fi

    mtime=$(stat_mtime "$path")
    before_arr=$(jq -c '.permissions.allow // []' "$path")

    actions_jq='[]'
    after_jq='[]'

    while IFS= read -r entry; do
        [[ -z "$entry" ]] && continue
        IFS='|' read -r category target rationale <<< "$(categorize "$entry")"

        actions_jq=$(jq --arg e "$entry" --arg c "$category" --arg t "$target" --arg r "$rationale" \
            '. += [{entry: $e, category: $c, target: $t, rationale: $r}]' <<< "$actions_jq")

        if [[ "$category" == "LEAVE-PROJECT-LOCAL" || "$category" == "LEAVE-UNKNOWN" ]]; then
            after_jq=$(jq --arg e "$entry" '. += [$e]' <<< "$after_jq")
        fi
    done < <(jq -r '.permissions.allow // [] | .[]' "$path")

    plan_json=$(jq --arg label "$label" --arg path "$path" --argjson mtime "$mtime" \
        --argjson before "$before_arr" --argjson after "$after_jq" --argjson actions "$actions_jq" \
        '.sources += [{label: $label, path: $path, exists: true, mtime: $mtime, before: $before, after: $after, actions: $actions}]' \
        <<< "$plan_json")
done

# Aggregate global additions in jq (group all PROMOTE actions by target)
plan_json=$(jq '
    .global_additions = (
        [.sources[] as $s | $s.actions[] | select(.category == "PROMOTE")
         | {target: .target, label: $s.label, rationale: .rationale}]
        | group_by(.target)
        | map({
            entry: .[0].target,
            sources: (map(.label) | unique | join(", ")),
            rationale: .[0].rationale
          })
    )
' <<< "$plan_json")

# Global settings mtime
GLOBAL_MTIME=$(stat_mtime "$GLOBAL_SETTINGS")
plan_json=$(jq --arg path "$GLOBAL_SETTINGS" --argjson mtime "$GLOBAL_MTIME" \
    '. += {global_settings: {path: $path, mtime: $mtime}}' <<< "$plan_json")

# Summary
plan_json=$(jq '
    .summary = {
        promote: ([.sources[].actions[] | select(.category == "PROMOTE")] | length),
        dup: ([.sources[].actions[] | select(.category == "DUP")] | length),
        drop_dead: ([.sources[].actions[] | select(.category == "DROP-DEAD")] | length),
        drop_forbidden: ([.sources[].actions[] | select(.category == "DROP-FORBIDDEN")] | length),
        leave_project_local: ([.sources[].actions[] | select(.category == "LEAVE-PROJECT-LOCAL")] | length),
        leave_unknown: ([.sources[].actions[] | select(.category == "LEAVE-UNKNOWN")] | length)
    }
' <<< "$plan_json")

echo "$plan_json" > "$PLAN_FILE"

# ============================================================
# Markdown report
# ============================================================
echo "# Permission Audit — Plan"
echo
echo "**Timestamp:** $PLAN_TIMESTAMP"
echo "**Plan file:** \`$PLAN_FILE\`"
echo "**Status:** PLAN ONLY — no files have been modified."
echo

n_promote=$(jq '.summary.promote' "$PLAN_FILE")
n_dup=$(jq '.summary.dup' "$PLAN_FILE")
n_drop_dead=$(jq '.summary.drop_dead' "$PLAN_FILE")
n_drop_forbidden=$(jq '.summary.drop_forbidden' "$PLAN_FILE")
n_leave_local=$(jq '.summary.leave_project_local' "$PLAN_FILE")
n_leave_unknown=$(jq '.summary.leave_unknown' "$PLAN_FILE")
n_additions=$(jq '.global_additions | length' "$PLAN_FILE")

echo "## Summary"
echo
echo "| Action | Count |"
echo "|---|---|"
echo "| PROMOTE → global (deduplicated to **$n_additions** unique targets) | $n_promote |"
echo "| DUP (remove from local) | $n_dup |"
echo "| DROP-DEAD (remove from local) | $n_drop_dead |"
echo "| DROP-FORBIDDEN (remove from local) | $n_drop_forbidden |"
echo "| LEAVE-PROJECT-LOCAL (kept) | $n_leave_local |"
echo "| LEAVE-UNKNOWN (manual review) | $n_leave_unknown |"
echo

if (( n_additions > 0 )); then
    echo "## Will be ADDED to \`~/.claude/settings.json\` ($n_additions entries)"
    echo
    echo '```json'
    jq -r '.global_additions[] | "\"\(.entry)\","' "$PLAN_FILE" | sed '$ s/,$//'
    echo '```'
    echo
    echo "Rationales:"
    jq -r '.global_additions[] | "- `\(.entry)` — \(.rationale) _(from: \(.sources))_"' "$PLAN_FILE"
    echo
fi

if (( n_drop_forbidden > 0 )); then
    echo "## Will be REMOVED per global policy (DROP-FORBIDDEN)"
    echo
    echo "These are documented anti-patterns. If you want any kept, decline this plan."
    echo
    jq -r '.sources[] as $s | $s.actions[] | select(.category == "DROP-FORBIDDEN") | "- **From `\($s.label)`:** `\(.entry)` — \(.rationale)"' "$PLAN_FILE"
    echo
fi

echo "## Per-source breakdown"
echo
n_sources=$(jq '.sources | length' "$PLAN_FILE")
for ((i = 0; i < n_sources; i++)); do
    label=$(jq -r ".sources[$i].label" "$PLAN_FILE")
    exists=$(jq -r ".sources[$i].exists" "$PLAN_FILE")
    path=$(jq -r ".sources[$i].path" "$PLAN_FILE")

    if [[ "$exists" == "false" ]]; then
        echo "### \`$label\`"
        echo
        echo "_File does not exist (skipped):_ \`$path\`"
        echo
        continue
    fi

    before_n=$(jq ".sources[$i].before | length" "$PLAN_FILE")
    after_n=$(jq ".sources[$i].after | length" "$PLAN_FILE")
    echo "### \`$label\` ($before_n → $after_n entries)"
    echo
    echo "| Entry | Disposition | Reason |"
    echo "|---|---|---|"
    jq -r ".sources[$i].actions[] | \"| \`\(.entry)\` | \(.category)\(if .target != \"\" then \" → \`\(.target)\`\" else \"\" end) | \(.rationale) |\"" "$PLAN_FILE"
    echo
    if (( after_n > 0 )); then
        echo "**Final \`permissions.allow\`:**"
        echo
        echo '```json'
        jq -r ".sources[$i].after | .[] | \"\\\"\\(.)\\\",\"" "$PLAN_FILE" | sed '$ s/,$//'
        echo '```'
        echo
    else
        echo "**Final state:** \`\"allow\": []\` (empty)"
        echo
    fi
done

if (( n_leave_unknown > 0 )); then
    echo "## ⚠ Items requiring manual review (LEAVE-UNKNOWN)"
    echo
    echo "No rule matched these. They will be left in their current location."
    echo
    jq -r '.sources[] as $s | $s.actions[] | select(.category == "LEAVE-UNKNOWN") | "- **From `\($s.label)`:** `\(.entry)`"' "$PLAN_FILE"
    echo
fi

echo "---"
echo
echo "## To apply"
echo
echo "Type **YES** (uppercase) to apply this plan."
echo "apply.sh will re-verify file mtimes (abort on drift), back up all affected files to \`~/.claude/backups/promote-permissions/<timestamp>/\`, and atomically write the changes."
