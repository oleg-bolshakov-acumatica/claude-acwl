# Support duty report templates

Use these as concise output contracts, not as instructions to invent missing values.
Remove irrelevant optional detail. Replace example slots with actual values;
keep `unknown`, `not checked`, and missing evidence explicit when appropriate.

## Run summary

Save only this overview under `support-duty/<UTC-run-start>/summary.md`.
Every retrieved SR needs a row, even when it could not be reviewed.

```markdown
# Support duty: <run start UTC>

- Scope: all | backlog
- Started / ended: <UTC instants>
- Display timezone: Europe/Budapest
- Queue retrieval: complete | incomplete | failed
- Review coverage: complete | incomplete; reused notes may need refresh
- Retrieved SRs: <unique count>; Jira-reported total: <if reliable>
- Reviews: <new>, <reused>, <failed/pending>
- Reused freshness: <unchanged>, <stale>, <unknown>

JQL:
<exact executed query>

| Код | Описание | Статус | Команда | Исполнитель | Этап разбора | Root cause / уверенность | Workaround | Следующее действие | Review / актуальность | Заметка |
|---|---|---|---|---|---|---|---|---|---|---|
| <linked key> | <Jira summary> | <live status> | <acuTeam> | <live assignee or empty> | <evidence-backed step or unknown> | <short cause; Confirmed/Likely/Unclear> | <available / not confirmed> | <one action> | <new/reused; original date; unchanged/stale/unknown> | <relative link to Jira note> |

## Queue overview

- Counts by status/team and analysis step.
- Priority, due-date or impact facts that justify attention; avoid invented urgency.
- Material blockers, stale investigations and items needing a focused follow-up.
- Optional added/removed/changed keys against a comparable complete run.

## Coverage and errors

- Failed pages/SRs, missing comments/context and bounded-search limits.
- Reused analysis was not rerun; issue watermark equality does not validate linked sources.
- No database/source checks performed in this run; no external writes.
```

Use valid Markdown links and escape table pipes/newlines in Jira summaries.
From a run's `summary.md`, the relative link to an individual note is
`../../AC-123456/support-duty-review.md` (or the actual existing note name).
Use absolute clickable workspace links in the final chat response.
For an inaccessible issue leave unsupported analysis cells `not reviewed`, not
`Unclear` as if an investigation had been completed. For a zero queue retain run
metadata and state `No matching active SRs`; for a failed search state retrieval
failure and unknown queue size.

## On-screen summary

Use this compact form in the final chat response for both scopes. Include one
row for every retrieved SR, including reused and failed reviews. In `scope=all`,
the separate Assignee column is mandatory; it may also be kept for backlog.
Show the current display name and login when available. A confirmed empty
assignee is `не назначен`; a missing field is `unknown`. Do not replace the
per-item table with selected highlights or the saved-report link. `fast`
reduces wording per row, not the number of rows.

```markdown
Scope=<all/backlog>: <count> SR; <new> новых review / <reused> переиспользованных / <failed> не разобраны.

| Код | Краткое описание | Статус | Команда | Assignee / Исполнитель | Краткий review | Следующий шаг |
|---|---|---|---|---|---|---|
| <linked key> | <short Jira summary> | <live status> | <acuTeam> | <live display name (login), не назначен or unknown> | <current step; cause and Confirmed/Likely/Unclear, or not reviewed> | <one concise action> |

<Reuse freshness / incomplete coverage limitations, when applicable.>

[Полный отчёт](<absolute workspace path to saved summary.md>)
```

Keep each review to one short sentence or clause; label historical/unverified
findings for reused stale/unknown notes in that row. On partial retrieval show
all obtained rows and state that the queue is incomplete. An empty successful
queue or a failed initial search uses the appropriate explicit outcome and
report link, without invented item rows.

## Individual quick review

Save to `.session-notes/<JiraKey>/support-duty-review.md` only when a new review
is needed. Prefer existing substantive notes. The YAML metadata supports future
reuse; preserve the distinction between review completeness and source gaps.

```markdown
---
jira_key: <key>
review_type: support-duty-quick
reviewed_at: <UTC instant>
jira_updated_at: <queue watermark as UTC>
jira_updated_precision: seconds | milliseconds
detail_jira_updated_at: <detail watermark if available>
review_complete: true | false
---

# <key>: <summary>

## Request and current step

- Symptom, expected/actual behavior, impact, version and development question.
- Analysis step: <step>; source: <latest material comment/date or description>.
- Observed Jira status/team/assignee: <snapshot, not a current-state guarantee>.

## Evidence

- Decisive facts with Jira comment/key, Wiki section or PR metadata links.
- Checked explicit/related keys, actual similarity-search queries.
- Comment coverage, skipped evidence, limits and conflicts.

## Root cause and workaround

- Confidence: Confirmed | Likely | Unclear
- Cause/hypothesis, supporting evidence and what would confirm/refute it.
- Workaround: <steps/source/applicability/risk or no safe confirmed workaround>.
- Known Bug/fix: <key/build/source and applicability, when established>.
- No database or source-code analysis performed during this review.

## 9. Iteration Gate

- Outcome: Resolved | Partially Resolved | Unresolved | Blocked
- Further investigation needed: yes | no; <reason and exact missing evidence>.
- Next action: <one concrete task; owner only if supported, otherwise proposed>.
- Starting another investigation requires explicit user approval; not executed here.

Continuation prompt, if needed:
Continue <key> using this note. Goal: <unresolved goal>.
Known facts: <facts>. Already checked: <sources/checks; do not repeat without change>.
Remaining hypothesis: <hypothesis + confirm/refute condition>.
Focus: <narrow task>. Success criterion: <decision enabled>.
Constraints: approved repository access paths; no Jira writes.
SQL/source checks require a separate approved detailed-analysis invocation.

## 10. Jira Comment Proposal

<One short evidence-backed draft, or why unavailable. Not posted.>
```

`review_complete=true` means the bounded pass and deliverables were completed,
not that the cause was resolved or every source was available. A failed primary
SR read is incomplete. If the detail watermark changed after discovery, record
the mismatch and mark current applicability unverified; do not silently label
that review fresh. Do not copy credentials, private backup paths or personal
contact data into either artifact.
