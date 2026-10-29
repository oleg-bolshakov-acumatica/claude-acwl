---
name: acumatica-support-duty
description: Review the active Acumatica Projects/Construction support queue, either all assignees or the Project Accounting backlog. Use for support duty reports, queue triage, or a batch of quick SR reviews with reusable session notes; ask for scope when unspecified. Performs one pass without database or source-code analysis.
---

# Acumatica Support Duty

Produce an evidence-led queue report and one quick review per previously unreviewed SR. Reuse existing investigations instead of repeating them. This is a separate batch mode from `acumatica-support-request-analysis`; do not invoke that full workflow or inherit its SQL/code stages. Use its confidence and handoff principles through the bounded procedure below.

## Resolve scope before retrieval

Require one of these values; there is no default:

| Parameter | Meaning | Assignee clause |
|---|---|---|
| `scope=all` | Active SRs of both teams, regardless of assignee | None |
| `scope=backlog` | The Project Accounting backlog queue | `AND assignee = ProjectAccounting_Ba` |

Infer scope from explicit natural language ("all active SRs", "все сапорты в работе", "backlog Project Accounting", "бэклог команды") or an unambiguous supplied JQL. A JQL covering the base queue without an assignee restriction means `all`; the exact backlog assignee means `backlog`. An unrelated assignee filter, conflicting instructions, or a bare "support duty" request does not determine scope.

If unresolved, ask explicitly with the `AskUserQuestion` tool when available, otherwise a direct question. This is a required scope clarification, not an optional-preference question:

> Обработать все активные сапорты Projects/Construction независимо от исполнителя или только бэклог Project Accounting — SR, назначенные на ProjectAccounting_Ba?

Offer `Все активные SR` and `Только backlog Project Accounting`. Wait for an answer before Jira retrieval or creating a run folder. Do not turn elapsed time or a preselected option into a choice. The backlog account is a real assignee: do not replace it with `assignee IS EMPTY`, add empty assignees, or equate a literal unassigned queue with backlog. If "unassigned" is not explicitly tied to the team backlog, clarify this distinction.

The invariant base query is:

```jql
project = AC
AND type = SupportRequest
AND acuTeam in (ProjectAccounting, ProjectsConstruction)
AND status in (New, Open, "In Progress", Assisted, Reopened)
```

Append the chosen assignee clause and `ORDER BY key ASC`. Both scopes retain exactly these teams and statuses. Do not silently broaden the queue to other teams or statuses, add a creation-date filter, or accept a different custom scope. Clarify conflicting JQL first. "New to this run" means not present in the previous comparable run; it does not mean Jira status `New`.

## Access and boundaries

Use `jira-access` for queue discovery through `jira-internal.jira_search` and individual issue reads; use `jira-similar-search` only for heuristic similarity. Load `related-items-analysis`, `wiki-access`, and `bitbucket-pr-access` when their context is needed. Use `acumatica-session-notes` for saved/reused notes. Consult `docs/BUSINESS_MODEL.md` only when it can resolve domain terminology or expected process behavior.

- External context stays read-only through the designated MCP paths. No direct REST, scraping, provider modules, or ad hoc external-access scripts.
- No SQL, database/schema inspection, environment diagnostics, local product source, PR diffs/files, Git operations, or origin-code investigation. PR metadata is allowed only to establish state/target branch; it cannot prove an exact released build.
- Existing notes may contain SQL/code evidence from a previous investigation. Attribute it to that dated note; do not rerun the checks or present it as verified in this run.
- Never post Jira comments, change assignment/status, configure schedules, or start remediation. Drafts and follow-up proposals are local artifacts only.
- One analysis pass per newly reviewed SR; no automatic investigation continuation. A later user-approved refresh is a separate invocation. Run independent retrievals as parallel tool calls when useful, but this skill does not authorize dispatching subagents.

## Retrieve a complete queue

Use the live MCP schema. Start with fields `summary,status,assignee,customfield_12700,updated,created,priority,duedate`, page size up to 50, and `start_at=0` on Server/DC. `customfield_12700` is `acuTeam`, verified in this environment; `customfield_10500` is `Area` and must not supply the team column. If mapping is absent or ambiguous, verify a representative issue with `expand=names`, rather than substituting Area/components/assignee as team.

