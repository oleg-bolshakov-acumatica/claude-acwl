# claude-acwl — Acumatica Application Engineer Workspace, Light (Claude Code)

A self-contained Claude Code workspace for Acumatica ERP application engineering on the
Projects/Construction team. This is the **light** variant: external context comes from the
corporate `jira-internal` and `wiki-internal` MCP servers,
read-only SQL through a local PowerShell facade, and git over a local product checkout.
It provides workflow skills for support analysis, code review, spec verification,
bugfixing, and feature development.

The operating contract for the agent lives in [`CLAUDE.md`](CLAUDE.md); it is loaded
automatically by Claude Code. This README is for humans setting up and maintaining the
workspace.

## What "light" changes vs. the pro workspace (`claude-acw`)

- The `powershell-mcp-facade` is trimmed to **read-only SQL only** (`sql.select`). It no
  longer exposes Jira, Wiki, Bitbucket, or `context.get_reference` tools.
- Jira and Wiki are read through the corporate **`jira-internal`** and **`wiki-internal`**
  HTTP MCP servers (now the primary path, not a fallback).
- **RAG Memory is removed** (no `rag-memory` server, no `rag-proxy` backend, no RAG skills).
- **Bitbucket/PR access is removed**; a change set is inspected with **git over the local
  `code/` repository** via the `local-change-access` skill.
- The resource-proxy backend for SQL (`127.0.0.1:8765`) and its protocol are unchanged.

## Layout

```text
claude-acwl/
  CLAUDE.md                 Always-on operating contract (context rules, mode router, safety).
  .mcp.json                 Project MCP servers (read natively by Claude Code).
  .claude/
    settings.json           Read-only permission allowlist + SQL read-only guard hook.
    skills/                 Workflow and access skills (one folder per skill).
    agents/                 Read-only investigation subagents (parallel tracks, context isolation).
  core/                     PowerShell modules for the powershell-mcp-facade stdio server (SQL only).
  config/server.config.json Facade server + backend configuration.
  db-proxy/                 Local read-only SQL backend for the facade (HTTP on 127.0.0.1:8765).
  scripts/                  Startup, health-check, hook, and smoke-test scripts.
  docs/                     Architecture/business/database/feature docs + Acuminator (PX####) reference.
  .session-notes/           Per-Jira-item handoff notes (git-ignored).
  code/                     Local Acumatica product checkout (git-ignored; populated separately).
```

## MCP servers

Declared in `.mcp.json` and connected automatically when the workspace is trusted:

| Server | Transport | Purpose |
| --- | --- | --- |
| `powershell-mcp-facade` | stdio | Read-only SQL only (`sql.select`). Backend: local `db-proxy` at `127.0.0.1:8765`. |
| `jira-internal` | http | Internal Jira MCP — primary Jira read path (`jira_get_issue`, `jira_search`). |
| `wiki-internal` | http | Internal Confluence/Wiki MCP — primary Wiki read path (`confluence_get_page`, ...). |

The SQL facade requires its `db-proxy` backend to be running (see `db-proxy/README.md`).
Both HTTP servers require OAuth on first use and the Acumatica corporate network with
private access enabled.

## Getting started

1. Start Claude Code from the workspace root so the relative MCP startup paths resolve:
   ```powershell
   scripts/Start-Claude.ps1
   ```
   This auto-starts the local `db-proxy` SQL backend (in a separate window) if it is not
   already running, then launches Claude. Use `-SkipProxy` to skip it, or `-ProxyOnly` to
   only start the backend. (Or run `claude` yourself with this directory as the working
   directory, and start `db-proxy/Start.ps1` manually.)
2. Validate the MCP configuration and smoke-test the local SQL facade:
   ```powershell
   scripts/Check-Mcp.ps1            # full check (needs the local SQL backend running)
   scripts/Check-Mcp.ps1 -SkipSmokeTest   # config-only check
   scripts/Smoke-Test-Sql.ps1       # exercise sql.select end-to-end (needs the backend)
   ```
3. In Claude Code, run `/mcp` to confirm all three servers are connected. If any are
   missing, treat it as a configuration or backend-availability issue (see `CLAUDE.md`),
   not a reason to bypass the approved paths.

## Product source checkout (`code/`)

The Acumatica ERP product sources are **not** part of this workspace's git repository and
are **not** distributed with it. You must deploy them yourself:

1. Create the `code/` folder in the workspace root if it does not already exist.
2. Place a local clone/checkout of the Acumatica ERP source git repository inside `code/`
   (so that `code/.git` and the product tree resolve under it).
3. `code/` is git-ignored (see `.gitignore`), so the product sources never get committed
   into this workspace.

The git topology under `code/` is your choice — a full clone, a `git worktree` of an
existing checkout, or a junction/symlink to one you already maintain. The agent does not
assume a fixed layout: per the **Environment Interaction Principle** in `CLAUDE.md`, it
establishes the effective layout with you and reuses it for the session. If you keep the
sources at a path other than `code/`, just tell the agent the path.

