# claude-acwl — Acumatica Application Engineer Workspace (Claude Code)

A self-contained Claude Code workspace for Acumatica ERP application engineering on the
Projects/Construction team. External context comes from the corporate `jira-internal`,
`wiki-internal`, and `bitbucket-internal` MCP servers, read-only SQL through a local
PowerShell facade, and git over a local product checkout. It provides workflow skills for
support analysis, code review, spec verification, bugfixing, and feature development.

The operating contract for the agent lives in [`CLAUDE.md`](CLAUDE.md); it is loaded
automatically by Claude Code. This README is for humans setting up and maintaining the
workspace.

## Layout

```text
claude-acwl/
  CLAUDE.md                 Always-on operating contract (context rules, mode router, safety).
  .mcp.json                 Project MCP servers (read natively by Claude Code).
  .claude/
    settings.json           Read-only permission allowlist + SQL read-only guard hook.
    skills/                 Workflow and access skills (one folder per skill).
    agents/                 Read-only investigation subagents (parallel tracks, context isolation).
    hooks/                  Guard-Sql.ps1, the PreToolUse SQL read-only guard.
  db-mcp/                   powershell-mcp-facade stdio MCP server (SQL only), its config, and Check-Mcp.ps1.
  db-proxy/                 Local read-only SQL backend for the facade (HTTP on 127.0.0.1:8765).
  docs/                     Architecture/business/database/feature docs + Acuminator (PX####) reference.
  .session-notes/           Per-Jira-item handoff notes (git-ignored).
  code/                     Local Acumatica product checkout (git-ignored; populated separately).
```

## MCP servers

Declared in `.mcp.json` and connected automatically when the workspace is trusted:

| Server | Transport | Purpose |
| --- | --- | --- |
| `powershell-mcp-facade` | stdio | Read-only SQL only (`sql.select`, `sql.list_databases`, `sql.search_schema`, `sql.describe_table`). Backend: local `db-proxy` at `127.0.0.1:8765`. |
| `acumatica-development-guidance` | http | Repository-specific development guidance articles for `code`/`tests` work. |
| `jira-internal` | http | Internal Jira MCP — primary Jira read path (`jira_get_issue`, `jira_search`). |
| `wiki-internal` | http | Internal Confluence/Wiki MCP — primary Wiki read path (`confluence_get_page`, ...). |
| `bitbucket-internal` | http | Internal read-only Bitbucket MCP — pull-request metadata, changed files, diffs, comments, commits. |

The SQL facade requires its `db-proxy` backend to be running (see `db-proxy/README.md`).
All four HTTP servers require OAuth on first use and the Acumatica corporate network with
private access enabled.

## Getting started

1. SQL tools need the local `db-proxy` backend. Start it once from the workspace root and
   leave its window open. It serves every session until you close the window or sign out
   of Windows. Skip this step when the task does not use SQL.
   ```powershell
   .\db-proxy\Start.ps1
   ```
   You can also right-click `db-proxy/Start.ps1` in File Explorer and select
   **Run with PowerShell**. If you start the backend after Claude Code, retry the SQL
   request; Claude Code does not need a restart.
2. Start Claude Code from the workspace root as usual, so the relative MCP startup paths
   in `.mcp.json` resolve:
   ```powershell
   claude
   ```
3. Validate the MCP configuration and smoke-test the local SQL facade:
   ```powershell
   db-mcp/scripts/Check-Mcp.ps1                  # config, facade smoke test, backend probe
   db-mcp/scripts/Check-Mcp.ps1 -SkipSmokeTest   # config-only check
   db-proxy/scripts/Smoke-Test-DbProxy.ps1       # sql.select directly against the running backend
   db-proxy/scripts/Test-SqlProvider.ps1         # read-only guard and parameter unit checks
   ```
4. In Claude Code, run `/mcp` to confirm all five servers are connected. If any are
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
`code/` location. A pull request can be inspected directly through `bitbucket-internal`
from its URL or repository coordinates; local source analysis, git history, and anything
outside the PR diff still need a branch or commit range in `code/`.

## Workflows (mode skills)

Invoke the matching skill (e.g. `/acumatica-code-review`) or describe the task and let the
mode router in `CLAUDE.md` select it:

