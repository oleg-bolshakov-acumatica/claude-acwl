# Projects and Construction Business Model

> Reference revision: Acumatica ERP `2027r150@30696c145fce` (2026-11-26).
>
> Scope: Project Accounting (PM), Construction (CN), and Construction Project Management (PJ).

Use this guide to identify the business event, the owner of each result, and the conditions that affect it. Check the target version, enabled features, and document state before applying a branch-specific example. Use the [code navigation guide](CODE_NAVIGATION.md) to locate the implementation. Use the [database model](DATABASE_MODEL.md) to orient a data investigation and verify physical keys and joins against the schema on the target branch.

## Core business model

**PM** provides project and task attribution, project financial controls, and billing policy. **CN** adds construction controls such as subcontracts, compliance, and joint payments. **PJ** owns field coordination and supporting evidence. One process may cross all three domains and several ERP modules. Follow each transition to the document that owns the resulting state.

| Business question | Primary evidence | What determines the answer |
|---|---|---|
| What was planned? | Original project budget | Budget setup, original values, and budget lock state |
| What is the current budget? | Revised project budget | The budget side and applicable changes. See [Change control](#change-control). |
| What change is under consideration? | Pending change documents | Determine which scope, cost, or revenue changes are still pending. See [Change control](#change-control). |
| What outcome do we expect? | Selected Budget Forecast or Cost Projection revision | Check its inputs and estimates of remaining work. |
| What is committed or still open? | PM commitment linked to the purchase or subcontract line, or an external commitment | Tracking setup and the state of the originating line. See [Procurement and commitments](#procurement-and-commitments). |
| What cost or revenue is reflected in PM? | Released project transactions and the corresponding project balance | The source event, account group, currency, and budget level. See [Actuals and project balances](#actuals-and-project-balances). |
| What can we bill now? | Eligible project transactions or progress against the revenue budget | The billing rule, rate, billable basis, and period or cutoff |
| What was invoiced or paid? | AR or AP document and its payment applications, with CA records for cash activity | Document release and settlement each have their own state. See [Billing, retainage, and settlement](#billing-retainage-and-settlement). |
| What is held back or blocking payment? | AR/AP retainage state or the applicable CN compliance control | Determine whether the question is about the withheld amount, eligibility to proceed, or allocation of the payment. |
| What explains a field decision? | PJ document and linked project evidence | Follow any subsequent change or financial document before attributing a financial effect. |

Apply these distinctions by asking which result changed. For example, the same work may have an actual cost, a separately calculated billable amount, a released invoice, and an outstanding payment balance. Each amount answers a different question.

## Project setup and attribution

- **Project** is the business boundary for attribution and control. **Project Task** belongs to a project and identifies work within it. Check the task's state and eligibility for the operation. `Non-Project` is a special designation used for activity outside project accounting.
- **Account Group** classifies amounts in PM and connects applicable GL accounts to the project budget and actuals. **Cost Code** adds work or cost breakdown. **Inventory Item** identifies the material, service, or labor item where the process uses that dimension. Pay and work classifications such as union or certified labor serve a separate labor purpose.
- **Project Template** supplies defaults such as tasks, budget structure, and billing policy. **Project Group** organizes projects and can participate in project visibility. A **Project Management Class** supplies defaults or policy for PJ documents.
- **Project Quote** captures the proposed commercial scope before execution. An opportunity can provide context for a quote. Quote conversion is a separate action that creates or seeds the project and its setup, subject to the conversion options.

Check project and task on the relevant source line. A header may carry a default or constrain the lines in some configurations. Follow the values that reach the actual downstream line.

## Core processes

### Budget and forecast

Original budget records the baseline. Revised budget is the current controlled plan. Check the budget lock when evaluating edits to the original budget. Check the change-order workflow setting when evaluating direct edits to the revised budget.

Cost and revenue budgets have **separately configurable budget levels**. Both use project, task, and account group. The selected level determines the use of inventory item and cost code for targeting a budget line. Match amounts at the applicable level before reconciling a balance.

Pending changes show potential changes to scope or amounts. A Budget Forecast or Cost Projection revision expresses an expected outcome using the inputs of that process, such as budget, commitments, actuals, and estimates of remaining work. Confirm which revision and assumptions are displayed when comparing a forecast with the revised budget.

### Procurement and commitments

Purchasing owns the PO and receipt. CN adds Subcontract behavior for construction purchasing. PM tracks the related cost commitment for qualifying lines when **Internal Cost Commitment Tracking** is enabled. External commitments provide a separate way to track an obligation.

For an open commitment question, check the originating line and the state used by the tracking process. Check received and billed quantities separately from the open amount and whether the line is closed. Follow a receipt to its inventory effect where applicable, and a vendor bill to its payable and applicable project-cost effect. A change can also adjust an existing purchasing obligation through the applicable Change Order process.

### Actuals and project balances

Project actuals can come from released operational or financial documents, direct PM transactions, or released derived transactions such as allocations. Trace the original document or initiating operation, then the release, posting, or processing step that produces the PM effect. Follow the linked adjustment or reversal when the source was corrected.

Project budget balances aggregate effects at the applicable cost or revenue budget level. The balance calculation can apply sign rules and account for an offset account group. Align project, task, budget dimensions, account group, and currency before comparing transaction totals with the budget. Distinguish transaction, project, and base currency in PM and the relevant document currency in the source module.

Release and posting are separate checkpoints when tracing GL. A released PM transaction can contribute to project tracking without a GL batch, for example on an off-balance path. Explore [GL in the module matrix](#adjacent-modules) for both directions of the integration.

### Billing, retainage, and settlement

1. **Billable basis.** Project billing can use eligible time and material transactions or budget and progress values, according to billing rules. Where used, a Progress Worksheet records progress. Verify how that progress reaches the billing basis.
2. **Calculation.** Rules govern pricing, rates, markups, grouping, and selection. Labor cost, billable quantity, and the amount billed are separate measures.
3. **Invoice creation.** PM billing creates an AR document directly or creates a pro forma for review, depending on project setup. In the pro forma path, its release generates the AR document.
4. **Invoice release and settlement.** Check the AR document's release separately from its creation. Check payment applications and cash activity when the question concerns collection. In the payable flow, apply the same separation to the vendor bill and payment.

Allocation can derive or redistribute PM transactions. WIP and unbilled records can explain accounting or billing timing. Trace each to the underlying activity and the effect of its own process.

**Retainage** is part of the amount withheld from settlement on the receivable or payable side. Trace what was withheld, what was separately released, and what has been collected or paid. The held amount and the underlying earned or incurred amount answer different questions. For payment eligibility or recipients, use the [construction controls](#construction-payment-controls).

### Change control

- A **Change Request** records a proposal and its estimated scope, cost, or revenue impact. When used, it can feed a related Change Order.
- A **Change Order** is the document for applying a scope change through the configured workflow. It can exist before approval. Approval, applicable release, and the resulting budget or commitment effect are separate facts.
- On a **cost-only release**, the cost side is applied while revenue budget lines await full release. Check related commitment changes independently. On full release, verify the applicable remaining cost and revenue effects and follow the released lines to the revised budget or the affected purchasing document. Use individual line state when investigating a partial result.

### Project inventory

IN owns stock movement and valuation. Project inventory settings determine how the system tracks material, including location tracking, project quantity, or project quantity and cost. For project stock questions, follow the warehouse or location and applicable project/task context on the receipt, issue, transfer, or return. Check which movement and release path carries a cost effect to PM.

### Construction payment controls

**Compliance** tracks obligations and eligibility, such as whether a required lien waiver is outstanding. Check the required document, its applicability to the vendor, subcontract, bill or payment, and the rule for the action being attempted. For example, an outstanding lien waiver can prevent an AP payment from being removed from hold when the stop-payment setting applies. Establish separately whether the applicable path warns, blocks, or allows the operation.

**Joint Payment** controls allocation of settlement between the vendor and additional payees in the applicable AP process. Determine the bill, payees, payment applications, and actual cash movement. **Retainage** answers a separate question about amounts held for later settlement.

### Field coordination and evidence

**RFI** tracks a request for clarification. **Project Issue** tracks a field or coordination problem through assignment and resolution. Either can initiate a Change Request. For financial impact, follow the created request to its related Change Order and check the release described in [Change control](#change-control).

**Daily Field Report** captures site activity. **Drawing Log** tracks drawings and revisions. **Photo Log** captures visual evidence. **Submittal** tracks packages for review and approval. **Project Files** organize linked documents and evidence. Use these records for field context and traceability to any separately created PM, CN, or financial document.

## Adjacent modules

| Module | Owner and source documents | Transition to check in a project inquiry |
|---|---|---|
| **AR** | Customer invoices, credit memos, receivables, and payment applications | PM billing can create the AR document. Release of a project-linked AR document can feed back into PM. Trace retainage and settlement on the AR side. See [Billing](#billing-retainage-and-settlement). |
| **AP** | Vendor bills, adjustments, payables, and payment applications | For project cost, trace the bill line through release and account-group mapping. Check whether the document is the original bill or a child retainage document because the release path treats project attribution differently. For payment, check AP settlement and applicable CN controls. |
| **GL** | Accounts, journal transactions, batches, and posting | Trace GL-to-PM effects through eligible project lines and account-group mapping. Trace PM-to-GL effects through the batch produced by a qualifying release and its posting state. |
| **PO** | Purchase orders and receipts | Determine whether the line generates a tracked PM commitment, including the construction subcontract path. Follow receipts and bills to the modules that process them. See [Procurement and commitments](#procurement-and-commitments). |
| **SO** | Sales orders, shipments, and the commercial context for invoicing | Follow order-line project attribution into the shipment or invoice as applicable. Check IN for the stock movement and AR for the customer invoice. These paths can reach PM through different processing steps. |
| **IN** | Items, stock movements, and inventory valuation | Check inventory tracking mode, movement, and release for project quantity or cost. See [Project inventory](#project-inventory). |
| **CA** | Cash accounts and cash transactions | Trace payment applications in AR/AP to cash activity. For a project-attributed cash adjustment, follow the split through release to the accounting lines. |
| **EP** | Employee activities, time cards, and expense claims | Time release can produce project transactions. Follow the applicable expense processing path for reimbursement and project cost. Keep time entry, cost, and billing eligibility distinct. |
| **PR** | Payroll earnings, deductions, and labor classification outcomes | Check project/task attribution and certified labor where applicable. Reconcile payroll earnings with project labor cost and billing using the applicable source and rate policy for each. |
| **CR** | Opportunities, business accounts, contacts, and relationship context | Trace a proposal through the Project Quote and its conversion when determining when project execution and accounting begin. |
| **TX** | Tax calculation and tax state on the source document | Check project-specific defaults where enabled. For example, an SO document may use the project's revenue tax zone, subject to the document's override. |

## Configuration and cross-module boundaries

Project Accounting, Construction, and Construction Project Management enable different capabilities. Check the applicable feature and the document's own setup when a path is absent or behaves differently. For example, Parent-Child Projects can roll qualifying amounts from a child to a parent. Before consolidating figures, identify the originating project and any configured rollup so the same effect is counted once.

Ownership follows the result. Use PM for a change to project attribution, budget control, or billing policy. Follow the owning document for commercial, stock, accounting, or cash state. When a result crosses modules, preserve the references that explain how the source document led to each downstream effect.

## Questions to resolve

1. What happened in the business, and which result is being questioned?
2. Which module and document own that result?
3. At what level and in which currency is the result recorded or calculated?
4. Which action, document state, and setting determine when the result changes?
5. Which source line, downstream document, or balance confirms the effect?
