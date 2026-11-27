# Projects and Construction Database Model

> Reference revision: Acumatica ERP `2027r150@30696c145fce` (2026-11-26).
>
> Scope: SQL Server storage and document relationships for Project Accounting (PM), Construction (CN), and Construction Project Management (PJ).

Start from the business event and the result it should change. Use the [business model](BUSINESS_MODEL.md) for ownership and process semantics and the [code navigation guide](CODE_NAVIGATION.md) to find the implementation. Confirm physical tables, columns, and keys in the target revision of `DatabaseModel`. Use the DAC, graph, and workflow to explain how a value is calculated or updated. Use the target database to establish the actual document state. The [SQL examples](DATABASE_MODEL_SQL.md) provide starting queries for the paths below.

## Tenant and branch scope

- **`CompanyID` identifies the tenant partition.** For tenant-partitioned records, filter by the known tenant and carry `CompanyID` in joins between partitioned tables. Check the schema for shared or system tables and the platform sharing rules when comparing with application results.
- **`BranchID` records business branch attribution.** The query provider can also add branch predicates for supported tables using the application's access context and active query scope. A screen or inquiry may apply additional branch or organization criteria. When comparing a screen with raw SQL, use the same user-visible branch scope for the diagnosis and confirm which branch field the screen uses. Raw diagnostic queries must express their own branch filters where relevant.
- **Use branch equality where the relationship requires it.** A source document, an application of payment, and the resulting accounting lines can involve different branches. `PMTran` stores `BranchID`, `PMHistory` includes it in the key, and `PMBudget` has no branch column. For a branch-specific inquiry, select the transaction or history grain before comparing with a project budget total.

For schema discovery and bounded reads, use the [database-access skill](../.claude/skills/database-access/SKILL.md). For application restrictions, start at `NetTools/PX.Data/Database/Common/DbProviderBaseCompanies.cs` and check the relevant query scope and BQL branch predicates.

## How to read keys and values

- Use the **full key of the relationship**. A line may require a document type, number, revision, and line number. DAC keys and `FK`, `PXParent`, or `PXForeignReference` declarations explain application relationships. DDL establishes physical keys and constraints. Check the actual writers for a link populated by a process.
- Confirm how a value reaches the screen. A DAC may use an existing table, a mapped extension table, a projection with its own persistence mapping, or transient values. For example, `PMProject` uses `Contract`, `Subcontract` reads the subcontract type of `POOrder`, and `PMQuote` projects CRM quote and opportunity data. `PMBudget.CuryVarianceAmount` is computed in the DAC. Inspect its calculation and inputs if needed.
- Interpret status and flags for the specific document and action. Check the document type, revision, release state, correction or reversal, and the related header and lines. In a reconciliation, align grain, sign, currency, and period. Check cardinality before aggregating.
- Use the [architecture rules](ARCHITECTURE_RULES.md) for DAC/SQL design and data types.

## Storage by business question

The keys below include `CompanyID` for the listed tenant tables. Where the rest of a key is shown by itself, it applies within that tenant.

| Question | Physical starting point and grain | Decisive check |
|---|---|---|
| Which project and task? | `Contract` by `ContractID`. `PMTask` by `ProjectID + TaskID`. | Distinguish project, template, and non-project through `BaseType` and `NonProject` as applicable. Use `ContractCD` and `TaskCD` for business lookup. |
| What did the project plan or revise? | `PMBudget` by `ProjectID + ProjectTaskID + CostCodeID + AccountGroupID + InventoryID`. | Read original, revised, change, and actual fields for the same row. Determine the cost or revenue budget level from `Contract`. |
| Which outcome is forecast? | `PMForecast` by project and revision, and `PMForecastDetail` by revision, budget dimensions, and period. For Cost Projection, start with the relevant `PMCostProjection*` header and lines. | Select the relevant revision before comparing with the baseline or current budget. |
| What was committed or remains open? | `PMCommitment` by `CommitmentID`. Internal PO/subcontract tracking can use `POLine.CommitmentID`. | Check the stored open fields, the source line state and completion method, and the amount's currency. |
| What reached project actuals? | `PMTran` by `TranID`. `PMRegister` by `Module + RefNbr`. `PMHistory` by the budget dimensions plus `PeriodID + BranchID`. | Trace origin and release. Compare a history or budget accumulator only at its own grain. |
| Which change was applied? | `PMChangeOrder` by `RefNbr`. `PMChangeOrderBudget` by `RefNbr + LineNbr + Type`. `PMChangeOrderLine` by `RefNbr + LineNbr`. | Inspect header and line release states. Trace the budget row separately from the procurement line. |
| What did billing create? | `PMBillingRecord` by `ProjectID + RecordID + BillingTag`. `PMProforma` by `RefNbr + RevisionID`. Pro forma lines add `LineNbr`. | Follow the applicable direct AR or pro forma path. Check corrections and release before drawing conclusions about a financial effect. |
| Was an invoice or bill settled? | `ARRegister` or `APRegister` by `DocType + RefNbr`, plus `ARAdjust` or `APAdjust` and applicable CA records. | Check application type, both documents, status, and cash movement. Handle retainage separately. |
| Why was an AP payment blocked or split? | `ComplianceDocument`, its typed references or bill links, and `LienWaiverSetup`. For a split, use `JointPayee` and `JointPayeePayment`. | Confirm the linked bill, enforcement setting, payment action, and actual AP settlement. |
| Which field evidence led to a financial change? | `RequestForInformation` or `ProjectIssue` linked through `PMChangeRequest`. Daily reports and project files have separate relationship tables. | Establish a saved relationship and follow the actual Change Order and line releases. |

