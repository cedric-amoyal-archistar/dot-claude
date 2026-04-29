# Claude Code Permissions Policy

This document is the source of truth for `permissions.allow` and `permissions.deny` in `~/.claude/settings.json`. JSON has no comments, so this sidecar IS the comment.

**Hard rule:** no entry lands in `settings.json` without a corresponding line of rationale here.

---

## Tier model

| Tier | What | Treatment |
|---|---|---|
| **Built-in** | `ls`, `cat`, `head`, `tail`, `grep`, `find` (no `-exec`/`-delete`), `wc`, `diff`, `stat`, `du`, `cd`, plus most read-only `git` (`status`, `log`, `diff`, `show`, `blame`, `branch`, etc.) | Auto-approved by Claude Code with no rule needed. Don't add — wasted noise. |
| **Tier 1** | Read-only / inspection. No state change. | `allow` |
| **Tier 2** | Working-tree mutating, NOT publishing. (`git add`, `eslint --fix`, `prettier --write`, `npm install`, formatters.) | `allow` |
| **Tier 3** | Publishing / history-rewriting / destructive. (`git push`, `git commit`, `git reset --hard`, `git rebase`, `npm publish`, `gh pr create`, `rm -rf`.) | `deny` (explicit, defense-in-depth) |
| **Tier 4** | Arbitrary-code-exec primitives. (`bash -c`, `node -e`, `python3 -c`, `eval`, `xargs <cmd>`, `npx`.) | Leave prompting (we deny `eval` explicitly; the rest are out of allow). |

---

## Pattern syntax (verified)

Use **`Bash(cmd *)`** — space form. Canonical, what the "always allow" UI generates.

| Pattern | Matches |
|---|---|
| `Bash(npm install)` | exact, no args |
| `Bash(npm install *)` | `npm install` followed by anything |
| `Bash(npm install:*)` | equivalent to `npm install *` (alternate sugar) |
| `Bash(git *)` | **DANGEROUS** — covers `git push`, `git reset --hard`, `git commit --amend` |

**Compound commands are parsed.** Claude Code splits on `&&`, `||`, `;`, `|`, `|&`, `&`, newlines. Each subcommand is matched independently. So `Bash(npm install *)` does NOT auto-allow `npm install && rm -rf ~`.

**Process wrappers stripped:** `timeout`, `time`, `nice`, `nohup`, `xargs` (no inner cmd). NOT stripped: `npx`, `docker exec`, `mise exec`, `devbox run`. Don't allowlist runners that aren't auto-stripped.

**Always-prompt forms:** `find -exec`, `find -delete`, `watch`, `setsid`. Cannot be auto-approved at all.

---

## Layered settings (precedence, highest first)

1. Managed enterprise settings
2. CLI flags (`--allowedTools`)
3. Project local `.claude/settings.local.json`
4. Project shared `.claude/settings.json`
5. **User global** `~/.claude/settings.json` ← THIS FILE'S TARGET

**Arrays merge (union)** across layers. **Deny always beats allow at every level.** A user-global deny cannot be overridden by a project allow. This is why our deny list is the safety net: even if some project file later sneaks in `Bash(git *)`, our global denies of `git push *`, `git commit *`, etc. still fire.

---

## Allow groups (rationale per group)

| Group | Rationale |
|---|---|
| **Search & data tools** (`rg`, `ag`, `fd`, `jq`, `yq`, `sed -n`, `awk`) | Beyond the built-in `grep`/`find`. `sed -n` is read-only (no `-i`); `awk` can technically write but acceptable risk for solo dev. |
| **Filesystem inspection** (`tree`, `realpath`, `basename`, `dirname`, `file`, `df`) | Pure introspection. |
| **System lookup** (`which`, `command -v`, `type`, `pwd`, `whoami`, `date`, `hostname`, `env`, `printenv`) | Lookup. `env`/`printenv` leak environment to model — acceptable on personal machine. |
| **Git read-only** (~22 entries) | Belt-and-suspenders for the built-in classifier. `git fetch` mutates only `.git/refs/remotes/*`, isolated from working tree. |
| **GitHub CLI read-only** (`gh pr view/list/diff/checks`, `gh issue view/list`, `gh run view/list`, `gh api`) | `gh api` defaults to GET — POST/PUT/DELETE/PATCH are caught by deny rules. |
| **Package introspection** | `npm list/view/outdated`, `pnpm list/why`, `yarn list/why`, `bun pm ls`, `pip list/show`, `cargo metadata/tree`. |
| **Build / test / lint / typecheck** | `npm run *` is broad — trust boundary is identical to user typing it. Compound-command parsing catches `npm test && git push` (push denied). |
| **Formatters / autofixers** | `prettier --write`, `eslint --fix`, `ruff`, `black`, `gofmt`, `cargo fmt`. Mutate tracked files, exactly per your rule. |
| **Git mutation (non-publishing)** | `git add/restore/mv/rm/checkout`, `git stash push/pop/apply`. `git checkout *` is allowed but `git checkout -- *` and `git checkout .` are denied (destructive). |
| **Package install** | `npm/pnpm/yarn/bun install`. Mutates `package-lock.json` and `node_modules`. Postinstall script risk = same as user running it manually. |
| **Filesystem mutation in cwd** | `mkdir/touch/mv/cp/ln/sed -i`. Already covered by `acceptEdits` for paths in cwd, but explicit allow is belt-and-suspenders. |
| **Script syntax checks** | `bash -n *`, `node --check *`. Verify-only, never executes. |