MCP issue objects may be normalized at the top level rather than under `fields`; custom fields may wrap their content as `value`. Inspect the actual response. Do not assume a raw Jira response layout.

Advance `start_at` by the number of returned rows until an empty page; on Cloud use returned page tokens. Deduplicate by key. Do not infer completeness from the first page or an unverified `total` alone. Stop and flag incomplete retrieval on repeated pages, failed pages, or inconsistent pagination instead of looping. A live Jira queue is not an atomic snapshot: disclose detected changes and retrieval times.

An empty successful first page is an empty queue. A failed search is a failed retrieval, never zero active SRs. Save a summary with incomplete/failed status when retrieval fails after scope is resolved. Retain all successfully obtained rows and identify the missing coverage.

## Reuse notes before reviewing

For each key, inspect `.session-notes/<JiraKey>/` for a relevant analysis. Prefer a substantive existing investigation for the same symptom/question over a quick review; use its most recent material conclusions and record conflicts. Do not choose a file solely by modification time or a folder's existence. Unrelated notes, raw attachments, and empty/incomplete scaffolds are not completed reviews.

| Available context | Action |
|---|---|
| Relevant completed investigation or quick review | Reuse it; no detailed SR reads, similarity searches, or comment redrafting |
| No relevant completed review | Perform one quick review and save `support-duty-review.md` in the standard Jira folder |
| Note and queue update watermark differ | Reuse with `stale` and recommend refresh; do not automatically reanalyze |
| No trustworthy watermark, or conflicting relevant notes | Reuse with `unknown` freshness and disclose the limitation |

Compare saved `jira_updated_at` against the queue `updated` as UTC instants at their common reported precision; never compare timezone strings lexically. Queue timestamps in this MCP may omit milliseconds present in issue detail. Save the queue watermark and its precision for the next comparison. Mark `unchanged` only when trustworthy watermarks match and there is no known conflict. This confirms only the SR watermark, not that linked Bugs/Wiki/PRs are unchanged. Always show the original review date or `unknown`.

Use current queue status/team/assignee in the report even when reusing old conclusions. For stale/unknown notes, label the root cause, workaround, analysis step and action as historical/unverified for current applicability. Preserve stronger existing findings and user edits; do not overwrite a detailed investigation with a quick review. If refreshed explicitly in a future invocation, update the existing quick-review workstream and retain provenance of earlier conclusions.

## One quick-review pass

1. Read title, description, version/build, impact, reproduction, requested development action, attachments metadata and relevant comment history through `jira-access`, with `update_history=false`. Read comments chronologically. Select a sufficient comment limit using the actual returned count/total; allow at most one larger reread when returned history is truncated. If history remains incomplete, disclose that gap rather than claiming full coverage. Do not download backups or customization packages. Retrieve an essential small screenshot/log only through `jira-access` when it can change the conclusion; otherwise record the missing evidence.
2. Establish current analysis step from the latest material facts: awaiting triage, investigating, awaiting customer information, awaiting engineering/fix, workaround validation, or unknown. Cite its source/date. A Jira status or an assignee alone does not prove the precise step, ownership decision, or completed work.
3. Open meaningful explicit links/mentioned issues first. Read relevant fixing Bugs before claiming a known defect or fix applicability. Compare the current Jira build with explicit fixed builds/QA evidence; a reported regression or merged PR is supporting evidence, not automatic confirmation.
4. If cause/workaround remains unclear, run at most one targeted Jira similarity search (up to five candidates). Open only useful results. Bound additional related Jira issue reads to five unique keys per SR, including fixing Bugs; reserve capacity for the fixing Bug when a prior SR is used. Cache already retrieved related context within this run. Do not recursively traverse links or refine noisy searches repeatedly.
5. Open at most one material Wiki page (including inline/footer comments and resolution state) and one specific PR's metadata per SR when needed. On limits, missing access, or incompatible versions, report the unverified evidence and keep an appropriate confidence. Stop discovery when it cannot change the decision.
6. Form at most three hypotheses. State the strongest supported cause, a safe supported workaround or its absence, and one concrete next action with the evidence needed to confirm/refute the conclusion. Record actual checked keys/queries and retrieval gaps so a later investigation can continue without repeating work.

