# Feature Development from Specification Workflow

This document defines the workflow for iterative Acumatica ERP feature development from versioned functional requirements. It supplements `acumatica-feature-development` in `CLAUDE.md`.

Use [FEATURE_IMPLEMENTATION_PATTERNS.md](FEATURE_IMPLEMENTATION_PATTERNS.md) as the companion implementation guide for Acumatica data-path tracing, recalculation parity, report-source analysis, currency/base amount handling, UI computed values, and customization-friendly placement.

## Goals

- Base the implementation on versioned functional requirements and a plan for the whole feature.
- Keep implementation iterations small, explicit, and verifiable.
- Make scope, ambiguity, validation, and residual risk visible to the user.
- Preserve enough session state for reliable resume, handoff, and later verification.

## Core Principles

- Do not invent requirements. Separate confirmed facts from hypotheses.
- Do not implement ambiguous, contradictory, obsolete, or explicitly deferred requirements without user confirmation.
- Prefer existing Acumatica patterns, graph extension points, DAC attributes, accumulator patterns, workflow conventions, and report data-source patterns over new abstractions.
- Prefer graph-owned `protected virtual` methods for business logic that may need customization. Avoid static helper methods for feature behavior unless the logic is genuinely shared and no graph-level customization point is appropriate.
- Treat normal processing and recalculation/rebuild paths as separate implementation targets that must stay consistent.
- Treat report layout changes, data migrations, broad workflow redesign, and automated test expansion as separate scope items unless explicitly included in the current iteration.

## Context Source Selection

The effective functional requirements define the expected business behavior. Use local documentation and current code to establish implementation constraints. Record and surface any conflict between the requirements and implementation.

- Always use `docs/ARCHITECTURE_RULES.md` and `docs/REFACTORINGS.md` as the implementation guardrails for feature work.
- Use `docs/BUSINESS_MODEL.md` when PM/CN/PJ domain meaning, process semantics, terminology, or expected product behavior can change interpretation of the requirement.
- Use `docs/DATABASE_MODEL.md` when table ownership, keys, relationships, projections, or physical join paths can change design or validation.
- Use `system-diagnostics-analysis` when version, branch choice, customization state, upgrade history, or schema discovery can change the implementation or validation plan.
- Use `acumatica-git-workflow` for Jira-related branch/PR discovery and for the approval-gated feature branch, staging, commit, and push workflow.

## Functional Requirements and Source Versions

Resolve the Jira item and obtain sufficient functional requirements before starting feature analysis or implementation. Read a linked specification when present. A Jira item with a sufficient functional description or acceptance criteria can supply the requirements directly. A functional specification can also be one or more Wiki pages, Markdown files in a Git repository, or local Markdown files. If the Jira item has insufficient requirements and there is no usable linked or user-provided specification, explicitly ask the user for one of these sources and pause feature development. This also applies to work resumed from an existing branch or PR.

Before analyzing requirements, record the **source type, exact URL or other locator, and version** for each source. Analyze the content at that recorded version. Use the following identifiers.

| Source type | Exact location | Version |
| --- | --- | --- |
| Jira item | Issue URL or Jira key that identifies the item | `updated` plus a SHA-256 fingerprint of the requirement fields used, such as the description and acceptance criteria. Hash the same fields in a stable order on each check. |
| Wiki specification | Page URL or page ID for each requirements page | Page version for each page, captured with its content. |
| Markdown in Git | Repository URL or checkout path and the relative paths of the requirements files. Record the source ref when the source tracks a branch. | Exact commit SHA used to read the files. |
| Local Markdown | Resolved paths of the requirements files | SHA-256 of each file's content used for analysis. |

Include accepted amendments that affect requirements. Record their location, such as a comment link or ID, and the revision, last-edited time, or content fingerprint needed to detect a change. A page version alone may not capture an accepted amendment in a comment. Treat a change in the location or set of requirement files as a source change.

After every requirements analysis, record the sources and versions actually analyzed, the result, and any unresolved differences in the Jira item's session notes. Preserve previous records so the next stage can compare against the requirements used for the preceding stage.

## Required Working Artifacts

### Whole-Feature Implementation Plan

After the first analysis of the functional requirements, record and present a high-level plan for the whole feature before drafting the first detailed stage plan. Give each stage a short description of the business behavior it delivers, the intended order, material dependencies, and open decisions. Prefer stages that can be verified independently.

When work starts with a partial PR or branch, build the plan from the requirements and map the existing changes to its stages. Record the PR or branch, inspected commit SHA, and relevant baseline. Identify which behavior is implemented, partial, outstanding, or still needs validation, and cite the evidence. Use the reconciliation to choose the next stage. Carry forward prior approvals supported by the record for the applicable scope.

### Scope Ledger

Maintain a concise scope ledger during feature work:

- **In scope** - requirements selected for the current iteration.
- **Out of scope** - requirements explicitly excluded by the user or by mode limits.
- **Deferred** - valid requirements postponed to a later iteration.
- **Ambiguous** - requirements that need user, analyst, or specification clarification.
- **Validation pending** - behavior implemented but not yet validated by a focused scenario.