## Key diagnostic paths

### Budget, actuals, and derived values

Use `Contract.BudgetLevel` for revenue and `Contract.CostBudgetLevel` for cost where selected by the budget service. The physical key of `PMBudget` always includes the item and cost-code columns. The targeting logic can normalize those dimensions and considers account-group classification, including the expense flag. Find the default cost code through `PMCostCode.IsDefault` and verify any item placeholder in the relevant code path.

For a discrepancy, trace the released transaction, its account group and possible offset group, the amount sign, and the budget row selected by `BudgetService` and `ProjectBalance`. A raw sum of `PMTran.ProjectCuryAmount` is a first comparison. A balance reconstruction also needs the release and rollup rules. For `PMHistory`, keep branch and period, and choose the financial or transaction series and PTD or YTD to match the inquiry. For Parent-Child Projects, identify the originating and rolled-up effects before combining project totals.

Treat `PMTaskTotal`, history, and unbilled summaries as accumulated results. For unbilled and WIP questions, follow `PMTran` and, where applicable, `PMUnbilledDailySummary`, `PMWipAdjustment` and its lines, and the resulting AR or GL records. Trace quote conversion from CRM quote storage and `PMQuoteTask` to the resulting project and tasks. Check the conversion and defaults when a quoted task is missing on the project.

### Procurement and change documents

Within the tenant, follow `POLine.CommitmentID` to `PMCommitment.CommitmentID` on the tracked purchase/subcontract path. Keep `OrderType + OrderNbr + LineNbr` when tracing the PO line, receipt, or AP bill line. An external commitment may have its own reference. In the PO path, amounts are converted to project currency and open values are calculated using line eligibility and completion rules. Read the stored `OpenQty` and `OpenAmount`. For reconciliation, apply budget targeting and currency rules before comparing with any `PMBudget` commitment amount.

Use `PMChangeRequest.ChangeOrderNbr` and `CostChangeOrderNbr` as applicable. Inspect `PMChangeOrder.CostReleased`, `Released`, and line release state. Use `PMChangeOrderBudget.Amount` for the stored adjustment and verify the amount's basis along the release path. Cost-only release can affect the cost budget and procurement lines while the revenue budget awaits full release.

### Billing, retainage, and settlement

For direct billing, follow `PMBillingRecord.ARDocType + ARRefNbr` to `ARRegister.DocType + RefNbr`. For the pro forma path, use the selected `PMProforma` revision, its `Released` and `Corrected` flags, and its AR invoice references. A `ProformaRefNbr` by itself can identify more than one revision.

For billing links to a specific `ARTran` line, use `PMTran.ARTranType + ARRefNbr + RefLineNbr` where the billing path populates those values. For original-document lineage, start with `OrigModule + OrigTranType + OrigRefNbr` and include `OrigLineNbr` where meaningful and available. Follow the source path when the fields refer to a different stage of the document chain. A PM billed flag records billing participation. Determine invoice release and payment from the related AR records.

Treat `PMBudget.CuryInvoicedAmount` as a budget accumulator. Check the process that updates it and its interaction with actuals, pending billing, corrections, and retainage before comparing with totals from AR documents. For cash or withholding questions, follow the applicable original and retainage AR/AP documents and their payment applications. Use the adjusted and adjusting document references, line and application sequence where relevant, and verify the related cash record in CA.

### Financial and operational sources

| Source | Trace to the project result |
|---|---|
| **AR/AP** | Header keys use `DocType + RefNbr`. `ARTran` and `APTran` use `TranType + RefNbr + LineNbr`. Take project and task from the relevant line and resolve the applicable GL account's `AccountGroupID`. Follow release processing, including the original versus child retainage distinction. |
| **GL ↔ PM** | When populated, use `GLTran.PMTranID → PMTran.TranID`. One PM transaction can link to several GL lines. Inspect `Batch` by the GL line's `Module + BatchNbr` when checking posting. `PMTran.TranType` identifies the PM register module. PM may have actuals without a GL batch. |
| **PO → IN/AP** | Match PO and receipt line keys to the references actually stored on the AP line. Use the receipt movement for stock and the released AP or IN path for project cost as applicable. |
| **SO → IN/AR** | Start with `SOLine` and the related shipment line or AR line. Follow the recorded shipment or order-line references, then inspect `INTran` for stock or `ARTran` for invoicing. For project stock, verify the tracking mode and applicable `INCostCenter` mapping. |
| **CA** | Use the associated cash record for movement. For a cash adjustment, follow its project/task split through release to the accounting lines. |
| **EP and PR** | Start with the time activity, expense claim, or earning detail and trace the relevant release or payroll entry. Check which record supplies project labor cost and which supplies the billable basis. |
| **CR and TX** | Use CRM quote/opportunity records for the proposal context. For tax, check the owning document's tax zone and tax records together with any project-specific defaults. |

### Construction controls and field evidence

Use the populated link for the scenario. A compliance document can point through `ComplianceDocumentReference` using a reference ID, document type/number, or note identity. For bill-line links, `ComplianceDocumentBill` carries the bill type, number, and line. A linked document establishes the relationship. Check the applicable enforcement settings and the user's attempted action for an explanation of blocking or warnings. Joint-payee rows and assignments describe the split. Follow their payment references to confirm settlement in AP/CA.

For an RFI or issue, look up `PMChangeRequest.RFIID` or `ProjectIssueID` and follow the linked Change Order where present. For a Daily Field Report, inspect the relevant relationship table after identifying the report. For Project Files, `PMProjectEntity` links the project to document and entity note IDs. Follow the note reference to its owner for workflow or financial state.
