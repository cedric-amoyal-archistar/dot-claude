#!/usr/bin/env bash
# find-unused-vue/scripts/scan.sh
#
# Read-only Vue dead-code scanner. Wraps a vendored `knip` (no network at
# runtime). This script is the only thing allowlisted in settings.json;
# subprocess calls (node, knip, jq) inherit the grant and need no separate
# approval.

set -euo pipefail
IFS=$'\n\t'

# Script takes no arguments — refuse if any are passed. The allowlist entry
# is exact-match (no `:*` suffix) so this should never trigger via Claude,
# but it's defense-in-depth for direct shell invocations.
if (( $# != 0 )); then
    printf 'find-unused-vue: scan.sh takes no arguments (got %d)\n' "$#" >&2
    exit 2
fi

# ============================================================
# Frozen paths — must match settings.json allowlist exactly
# ============================================================
SKILL_ROOT="/Users/cedricamoyal/.claude/skills/a-find-unused-vue"
KNIP_BIN="$SKILL_ROOT/node_modules/.bin/knip"
FORMAT_SCRIPT="$SKILL_ROOT/scripts/format-report.sh"
SELF="$SKILL_ROOT/scripts/scan.sh"

PROJECT_ROOT="$PWD"
TIMEOUT_SECS=60

# ============================================================
# Helpers
# ============================================================
fatal() {
    # Emit to stdout (Claude reads this) AND stderr (visible in shell).
    printf 'find-unused-vue: %s\n' "$1"
    printf 'find-unused-vue: %s\n' "$1" >&2
    exit 2
}

stat_perm() {
    # BSD (macOS) first, GNU (Linux) fallback.
    stat -f "%Lp" "$1" 2>/dev/null || stat -c "%a" "$1"
}
stat_owner() {
    stat -f "%u" "$1" 2>/dev/null || stat -c "%u" "$1"
}

# ============================================================
# Tamper check — refuse if scripts are mutable by anyone but owner
# ============================================================
check_owner_mode() {
    local f="$1"
    [[ -f "$f" ]] || fatal "missing required file: $f"

    local owner mode g o
    owner=$(stat_owner "$f")
    mode=$(stat_perm "$f")

    if [[ "$owner" != "$(id -u)" ]]; then
        fatal "$f not owned by current user (file uid=$owner, current uid=$(id -u)) — refusing to run"
    fi

    # mode is 3 or 4 octal digits. Last digit = other perms; second-to-last = group.
    g="${mode: -2:1}"
    o="${mode: -1}"
    if (( (g & 2) != 0 || (o & 2) != 0 )); then
        fatal "$f has group- or world-writable mode ($mode) — refusing to run"
    fi
}

check_owner_mode "$SELF"
check_owner_mode "$FORMAT_SCRIPT"

# ============================================================
# Project preflight
# ============================================================
case "$PROJECT_ROOT" in
    "$HOME"|"/"|"")
        fatal "refusing to scan '$PROJECT_ROOT' — cd into a Vue project root and retry"
        ;;
    "$HOME/.claude"|"$HOME/.claude/"*)
        fatal "refusing to scan inside ~/.claude"
        ;;
esac

[[ -f "$PROJECT_ROOT/package.json" ]] || \
    fatal "no package.json in $PROJECT_ROOT — cd into your Vue project root and retry"

command -v jq >/dev/null 2>&1 || \
    fatal "jq not found on PATH — required for parsing package.json and knip output"