Confidence is `Confirmed`, `Likely`, or `Unclear`. `Confirmed` requires direct current-case evidence, such as documented reproduction plus a verified diagnosis, successful targeted validation, or a demonstrated configuration cause. Similar symptoms, an unverified comment assertion, a reporter's regression suspicion, and fix metadata alone do not confirm the cause. Keep workaround confidence separate from cause confidence and identify applicability/risk; do not invent repair SQL or recommend executing an unvalidated workaround.

Finish each newly reviewed SR in this order:

- **9. Iteration Gate:** analysis outcome `Resolved`, `Partially Resolved`, `Unresolved`, or `Blocked`; whether further investigation is needed; decisive reason/gap; focused continuation prompt. These outcomes are analysis results, not Jira transitions. State that another investigation requires explicit user approval and is outside this run. Do not pause the batch to request that approval; continue other SRs.
- **10. Jira Comment Proposal:** use `jira-comment-drafting` to produce one short ready-to-post draft from gathered facts, answering any outstanding explicit question first. If the SR is inaccessible, say why no useful draft is possible. Never post it.

Failures for one SR do not stop other SRs. Save a blocked/incomplete note where useful and a row that identifies the failure. Do not reuse an unsuccessful retrieval stub as a completed review on a later run.

## Save the run and individual results

Use [report templates](references/report-templates.md) when writing results. Adapt length to evidence; no transcripts or large source dumps. Write in the user's language; keep Jira keys/statuses/team names and confidence labels exact.

- Individual analysis: `.session-notes/<JiraKey>/support-duty-review.md`, or link the existing substantive note. No per-SR directories inside a run folder.
- Run summary: `.session-notes/support-duty/<YYYY-MM-DD_HHmmssZ>/summary.md`. Use actual UTC run start time, also recording timezone/local display time when useful. Create a unique folder; on collision append `-02`, `-03`, etc. Never overwrite an earlier run. Creation is authorized by a scoped invocation; do not ask for separate notes approval.
- `support-duty` contains only run summaries. Each summary records scope, exact JQL, start/end, retrieval completeness, review completeness, counts and errors; every retrieved SR has a row with **Code - Description - Status - Team**, plus assignee, analysis step, concise cause/confidence, workaround, next action, freshness/original review date, and note link. Description means Jira `summary`, not full description.
- Summarize distribution by Jira status/team and analysis step, and highlight blockers or actions needing attention. Put detailed evidence, continuation prompts and comment drafts only in Jira-item notes.
- When a previous comparable successful run exists, optionally show added/removed keys and changed status/assignee. Compare only identical scope/JQL and complete queue retrievals. A removed key means no longer matching the query, not necessarily resolved. Never claim removals from a partial run.

In `scope=all`, show each SR's current assignee in a separate **Assignee / Исполнитель** column in both the saved run summary and the final on-screen table. Use the live queue value even for reused reviews; show the display name and login when available. A confirmed empty assignee is `Unassigned / не назначен`; an unavailable field is `unknown`. Keep `ProjectAccounting_Ba` identifiable as the backlog account.

Conclude with queue counts, a compact on-screen table covering **every retrieved SR**, and clickable links to the saved run and relevant SR notes. Each row includes the key, short description, live status/team, a brief review (current step and strongest cause/confidence), and next action; include the mandatory assignee column for `scope=all`. Both scopes require this per-item summary, including reused and failed reviews. Mark stale/unknown reused evidence as historical/unverified and failed reviews as `not reviewed`. `fast` shortens each row's wording while preserving coverage of all items. Highlights may supplement the table; a report link or selected items alone does not satisfy the on-screen output. State incomplete coverage and reuse limits. See the [on-screen template](references/report-templates.md#on-screen-summary). If the scope is missing, only ask the scope question; no run report yet.

## Validation when changing this skill

Use [behavioral cases](references/validation-cases.md) to check scope resolution, cache handling, pagination, and failed/partial runs, in addition to the skill-creator structural validator. A creation/update request does not select a report scope or authorize a full live queue review; distinguish validation lookups from an actual report run.