Update this ledger whenever the specification changes, the user narrows or expands scope, or implementation reveals a hidden dependency.

### Requirement Coverage Matrix

For substantial features, maintain a lightweight coverage matrix. It can be in the session note or in the response when requested.

Recommended columns:

- requirement or business behavior;
- source of the requirement: Jira, Wiki section, comment, user instruction, or code evidence;
- affected screens, graphs, DACs, reports, projections, and processes;
- status: implemented, partially implemented, missing, unclear, deferred, or not applicable;
- code evidence;
- validation scenario;
- residual risk or open question.

Do not mark a requirement implemented only because a similar path is implemented. Confirm the relevant paths for that requirement.

### Session Note

Use `acumatica-session-notes` throughout feature development. Keep the whole-feature plan, requirements analyses and version history, and any partial-implementation reconciliation in an existing scope note or `feature-scope.md` under the Jira item. Keep detailed plans, approvals, intermediate results, changed files, validation evidence, and transition reports in the corresponding stage notes.

Record doubts about requirements consistency and conflicts with implementation as they arise and surface them to the user. Record temporary decisions with their rationale, affected behavior, and condition for revisiting them. Update the notes as work proceeds so the next session can resume from the latest recorded state.

### Approved Stage Plan

Before editing product code, create or refresh a purpose-based stage plan in
`.session-notes/<JiraItemId>/`, normally `stage-<id>-planning.md`. Its status must
move through **Draft**, **Review requested**, **Approved**, **Implemented**, and
**Validated**. Do not implement a Draft or Review requested plan. Approval applies
only to the stated stage; a newly discovered dependency, data-model decision, or
later stage needs its own review and approval.

Each plan must contain:

- goal, in-scope behavior, explicit exclusions, and deferred work;
- requirements, exact source locations and analyzed versions, relevant sections, assumptions, and decisions still needed;
- data ownership, DAC/schema impact, namespace/folder/type design, string/decimal storage classification, localization impact, and extension points;
- applicable path matrix: entry/defaulting, persistence, workflow, release/posting,
  deletion/void/reversal, recalculation/rebuild, long operations, copy/template,
  API/import/integration, and inquiry/report/UI;
- exposed-contract and compatibility impact;
- focused validation scenarios, including parity and negative cases; and
- residual risks and approval record.

In the user-facing approval request, name each new architectural choice that affects this slice and briefly explain your recommendation. For example, propose the exact feature folder and why its module owns the behavior. If two designs are credible, give the consequence that distinguishes them and ask which to adopt. Record the decision in the same stage note. Stage approval covers the stated choices. Reopen a choice only when new evidence changes it.

At the stage boundary, append the actual changes, validation evidence, unresolved questions, requirements version comparison, and the user's closure and transition approvals. Preserve earlier decisions and add superseding decisions as new entries.

## Iteration Workflow

Resolve and record the initial requirements sources and create the whole-feature plan before planning implementation. Use the following cycle for each business stage.

### 1. Refresh Context

1. Load the recorded requirements sources and versions, whole-feature plan, and current stage. Apply the requirements version comparison before every stage transition. Recheck the sources when resuming from a stale record or when there is evidence that requirements changed during the current stage.
2. Read `docs/ARCHITECTURE_RULES.md` and `docs/REFACTORINGS.md`; read `docs/BUSINESS_MODEL.md` and `docs/DATABASE_MODEL.md` only when they affect interpretation, design, branch choice, or validation.
3. Read `docs/FEATURE_IMPLEMENTATION_PATTERNS.md` when the iteration includes business logic, posting/recalculation paths, reports, projections, currency/base amounts, UI computed values, or customization-sensitive placement.
4. Use `system-diagnostics-analysis` when environment, version, customization, upgrade, schema, or branch-selection context can materially affect the slice.
5. Use `acumatica-git-workflow` to resolve repository, branch, PR, and baseline context. Read-only discovery needs no workflow confirmation; every Git mutation does.
6. Record refreshed context, changes to scope, and intermediate results or risks in the Jira item's notes.

### 2. Inventory and Classify Requirements

Identify normative requirements, examples, comments, unresolved comments, UI rules, data rules, edge cases, and acceptance criteria.

Classify each important requirement as:

- **Ready** - clear enough to implement.
- **Ambiguous** - multiple valid interpretations affect behavior or data.
- **Contradictory** - spec sections or comments conflict.
- **Deferred** - valid but outside current user-approved scope.
- **Rejected for current phase** - not appropriate for the current mode or risk level.

Ask for clarification only when implementation would be materially different depending on the answer. Otherwise make a conservative assumption and state it.

### 3. Trace Acumatica Data Paths

Before implementation, trace every requirement through the paths that can change the result. Use this checklist selectively, based on feature scope:

- document entry and defaulting;
- field events and validation;
- persist logic;
- release and posting;
- application, adjustment, reversal, voiding, and deletion;
- long operations and mass processing;
- recalculation, rebuild, and integrity-check processes;
- accumulators, project/base currency fields, and currency conversion paths;
- inquiry screens, side panels, dashboards, and selectors;
- reports, subreports, report DAC projections, and report data-source queries;
- workflow states and action availability;
- template/copy behavior;
- import scenarios and API/service entry points;
- cache invalidation and UI refresh behavior.

