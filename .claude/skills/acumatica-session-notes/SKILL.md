---
name: acumatica-session-notes
description: Use this skill when Claude needs to create, update, read, organize, or decide whether to keep session notes for Acumatica workflow work, including Support Request analysis, PR review, bugfix investigation, specification verification, and feature development. Trigger when work may need resume, handoff, reuse, or when another workflow mentions session notes.
---

# Acumatica Session Notes

## Purpose

Keep concise handoff notes for Acumatica work that may need to be resumed, handed off, or reused.

## When to Use

Use this skill when:

- a workflow asks to save, suggest, refresh, or update session notes;
- the task is substantial enough that future resume or handoff context matters;
- the user asks to create, inspect, update, or clean session notes;
- work is being resumed and existing notes may contain relevant context.

Skip session notes for quick questions, one-shot lookups, or tasks where the final response contains all useful state.

## Storage

Store notes by Jira item:

```text
.session-notes/<JiraItemId>/<meaningful-name>.md
```

Use the Jira issue key exactly as the directory name, for example:

```text
.session-notes/AC-123456/root-cause-analysis.md
.session-notes/AC-123456/review-findings.md
.session-notes/AC-123456/feature-scope.md
.session-notes/AC-123456/validation.md
```

Use lower-case, hyphenated, purpose-based file names. Do not include dates in session note file names.

If no Jira item is known, do not invent one. Keep the handoff context in the final response unless the user provides a stable identifier or explicitly asks for a note outside the Jira-item layout.

### Support duty run summaries

For `acumatica-support-duty`, use the explicitly authorized run-level layout:

```text
.session-notes/support-duty/<YYYY-MM-DD_HHmmssZ>/summary.md
```

The directory represents actual UTC run start time; add a suffix if needed to avoid overwriting a run. This exception permits timestamps in run directory names, not in individual SR note file names. Resolve all-vs-backlog scope before creating a run. Store only summary metadata, queue rows, actions and links here, without per-SR subdirectories or duplicated investigation evidence.

Individual quick reviews remain `.session-notes/<JiraItemId>/support-duty-review.md`. Before creating one, read relevant existing notes; reuse substantive investigations instead of rerunning them. Carry original review date, queue update watermark when available, and stale/unknown freshness into the run summary. A folder with unrelated files or a failed retrieval stub is not an existing completed review. Preserve detailed investigations and user edits.

## File Selection

Before creating a note, check whether `.session-notes/<JiraItemId>/` already exists.

- Update an existing file when it covers the same workstream.
- Create a new file when the current work has a distinct purpose, such as root-cause analysis, review findings, implementation progress, or validation.
- Keep notes concise. Do not turn them into transcripts or long evidence dumps.

## Content Guidance

Do not enforce a rigid template. Use headings that fit the workflow, and include only handoff facts that will help the next pass.

Prefer covering:

- what was done or checked;
- what remains to do;
- problems, risks, blockers, and uncertainties;
- open questions;
- important decisions, assumptions, or conclusions;
- evidence pointers such as Jira, PR, Wiki, SQL, code paths, commands, or validation results.

Separate confirmed facts from hypotheses. Preserve enough detail to continue the work without rereading the entire conversation, but avoid duplicating the final report.

## Workflow-Specific Notes

For Support Request analysis, capture root-cause status, workaround status, related or similar items checked, SQL or code locations inspected, unresolved goals, and next checks when they matter.

For reviews and specification verification, capture review scope, PR or branch context, decisive findings, requirement coverage gaps, validation limits, and residual risks.

For feature development, capture current scope, implemented slices, files changed, important design decisions, validation, deferred items, open questions, and known risks.
