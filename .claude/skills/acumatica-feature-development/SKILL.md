---
name: acumatica-feature-development
description: Implement or continue an Acumatica ERP feature from versioned functional requirements. Use for planning a whole feature, reconciling a partial implementation, or delivering approved stages.
---

# Acumatica Feature Development

## Purpose

Implement features in approved stages from versioned functional requirements. Maintain the whole-feature plan, coverage, validation evidence, and remaining risks.

## Context Sources

Use repository-approved paths only:

- Use `jira-access` for Jira requirements, acceptance criteria, comments, linked issues, and development metadata.
- Use `acumatica-git-workflow` to discover Jira-related branches/PRs and to prepare or resume the `feature` branch.
- Use `wiki-access` for linked `wiki.acumatica.com` functional specifications, including comments and resolution state.
- Use `bitbucket-pr-access` when an existing pull request must be inspected. Use `local-change-access` for an existing branch or commit/ref range via git over the local `code/` repository.
- Use `database-access` only for read-only diagnostics that can change interpretation, implementation risk, branch choice, or validation.
- Use `system-diagnostics-analysis` when version/build, customization, upgrade chronology, schema discovery, or source-branch selection can materially affect implementation or validation.
- Use `jira-similar-search` only when explicit context is insufficient and prior issues can change the plan.
- Use `acumatica-development-guidance` for applicable repository architecture, conventions, pitfalls, build/startup, testing, and validation guidance after the task and local context are resolved.

Do not use direct REST, provider modules, browser access, or ad hoc scripts for Jira, Wiki, Bitbucket, source changes, or SQL when the approved path is available.

## Required Local Context

Read and follow:

- `docs/FEATURE_DEVELOPMENT_WORKFLOW.md`
- `docs/ARCHITECTURE_RULES.md`
- `docs/REFACTORINGS.md`

Read `docs/FEATURE_IMPLEMENTATION_PATTERNS.md` when the iteration includes business logic, posting/recalculation paths, reports, projections, currency/base amounts, UI computed values, or customization-sensitive placement.

Use `docs/CODE_NAVIGATION.md` to locate the existing code the feature must touch and to enumerate the data paths that need parity: entry/defaulting, validation, persist, release/posting, recalculation, inquiry/report/projection, workflow, API/GI, migration, and tests. Keep `docs/ARCHITECTURE_RULES.md` authoritative for where new files belong, and confirm map paths on the feature branch.

Read domain, database, and source references only when they can change interpretation, design, branch choice, or validation.

If a required workflow doc is missing, continue with this skill and report the limitation.

## Requirements and Initial Plan