For report requirements, trace `rpx -> subreport -> report table -> DAC/projection -> source tables` before deciding whether to edit report layout or source queries.

Use [FEATURE_IMPLEMENTATION_PATTERNS.md](FEATURE_IMPLEMENTATION_PATTERNS.md) to structure this tracing and to identify parity risks between normal processing, recalculation, reports, projections, and UI computed values.

### 4. Plan and Obtain Approval for the Slice

Before editing files:

1. Verify or prepare the Jira `feature` branch through `acumatica-git-workflow`. Creating a branch requires explicit confirmation and a freshly fetched stable ref.
2. State the selected business slice.
3. State what will not be touched in this iteration.
4. Identify the central extension points and affected data paths.
5. Identify customization impact and prefer overridable graph-level methods where useful.
6. Identify focused validation commands and manual scenarios.
7. Create or refresh the approved stage plan described above and request review.

Keep the slice small enough that a build and a manual acceptance scenario can give meaningful confidence. Do not edit product code until the user approves the stage plan.

### 5. Implement

Implementation should follow these Acumatica-specific rules:

- Keep normal processing and recalculation behavior aligned.
- For currency/base field pairs, follow existing DAC and accumulator patterns. Do not hand-roll conversion when framework currency logic should populate base fields.
- Prefer stable persisted flags, such as `Released`, over fragile status-string interpretation when business behavior allows it.
- Avoid DB queries in frequent UI events such as `RowSelected`; prefer `FieldSelecting`, cached values, persisted fields, or existing view data depending on behavior.
- Keep report layout unchanged unless layout work is explicitly in scope.
- Avoid broad refactors while implementing a requirement slice.
- Preserve existing user changes and unrelated dirty worktree state.
- When changing an externally consumed or reusable surface, inventory consumers
  and compatibility expectations before changing its shape or meaning.

### 6. Validate

After each slice:

1. Run focused builds or checks that are meaningful for the changed files.
2. Run `git diff --check` or equivalent whitespace validation for code changes.
3. Search for equivalent code paths that may still miss the requirement.
4. Compare normal processing with recalculation/rebuild paths.
5. Recheck report/projection sources, UI computed values, and currency/base amount behavior when the slice touches those areas.
6. Provide manual validation scenarios when automated tests are not in scope.
7. Report any validation that could not be run.
8. Update the stage note with actual evidence before proposing the next stage.

### 7. Report, Recheck Requirements, and Approve the Transition

1. Update the coverage assessment and prepare a stage report. Include delivered behavior, changed paths, actual validation results, pending checks, and open or temporary decisions. Identify implementation gaps, validation gaps, and deferred scope. Save the report in the stage note.
2. Before moving to the next stage, re-resolve the requirements at their recorded locations and compare the current sources and versions with those analyzed for the stage just completed. Include accepted amendments. When a handoff has no previous version record, tell the user which baseline is missing and record the first verified requirements analysis as the starting point.
3. When a source or version changes, explicitly tell the user what changed and what it means for the completed work and the remaining plan. Compare the requirement-bearing content to identify semantic changes. If requirements changed, analyze the affected requirements again, update the whole-feature plan, coverage, and next stage as needed, and record the new analyzed version. If the requirements are equivalent, record that result and the current version. If a source cannot be verified, report the gap and keep the transition pending.
4. Present the stage report, the version comparison, and the next detailed stage plan when applicable. Obtain and record explicit user approval to close the stage and, when work remains, to start the next stage. One confirmation may cover both when its scope is clear. Obtain closure approval for the last stage as well. Record approval alongside the actual validation status.

## Stop Conditions

Stop and report instead of implementing when:

- sufficient functional requirements or verifiable source versions are unavailable;
- a stage transition is pending user approval or the required version comparison;
- requirement meaning is unclear and likely interpretations produce different persisted data or accounting results;
- specification comments contradict normative text and no later clarification resolves the conflict;
- the slice requires schema redesign, broad workflow changes, report layout work, migration, or large refactoring that was not approved;
- a high-risk accounting, posting, or recalculation change cannot be validated meaningfully;
- local architecture rules would be violated;
- branch, baseline, or repository context cannot be identified confidently.

## Recommended User-Facing Reports

During feature development, responses should be concise but explicit:

- current scope and excluded scope;
- business behavior implemented;
- key files or paths changed;
- validation run;
- known limitations;
- next recommended slice when useful.

For coverage reviews, use statuses consistently:

- **Implemented** - requirement is covered in relevant paths with code evidence.
- **Partially implemented** - core behavior exists but one or more relevant paths are missing.
- **Missing** - no implementation evidence found.
- **Unclear** - requirement or implementation mapping is ambiguous.
- **Deferred** - intentionally postponed by user or phase scope.
- **Not applicable** - confirmed not relevant to the current product mode, feature flag, branch, or scope.