---

## Deny groups (rationale per group)

| Group | Rationale |
|---|---|
| **Git publishing / rewrites** (`git push`, `git commit`, `git rebase`, `git merge`, `git reset --hard`, `git tag -a/-s`, `git branch -d/-D`) | Per your rule: never auto-allow commit/push. Also bars history-rewriters that lose work. |
| **Git destructive on working tree** (`git checkout -- *`, `git checkout .`, `git checkout HEAD -- *`, `git clean -f/-fd`, `git stash drop/clear`) | Destroys uncommitted work irrecoverably. No reflog for unstaged edits. |
| **Package publishing** (`npm/pnpm/yarn publish`) | Reaches public registries. Always require explicit confirmation. |
| **GitHub state mutation** (`gh pr create/merge`, `gh issue create`, `gh release create`) | Visible to others, hard to reverse. |
| **Filesystem destruction** (`rm -rf`, `rm -fr`, `rm -r`, `sudo`, `chmod 777`) | Irreversible. `rm -r` is enough to nuke directories. |
| **Mutating HTTP** (`curl -X POST/PUT/DELETE/PATCH`, `curl --data`, `curl -d`, `wget`) | Network mutation. Use `WebFetch` tool for reads. |
| **Eval primitives** (`eval *`) | Defeats every other rule. (Note: `bash -c`, `python3 -c`, `node -e` are NOT denied here — they continue prompting, which is the correct behavior since denying them would only stop Claude from explicitly invoking them, while a deny adds no marginal safety vs. the prompt baseline.) |

---

## Anti-patterns (do NOT add to allow)

- ❌ Tool-wildcards: `Bash(git *)`, `Bash(npm *)`, `Bash(docker *)` — replace with subcommand-pinned entries.
- ❌ Hyper-specific one-shots: `Bash(grep -r '$X|$Y' /abs/path/specific/file)` — fossils from a single session, never matches again.
- ❌ Embedded `/Users/cedricamoyal/...` user paths — except for skill-specific scripts in `~/.claude/skills/` (those are intentionally pinned).
- ❌ Pinned tool versions: `node v22.16.0` will be wrong in a month.
- ❌ Shell-state mutators: `Bash(export *)`, `Bash(source *)`, `Bash(cd *)`.
- ❌ Patterns with redirects/pipes: `Bash(* > file)`, `Bash(* | sh)`.
- ❌ Runner wildcards: `Bash(npx *)`, `Bash(devbox run *)`, `Bash(mise exec *)` — these aren't auto-stripped, so they cover arbitrary inner commands.
- ❌ Code-exec primitives: `Bash(node *)`, `Bash(python3 *)`, `Bash(bash -c *)` — defeat every other rule.

---

## "Always allow" UI hygiene

When Claude Code prompts and offers "always allow", it captures the **exact command**. Ask before clicking:

1. Is this command a CLASS of safe operations, or just THIS specific invocation?
2. Does the captured pattern contain a path/regex/version that won't repeat?
3. Is this in `~/.claude/.claude/settings.local.json` because cwd is `~/.claude/`? (If yes, promote to global manually.)

**Default to "allow once" for one-shots. Only "always allow" for true classes.** Five extra prompts is cheaper than a year of stale entries.

---

## Quarterly review

First Monday of each quarter:

1. `git log --since=3.months -- ~/.claude/settings.json` — see what was added.
2. For each entry: "would I add this today?" If no, remove.
3. Walk every project's `.claude/settings.local.json` for accumulated cruft.
4. Update this file to reflect changes.

If quarterly slips, the failure mode is gradual bloat — acceptable but real.

---

## File status (snapshot)

- `~/.claude/settings.json` — global, governs every session.
- `~/.claude/.claude/settings.local.json` — **deleted** as of plan execution. Was auto-created when cwd = `~/.claude/`; its dangerous `Bash(git *)` is now permanently neutralized by global deny rules.
- `~/dev/archistar/frontend/citymanager/client/.claude/settings.local.json` — left alone.
- `~/dev/archistar/frontend/start-frontend/client/.claude/settings.local.json` — left alone.
- `~/dev/archistar/frontend/portal-frontend/.claude/settings.local.json` — left alone (the `curl` entry there warrants future review).

---

## Promoted via promote-permissions skill (20260429-124425)

- `Bash(python3 -m json.tool)` — JSON pretty-printer; literal exact match, zero exec surface (sourced from: lineups-vite-react-tailwind-healess-ui)
- `Read(//private/tmp/**)` — macOS symlink target of /tmp; read-only (sourced from: portal-frontend)
- `Read(//tmp/**)` — Conventional scratch dir; read-only (sourced from: lineups-vite-react-tailwind-healess-ui)
- `WebFetch(domain:github.com)` — Daily-use read-only HTTP; promoting reduces session friction more than it grows risk (sourced from: lineups-vite-react-tailwind-healess-ui)
