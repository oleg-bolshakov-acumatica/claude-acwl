---
name: acumatica-projects-product-research
description: Research business questions about Acumatica ERP Project Accounting and Construction. Use when someone asks how a process works today, whether configuration already covers a need, where a similar feature exists, or what would change if a proposed capability were added or extended. Select by the requested analysis even when the user gives no role, Jira key, or formal specification.
---

# Projects and Construction Product Research

## Identify the business decision

Start from the analyst's question. Identify the actor, business event and outcome they care about. Treat a suggested field, calculation or workflow as a candidate solution. Check whether an existing setting or process meets the need. When two interpretations would yield different answers, illustrate the difference with one realistic transaction and ask for the product decision that evidence alone cannot settle.

An attached specification or Jira issue can supply context for this research. Route an explicit request to assess a written specification's readiness to `functional-spec-risk-analysis`, a request to diagnose a customer incident to `acumatica-support-request-analysis`, and a request for a technical design document to `acumatica-technical-specification`. Keep product research read-only.

## Verify current behavior

- Start with [the business model](../../../docs/BUSINESS_MODEL.md) for process ownership and terms. Use [code navigation](../../../docs/CODE_NAVIGATION.md) and [the database model](../../../docs/DATABASE_MODEL.md) to locate the relevant implementation and storage. Search the source tree directly when the map runs out.
- Inspect the requested release or establish the relevant current baseline through read-only Git discovery. Record the product branch and commit. Follow the user action or document transition to the component that owns the result, including adjacent modules and platform code where relevant. Check the feature settings, document states and entry paths that could change the answer. Qualify conclusions if the target version or freshness cannot be verified.
- Use `wiki-access` for requirements and review comments, and `acumatica-development-guidance` for repository guidance when it affects feasibility. Open the exact guidance article. Use `database-access` for a bounded read-only SELECT when actual records can distinguish explanations. Establish the environment, tenant and relevant branch access. A persisted amount and the amount visible to a user with pending edits can require different evidence.
- Cross-check each conclusion that affects the decision against independent evidence, such as release code and a test with an expected amount. Repeated wording in Jira and Wiki represents one account. If sources disagree, identify the scenario, version, setup or document state that could explain it. State which conclusion still holds and what would resolve the discrepancy.

When a broad trace would flood the main context, you may dispatch read-only subagents with the resolved revision, tenant and question: `acumatica-source-investigator` for code paths in `code/`, `acumatica-sql-diagnostics` for bounded tenant-scoped reads, and `acumatica-context-digest` for large Jira or Wiki sets. Keep the framing of the business question, the cross-checks and the final answer in the main agent.

## Find relevant Jira precedents

Follow supplied keys and relevant links through `jira-access` first. When an earlier implementation, related proposal or rejected approach could affect the recommendation, search through the read-only `jira-internal` tool `jira_search`. A feature idea can be the starting point even without a source issue. Build a narrow JQL search from the business operation and a distinguishing term, such as a document type, screen ID or adjacent module. Include feature and change work as well as relevant fixes. Refine the terms if the first search yields only superficial matches.

Open promising issues with `jira-access`. Check the decision, status, target or fix version and linked specification or PR as relevant. Use `bitbucket-pr-access` for a specific PR. Before describing a capability as available, verify it in the target product revision. An open proposal can reveal overlap, and a declined idea can explain a constraint. Report material precedents with a Jira link, what was delivered or decided, and which similarity or difference matters here. If a search is inconclusive, qualify its coverage.

## Assess options and answer

Test the analyst's premise against a counterexample, such as a partial payment, reversal or different feature setting, chosen for the question. Compare feasible options by their business effect. For a reuse proposal, identify the existing component, the rule both processes share and the point where the analogy breaks. Use [architecture rules](../../../docs/ARCHITECTURE_RULES.md) and [implementation patterns](../../../docs/FEATURE_IMPLEMENTATION_PATTERNS.md) to explain concrete consequences for users, accounting, integrations or consistency across document states.

Write in the analyst's language. Lead with the answer and its conditions. For a narrow lookup, a concise finding and evidence suffice. For a product decision, cover:

1. **Current behavior.** Explain what the user sees, which event produces it and where it was verified. Cite decisive source as `path:line` at the inspected revision, a versioned specification section, a test or a scoped data observation alongside the relevant claim.
2. **Options and recommendation.** Explain which premise holds, the relevant precedent and the trade-off that changes the choice. Distinguish verified behavior, intended behavior and proposed design. For a consequential hypothesis, give its basis and a practical way to disprove it.
3. **Open decisions.** Surface additional questions or research directions that could change the recommendation. Explain why each matters. Resolve discoverable technical facts during the investigation and direct business policy choices to the analyst.
