# Behavioral validation cases

Use these when creating or changing the skill. Walk through the proposed tool
calls and observable artifacts. Use fixtures/temporary outputs for error and
pagination scenarios; never modify live Jira or existing investigation notes
to manufacture a test. Live read-only query checks can verify the two scopes
without running full SR reviews or creating a duty-run report.

| Input / evidence | Expected behavior |
|---|---|
| `Run support duty` | Ask all vs backlog; no Jira call or run folder before answer |
| `Все активные SR Projects/Construction`, or `scope=all` | Base teams/statuses unchanged; no assignee clause |
| `Только backlog Project Accounting`, or `scope=backlog` | Exactly `assignee = ProjectAccounting_Ba`; no `IS EMPTY` |
| `Неназначенные SR`, without backlog clarification | Ask which queue; do not silently select literal empty or backlog |
| Full base JQL without assignee | Infer all; stable key ordering |
| Backlog JQL / a conflicting scope or unrelated assignee | Infer backlog only when unambiguous; otherwise clarify before retrieval |
| Existing relevant detailed investigation | Current queue metadata + dated reused findings; no new SR-detail/similarity calls |
| Existing quick review; equivalent UTC watermarks in different zones/precision | Compare common precision; unchanged SR watermark, linked-source freshness unverified |
| Existing note older than Jira `updated`, or legacy note without watermark | Reuse as stale or unknown; recommend refresh, no automatic rerun |
| Folder contains only implementation notes/attachments or failed retrieval stub | One new quick review; preserve old files |
| Status In Progress but no documented work stage | Keep actual Jira status; analysis step unknown, no invented stage |
| Reporter says regression; related Bug fits symptom but not version | Confidence not Confirmed; state applicability gap and next check |
| Relevant prior SR points to fixing Bug, near related-read limit | Reserve/read Bug or disclose unverified lineage; do not assert fix applicability |
| A full page followed by another page/empty page; duplicate keys | Advance by returned length, deduplicate, retrieve through termination |
| MCP repeats a page or fails the second page | Stop repeated pagination, retain rows, mark queue incomplete; no removed-key claims |
| Empty successful first page / failed first search | Empty queue / failed retrieval with unknown queue size, distinguish outcomes |
| One SR inaccessible; next SR readable | Failed row/incomplete note for first; continue second; review coverage incomplete |
| Cause still unclear after bounded searches | Complete one pass and gate; no search refinement loop, SQL, code or second iteration |
| Two starts in the same second | Different run directories; earlier summary untouched |
| All vs backlog historical run, or partial prior run | Do not infer added/removed keys across incompatible/incomplete queues |
| `scope=all and fast`; several assignees, including the backlog account | Saved report and on-screen table each have a separate Assignee column per SR with live values; fast keeps every item |
| Both scopes; new, reused and failed reviews in one queue | Final on-screen summary covers every retrieved key, with brief review/next action and per-row historical or not-reviewed labels where needed |
| Reused note has an old assignee; live queue has a different assignee | Show the live assignee in both outputs; do not derive it from old notes |
| Live assignee is null or the field was not returned | Show confirmed null as unassigned; missing field as unknown; do not infer backlog or ownership |
| Partial queue, zero queue or failed initial search | On-screen output shows all obtained items and the retrieval limitation, or the explicit empty/failed outcome; no invented rows |

Also validate frontmatter/UI metadata, existence of referenced files, and correct
Markdown links from nested run folders to standard Jira-item notes. No schedule
or external write is part of validation.