Follow the source and version rules in [the feature development workflow](../../../docs/FEATURE_DEVELOPMENT_WORKFLOW.md#functional-requirements-and-source-versions). Use sufficient functional requirements from Jira, a Wiki specification, or versioned Markdown files in Git or at local paths. Ask explicitly for a requirements source and pause feature development when requirements are insufficient.

Before analysis, identify each source type, exact URL or other locator, and version. Record each completed analysis with the version analyzed. Build a high-level plan covering the whole feature before planning the first stage of this work. When a PR or branch already exists, map its implementation and validation evidence to the plan and identify a starting stage.

Do not implement ambiguous, contradictory, obsolete, or explicitly deferred requirements without user confirmation.

## Working Artifacts

Maintain a concise scope ledger during feature work:

- **In scope** - requirements selected for the current iteration.
- **Out of scope** - requirements explicitly excluded.
- **Deferred** - valid requirements postponed.
- **Ambiguous** - requirements needing clarification.
- **Validation pending** - behavior implemented but not yet validated.

Maintain a lightweight coverage matrix for substantial features: requirement, source, affected paths, status, code evidence, validation scenario, and residual risk.

Use `acumatica-session-notes` throughout feature work. Record intermediate results, analysis versions, approvals, validation, and deferred work as they arise. Record and surface any doubts about requirements consistency or conflicts with implementation. Record temporary decisions and the conditions for revisiting them.

Before editing product code for a feature slice, create or refresh a stage plan in
the Jira item's session notes and present it for explicit user review/approval.
The plan must state the selected and excluded behavior, requirements and open
decisions, DAC/schema and extension design, relevant lifecycle and exposed-surface
paths, validation, and residual risk. Its status is Draft, Review requested,
Approved, Implemented, then Validated. Do not implement a stage before it is
Approved, and do not treat approval of one stage as approval for later stages or
newly discovered design work.

## Iteration Workflow

1. Load the recorded requirements sources, versions, whole-feature plan, and stage notes. Refresh relevant context and apply the requirements version check at every stage transition.
2. Use `acumatica-git-workflow` to discover or verify the task branch. Before editing, resume or prepare a `feature` branch; a new branch must use a freshly fetched stable ref, and every Git mutation requires explicit user confirmation.
3. Inventory and classify requirements as ready, ambiguous, contradictory, deferred, or rejected for the current phase.
4. Use `acumatica-development-guidance` to retrieve only the architecture, conventions, pitfalls, build, startup, testing, or validation articles relevant to the selected repository and slice. Read exact article resources, compare them with local docs and current code, and record material conflicts.
5. Trace relevant Acumatica data paths: entry/defaulting, validation, persist, release/posting, application/adjustment, reversal/void/delete, long operations, mass processing, recalculation/rebuild, reports/projections/inquiries, workflow, imports, API, copy/template behavior, and UI refresh.
6. Plan a coherent business slice: selected behavior, excluded scope, central extension points, affected paths, customization impact, compatibility impact, validation, and residual risk.
7. Present new architectural choices with your recommendation as described in the Approved Stage Plan in `docs/FEATURE_DEVELOPMENT_WORKFLOW.md`. Record the decision and obtain stage approval before editing product code.
8. Implement the approved minimal slice using existing Acumatica patterns.
9. Validate with focused builds/checks, `git diff --check` or equivalent, path parity review, and manual scenarios when tests are not in scope. Use applicable development guidance to select the narrowest reliable validation, but keep local build files and current-branch behavior authoritative.
10. Use [the stage transition procedure](../../../docs/FEATURE_DEVELOPMENT_WORKFLOW.md#7-report-recheck-requirements-and-approve-the-transition). Save and present the stage report, compare the current requirements sources and versions with the records for the stage, and notify the user of any change. Reanalyze changed requirements and update the plan as needed. Obtain and record approval for stage closure and any next stage before proceeding.

## Implementation Rules

- Prefer existing Acumatica patterns, graph extension points, DAC attributes, accumulator patterns, workflow conventions, and report data-source patterns.
- Prefer graph-owned `protected virtual` methods for behavior that may need customization.
- Keep normal processing and recalculation/rebuild behavior aligned.
- Avoid database queries in frequent UI events such as `RowSelected`.
- For a changed shared or externally consumed field, action, projection, selector,
  status, or endpoint, identify compatibility consumers before changing its shape or
  meaning; do not infer that a screen-only change is isolated.
- Identify new user-facing text and classify it for localization; separately classify
  persisted strings as fixed technical codes, variable technical keys, or user-facing text before selecting storage.
- For reports, trace `rpx -> subreport -> report table -> DAC/projection -> source tables` before changing layout.
- Keep report layout, migration scripts, broad workflow redesign, and automated test expansion out of scope unless explicitly included.
- Preserve existing user changes and unrelated dirty worktree state.
- Use `acumatica-git-workflow` for staging, commit, or push only after explicit user confirmation of those operations.

## Stop Conditions

Stop and report instead of implementing when:

- functional requirements or their source versions are missing or cannot be verified;
- the stage transition still needs a version check or user approval;
- requirement meaning is unclear and likely interpretations produce different persisted data or accounting results;
- spec comments contradict normative text and no later clarification resolves the conflict;
- the slice requires schema redesign, broad workflow changes, report layout work, migration, or large refactoring that was not approved;
- a high-risk accounting, posting, or recalculation change cannot be validated meaningfully;
- local architecture rules would be violated;
- branch, baseline, or repository context cannot be identified confidently;
- the requested work is not covered by an explicitly approved stage plan.

## Validation Methodology

Validation of a feature slice is case-specific. Propose concrete steps proportional to the slice's risk rather than following a fixed script, and agree with the user which steps the agent runs and which the user performs in their environment (see the Environment Interaction Principle in `CLAUDE.md`).

- Validate per implemented slice against its requirement, not the whole feature at once. Keep **Validation pending** items in the scope ledger until covered.
- Trace the Acumatica data paths the slice touches (entry/defaulting, validation, persist, release/posting, recalculation/rebuild, reports/inquiries, import/API, reversal/void) and cover the ones carrying real data or accounting risk. Verify normal-processing and recalculation/rebuild parity when both maintain the same values.
- Choose validation means by need: a build/compile check, a focused automated test (only when tests are in scope), a manual UI/process scenario, or a read-only SQL/diagnostic check. Use the lightest means that can confirm the behavior.
- Builds, test runs, and write/git steps are environment-specific. Propose them and let the user execute when that fits their setup. Never report an unobserved result.
- Record the validation outcome and residual risk per slice using the coverage statuses below. A high-risk accounting, posting, or recalculation change that cannot be validated meaningfully is a stop condition.

## Output

For regular implementation updates, report:

1. current scope and excluded scope;
2. business behavior implemented;
3. key files or paths changed;
4. validation run;
5. known limitations and open or temporary decisions;
6. at the stage boundary, the requirements version comparison and the requested decision on closure and any next stage. Record the user's decision in the stage note.

For coverage reviews, use statuses consistently: **Implemented**, **Partially implemented**, **Missing**, **Unclear**, **Deferred**, and **Not applicable**.