Code-dependent workflows (review, bugfix, feature development, source-code analysis) and
the read-only git commands pre-approved in `.claude/settings.json` expect the default
`code/` location. Pull requests are inspected over this local repository: a PR id/URL is
resolved through the remote's Stash PR refs (`refs/pull-requests/<id>/from`), or you can
hand the agent a branch name or commit range directly — there is no Bitbucket/PR service.

## Workflows (mode skills)

Invoke the matching skill (e.g. `/acumatica-code-review`) or describe the task and let the
mode router in `CLAUDE.md` select it:

- `acumatica-support-request-analysis` — end-to-end Support Request root-cause/workaround analysis.
- `acumatica-code-review` — read-only review of a branch/change set/diff.
- `acumatica-spec-verification` — verify an implementation against a functional spec.
- `acumatica-small-bugfix` — minimal low-risk defect correction.
- `acumatica-feature-development` — iterative feature implementation from a spec.
- `functional-spec-risk-analysis` — pre-implementation spec risk analysis.

### Example requests

You can name the skill explicitly (`/acumatica-code-review ...`) or just describe the task
and let the mode router pick it. Jira items are shown as `AC-XXXXX` and pull requests as
`PR-XXXXX`; substitute real ids.

**`acumatica-support-request-analysis`**
- `Analyze Support Request AC-XXXXX — find the root cause and a safe workaround.`
- `AC-XXXXX: is this a known issue? Find the fixing Bug and the build it was fixed in.`
- `Draft a Jira comment for AC-XXXXX with the root cause and a SQL detection script.`

**`acumatica-code-review`**
- `Review PR-XXXXX.`
- `Review PR-XXXXX against the intent of AC-XXXXX.`
- `Review branch feature/AC-XXXXX-2026r250, focus on migration scripts and regressions.`

**`acumatica-spec-verification`**
- `Verify PR-XXXXX against the functional spec in AC-XXXXX.`
- `Build a requirement coverage matrix for AC-XXXXX before QA.`
- `Does branch feature/AC-XXXXX-2026r250 fully implement the Wiki spec linked in AC-XXXXX?`

**`acumatica-small-bugfix`**
- `Fix the defect described in AC-XXXXX with a minimal change; base branch 2026r150.`
- `Failing test SubstantiatedBillingTest.ReverseKeepsNetZero — diagnose and fix minimally.`
- `AC-XXXXX throws a null reference on empty cost code — apply a low-risk correction.`

**`acumatica-feature-development`**
- `Implement the next slice of AC-XXXXX from its Wiki functional spec.`
- `Continue feature work on AC-XXXXX — start with defaulting and validation.`
- `Implement the retainage requirement from AC-XXXXX on branch feature/AC-XXXXX-2026r250.`

**`functional-spec-risk-analysis`**
- `Analyze the functional spec linked in AC-XXXXX for contradictions and implementability.`
- `Review the Wiki spec for AC-XXXXX and prepare clarification questions before development.`
- `AC-XXXXX proposes a new persisted field for visibility — how risky is that for upgrades?`

Lower-level access/analysis skills (`jira-access`, `wiki-access`, `local-change-access`,
`database-access`, `jira-similar-search`, `related-items-analysis`, `source-code-analysis`,
`migration-script-consistency-review`,
`system-diagnostics-analysis`, `database-root-cause-analysis`, `jira-comment-drafting`,
`acumatica-session-notes`) are used by the mode skills and can also be invoked directly.

## Subagents

`.claude/agents/` defines read-only investigation subagents that the main agent can
dispatch — to run review tracks in parallel and to keep heavy context (Jira/Wiki/SQL/code
dumps) out of the main window:

- `acumatica-review-track` — one code-review dimension per instance (spec / architecture / migration / test / domain).
- `acumatica-sql-diagnostics` — tenant-scoped read-only SQL evidence.
- `acumatica-source-investigator` — static source analysis and git archaeology in `code/`.
- `acumatica-context-digest` — condensed Jira/Wiki/related-item digests.

## Safety model

This workspace is read-only by default. Read-only MCP servers and read-only git commands
are pre-approved in `.claude/settings.json`. A `PreToolUse` hook
(`scripts/hooks/Guard-Sql.ps1`) rejects any non-`SELECT` SQL as defense-in-depth (the
resource-proxy backend is the primary enforcer). The write-capable modes
(`acumatica-small-bugfix`, `acumatica-feature-development`) are intentionally *not*
pre-approved and follow the approval rules in their skills and in `CLAUDE.md`.

## Local SQL backend (db-proxy)

The SQL path is served by `db-proxy/`, a light SQL-only backend that keeps the original
resource-proxy HTTP contract (`POST /invoke` with `operation=sql.select`, `GET /status`)
but drops the Jira/Wiki/Bitbucket providers. It binds `127.0.0.1:8765`, matching
`config/server.config.json`, so the facade connects unchanged. Read-only `SELECT` is
enforced in `db-proxy/providers/Sql.Provider.psm1` and again by the `Guard-Sql.ps1` hook.
See `db-proxy/README.md` for details. It still depends on `SQLPS`/`Invoke-Sqlcmd`;
modernizing that is a possible follow-up.
