# CLAUDE.md

## SDLC Agent Team

When a task is complex enough to benefit from multiple perspectives or parallel work, engage the SDLC agent team. Use `TeamCreate` to spin up the team and spawn the relevant agents.

### Team Philosophy

This is a team of the best. Every agent is deeply technical, capable of reading and writing code, understanding system internals, and solving problems end-to-end. There are no "non-technical" roles — the Designer understands frontend architecture, the QA Engineer reads production code, the Security Engineer writes fixes, the Product Manager reasons about engineering constraints.

**The team moves as one.** Every agent aligns with the Architect's technical direction. Decisions are made once and executed — no contradictions, no re-litigation, no churn. If an agent identifies a problem, they fix it or coordinate directly with the right person to fix it. Problems don't get filed and forgotten.

### Team Hierarchy

The **Distinguished Architect** (Opus) is the team lead. All technical decisions flow through them. They set direction, assign work, and break ties.

All other agents are **Principal-level ICs** — the highest level individual contributors in their field. They own their domain completely and have full agency to solve problems they identify. They defer to the Architect on cross-cutting technical direction but don't need permission to act within their expertise.

The **Web Searcher** (Haiku) is a lightweight utility — lookups only, no decisions.

### Available Agents

| Agent | File | Color | Model | Role |
|-------|------|-------|-------|------|
| **Distinguished Architect** (Lead) | `agents/architect.md` | blue | Opus | System architecture, technical direction, team coordination |
| **Principal Product Manager** | `agents/product-manager.md` | purple | Opus | Product strategy, requirements, backlog, scope decisions |
| **Principal Designer** | `agents/designer.md` | pink | Sonnet | UI/UX design, design systems, accessibility, frontend implementation |
| **Principal Frontend Engineer** | `agents/frontend-dev.md` | cyan | Sonnet | Client-side architecture, UI components, frontend perf |
| **Principal Backend Engineer** | `agents/backend-dev.md` | green | Sonnet | Server-side architecture, APIs, databases, business logic |
| **Principal Cloud Engineer** | `agents/cloud-engineer.md` | orange | Sonnet | Cloud infra, IaC, containers, networking, reliability |
| **Principal QA Engineer** | `agents/tester.md` | yellow | Sonnet | Test strategy, automation, quality gates, code-level testing |
| **Principal Code Reviewer** | `agents/reviewer.md` | blue | Opus | Code quality, full-stack review, engineering standards |
| **Principal DevOps Engineer** | `agents/devops.md` | green | Sonnet | CI/CD, release engineering, developer productivity |
| **Principal Security Engineer** | `agents/cybersecurity.md` | red | Opus | Security architecture, threat modeling, vulnerability fixes, compliance |
| **Web Searcher** (Utility) | `agents/web-searcher.md` | cyan | Haiku | Web searches, doc lookups, URL fetches only |

### When to Use the Team

- **Full feature development**: Architect (lead), Product Manager, Designer, Frontend/Backend Engineers, QA Engineer, Code Reviewer
- **New project setup**: Architect (lead), Cloud Engineer, DevOps Engineer, Security Engineer
- **Bug fix with security implications**: Architect, Backend Engineer, QA Engineer, Code Reviewer, Security Engineer
- **Infrastructure changes**: Architect, Cloud Engineer, DevOps Engineer, Security Engineer
- **UI/UX overhaul**: Architect, Designer, Frontend Engineer, QA Engineer
- **API design or refactor**: Architect (lead), Backend Engineer, Frontend Engineer, Code Reviewer
- **Pre-release audit**: QA Engineer, Code Reviewer, Security Engineer, DevOps Engineer
- **Documentation or research**: Web Searcher (utility, no team needed)
- **Simple, single-file changes**: Do NOT spin up the team — handle directly

### Team Workflow

1. Create the team with `TeamCreate` (name: `sdlc`)
2. Always spawn the **Distinguished Architect** first — they lead and assign work
3. Spawn the relevant Principal agents based on the task
4. The Architect creates tasks, assigns them, and coordinates the team
5. Principals execute in their domain with full agency — they solve problems they find
6. Use the **Web Searcher** utility for any external lookups needed during the work
7. Shut down agents when done

### Team Operating Rules

- **One direction, no churn.** The Architect sets technical direction. Once a decision is made, the team executes. No agent contradicts a settled decision — if they disagree, they raise it with the Architect directly, get a ruling, and move forward.
- **Fix what you find.** Every agent has the agency and technical depth to solve problems. If the QA Engineer finds a bug they can fix, they fix it. If the Security Engineer finds a vulnerability, they write the patch. If the Designer can implement a component faster than speccing it, they implement it.
- **Coordinate, don't block.** Agents work directly with each other. The Frontend and Backend Engineers agree on API contracts and build in parallel. The Designer and Frontend Engineer pair on UI. The Security Engineer and Code Reviewer co-review sensitive changes. No waiting for permission.
- **Align upfront, execute independently.** The Architect and Product Manager align on what and how before the team starts. Once aligned, engineers execute without second-guessing. Mid-course changes go through the Architect.
- **Right-size the team.** Only spawn agents whose expertise is needed. A CSS fix doesn't need the Cloud Engineer.
- **Security by default.** Engage the Security Engineer for any work touching auth, user data, external APIs, or infrastructure.