HAS_VUE=$(jq -r '
    ((.dependencies // {}) + (.devDependencies // {}) + (.peerDependencies // {}))
    | has("vue")
' "$PROJECT_ROOT/package.json" 2>/dev/null || echo "false")

[[ "$HAS_VUE" == "true" ]] || \
    fatal 'no "vue" dependency found in package.json — this skill is Vue-only'

[[ -d "$PROJECT_ROOT/node_modules" ]] || \
    fatal "node_modules/ missing in $PROJECT_ROOT — run your install (npm/pnpm/yarn install) first"

[[ -x "$KNIP_BIN" ]] || \
    fatal "vendored knip not found at $KNIP_BIN — run 'cd $SKILL_ROOT && npm install' once to set up"

# ============================================================
# Node detection (nvm-aware, no shell sourcing)
# ============================================================
if ! command -v node >/dev/null 2>&1; then
    if [[ -d "$HOME/.nvm/versions/node" ]]; then
        latest=$(ls -1 "$HOME/.nvm/versions/node" 2>/dev/null | sort -V | tail -1 || true)
        if [[ -n "${latest:-}" && -x "$HOME/.nvm/versions/node/$latest/bin/node" ]]; then
            export PATH="$HOME/.nvm/versions/node/$latest/bin:$PATH"
        fi
    fi
fi
command -v node >/dev/null 2>&1 || \
    fatal "node not found on PATH and ~/.nvm did not provide one — install Node.js and retry"

# ============================================================
# Project type detection
# ============================================================
IS_NUXT=$(jq -r '
    ((.dependencies // {}) + (.devDependencies // {}))
    | (has("nuxt") or has("@nuxt/kit"))
' "$PROJECT_ROOT/package.json" 2>/dev/null || echo "false")

PROJECT_TYPE="Vite-Vue"
[[ "$IS_NUXT" == "true" ]] && PROJECT_TYPE="Nuxt"

PROJECT_NAME=$(jq -r '.name // "(unnamed)"' "$PROJECT_ROOT/package.json" 2>/dev/null || echo "(unnamed)")

# ============================================================
# Temp workspace + cleanup trap
# ============================================================
TMPDIR_LOCAL=$(mktemp -d -t knip-skill.XXXXXX)
KNIP_OUT="$TMPDIR_LOCAL/knip.json"
KNIP_ERR="$TMPDIR_LOCAL/knip.err"
trap 'rm -rf "$TMPDIR_LOCAL"' EXIT INT TERM

# ============================================================
# Knip command construction
# ============================================================
KNIP_CMD=(node "$KNIP_BIN" --reporter json --no-exit-code --no-progress)

if [[ "$IS_NUXT" == "true" ]]; then
    NUXT_CONFIG="$TMPDIR_LOCAL/knip.config.json"
    cat > "$NUXT_CONFIG" <<'JSON'
{
  "entry": [
    "nuxt.config.{js,ts,mjs}",
    "app.vue",
    "app/**/*.{js,ts,vue}",
    "pages/**/*.{js,ts,vue}",
    "layouts/**/*.{js,ts,vue}",
    "components/**/*.{js,ts,vue}",
    "composables/**/*.{js,ts}",
    "middleware/**/*.{js,ts}",
    "plugins/**/*.{js,ts,vue}",
    "server/**/*.{js,ts}",
    "utils/**/*.{js,ts}",
    "stores/**/*.{js,ts}"
  ],
  "ignore": [
    ".nuxt/**",
    ".output/**",
    "dist/**"
  ]
}
JSON
    KNIP_CMD+=(--config "$NUXT_CONFIG")
fi

# ============================================================
# Run knip with portable timeout
# ============================================================
(
    cd "$PROJECT_ROOT"
    "${KNIP_CMD[@]}"
) > "$KNIP_OUT" 2> "$KNIP_ERR" &
KNIP_PID=$!

(
    sleep "$TIMEOUT_SECS"
    if kill -0 "$KNIP_PID" 2>/dev/null; then
        kill -TERM "$KNIP_PID" 2>/dev/null || true
        sleep 2
        kill -0 "$KNIP_PID" 2>/dev/null && kill -KILL "$KNIP_PID" 2>/dev/null || true
    fi
) &
WATCHDOG_PID=$!

set +e
wait "$KNIP_PID"
KNIP_EXIT=$?
set -e

kill "$WATCHDOG_PID" 2>/dev/null || true
wait "$WATCHDOG_PID" 2>/dev/null || true

# ============================================================
# Validate knip output
# ============================================================
if (( KNIP_EXIT != 0 )); then
    err_summary=$(head -c 500 "$KNIP_ERR" 2>/dev/null | tr '\n' ' ' || echo "(no stderr captured)")
    fatal "knip exited with status $KNIP_EXIT. stderr: $err_summary"
fi

if ! jq -e . "$KNIP_OUT" >/dev/null 2>&1; then
    raw=$(head -c 500 "$KNIP_OUT" 2>/dev/null | tr '\n' ' ' || echo "")
    fatal "knip output was not valid JSON. First 500 bytes: $raw"
fi

# ============================================================
# Format and emit report
# ============================================================
"$FORMAT_SCRIPT" "$KNIP_OUT" "$PROJECT_NAME" "$PROJECT_TYPE" "$PROJECT_ROOT"