- `acumatica-projects-product-research` — read-only business research for Project Accounting and Construction: current behavior, existing configuration, Jira precedents, and feature-option impact.
- `acumatica-support-request-analysis` — end-to-end Support Request root-cause/workaround analysis.
- `acumatica-support-duty` — active Projects/Construction SR queue report (`scope=all` or `scope=backlog`) with one quick review per unreviewed SR and note reuse.
- `acumatica-code-review` — read-only review of a branch/change set/diff.
- `acumatica-spec-verification` — verify an implementation against a functional spec.
- `acumatica-feature-final-review` — read-only final functional and technical/architectural review of a feature after iterative development.
- `acumatica-small-bugfix` — minimal low-risk defect correction.
- `acumatica-bug-backport` — approval-gated local Service Pack/Patch backport branch and commit from an existing fix.
- `acumatica-feature-development` — iterative feature implementation from a spec.
- `acumatica-technical-specification` — concise technical design document from the functional spec and verified code; approval-gated Wiki publication.
- `functional-spec-risk-analysis` — pre-implementation spec risk analysis.

### Example requests

You can name the skill explicitly (`/acumatica-code-review ...`) or just describe the task
and let the mode router pick it. Jira items are shown as `AC-XXXXX`; substitute real ids.
Reference a pull request by its Bitbucket URL (or project/repo/id coordinates) — a bare
numeric PR id is not resolvable on its own.

**`acumatica-support-request-analysis`**
- `Analyze Support Request AC-XXXXX — find the root cause and a safe workaround.`
- `AC-XXXXX: is this a known issue? Find the fixing Bug and the build it was fixed in.`
- `Draft a Jira comment for AC-XXXXX with the root cause and a SQL detection script.`

**`acumatica-code-review`**
- `Review <bitbucket-pr-url>.`
- `Review <bitbucket-pr-url> against the intent of AC-XXXXX.`
- `Review branch feature/AC-XXXXX-2026r250, focus on migration scripts and regressions.`

**`acumatica-spec-verification`**
- `Verify <bitbucket-pr-url> against the functional spec in AC-XXXXX.`
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

Lower-level access/analysis skills (`jira-access`, `wiki-access`, `bitbucket-pr-access`,
`local-change-access`,
`database-access`, `jira-similar-search`, `related-items-analysis`, `source-code-analysis`,
`acumatica-development-guidance`, `migration-script-consistency-review`,
`system-diagnostics-analysis`, `database-root-cause-analysis`, `jira-comment-drafting`,
`acumatica-session-notes`) are used by the mode skills and can also be invoked directly.

## Subagents

`.claude/agents/` defines read-only investigation subagents that the main agent can
dispatch — to run review tracks in parallel and to keep heavy context (Jira/Wiki/SQL/code
dumps) out of the main window:

- `acumatica-review-track` — one code-review dimension per instance (spec / architecture / migration / test / domain).
- `acumatica-sql-diagnostics` — tenant-scoped read-only SQL evidence.
- `acumatica-source-investigator` — static source analysis and git archaeology in `code/`.
- `acumatica-context-digest` — condensed Jira/Wiki/PR/related-item digests.

## Safety model

This workspace is read-only by default. Read-only MCP servers and read-only git commands
are pre-approved in `.claude/settings.json` (Git branch/remote commands only in their read-only forms). Among `wiki-internal` write tools, only the page-update tools `confluence_update_page` and `confluence_update_page_section` are pre-approved, so authorized technical-specification revisions run without repeated prompts; the other write tools are listed under `ask` so they always prompt. Every non-read-only git operation (including
`git fetch`) requires explicit confirmation per `acumatica-git-workflow`. A `PreToolUse`
hook (`.claude/hooks/Guard-Sql.ps1`) rejects any non-`SELECT` SQL as defense-in-depth (the
`db-proxy` backend is the primary enforcer). The write-capable modes
(`acumatica-small-bugfix`, `acumatica-bug-backport`, `acumatica-feature-development`) are
intentionally *not* pre-approved, and Wiki publication in `acumatica-technical-specification`
requires the user's scoped publication request or approval; all of them follow the approval
rules in their skills and in `CLAUDE.md`.

## Local SQL backend (db-proxy)

The SQL path is served by `db-proxy/`, a SQL-only backend with a small localhost HTTP
contract (`POST /invoke`, `GET /status`). Besides `sql.select` it serves `sql.list_databases`,
`sql.search_schema`, and `sql.describe_table`. It binds `127.0.0.1:8765`, matching
`db-mcp/config/server.config.json`, so the facade connects unchanged. Read-only `SELECT` is
enforced in `db-proxy/providers/Sql.Provider.psm1` and again by the `Guard-Sql.ps1` hook.
See `db-proxy/README.md` for details. SQL runs through `System.Data.SqlClient` under the
current Windows identity, so `SQLPS`/`Invoke-Sqlcmd` is not required and no SQL
credentials are stored in this workspace.
