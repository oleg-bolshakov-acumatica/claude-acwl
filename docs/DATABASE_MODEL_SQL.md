# Projects and Construction SQL Diagnostics

> SQL Server examples checked against Acumatica ERP `2027r150@30696c145fce`.

Choose a path from the [database model](DATABASE_MODEL.md) and interpret the result using the [business model](BUSINESS_MODEL.md). Confirm the schema on the target database, then run each block as a separate, bounded parameterized read through [database-access](../.claude/skills/database-access/SKILL.md). Bind `@CompanyID` to the tenant and the remaining parameters to identifiers or periods from the case. Use a bounded `maxRows` and narrow the predicates if the result is truncated.

Branch visibility depends on the application query and user. When reproducing a screen's result, check the [tenant and branch scope](DATABASE_MODEL.md#tenant-and-branch-scope) and apply the relevant branch filters explicitly. The single-branch history query below is for a known branch. Related documents in other examples can have different branch values.

## Project and budget

Project context by physical key. Check `BaseType` and `NonProject` before interpreting a contract row as an active accounting project.

```sql
SELECT p.ContractID, p.ContractCD, p.BaseType, p.NonProject,
       p.BudgetLevel, p.CostBudgetLevel, p.CuryID
FROM Contract p
WHERE p.CompanyID = @CompanyID AND p.ContractID = @ProjectID
```

One row per budget key. Project and task establish the task relationship. Compare original, revised, pending-change, and actual fields in project currency.

```sql
SELECT b.ProjectID, b.ProjectTaskID, t.TaskCD, b.CostCodeID, b.AccountGroupID,
       b.InventoryID, b.Type, b.CuryAmount, b.CuryRevisedAmount,
       b.CuryDraftChangeOrderAmount, b.CuryActualAmount, b.CuryCommittedOpenAmount
FROM PMBudget b
LEFT JOIN PMTask t ON t.CompanyID = b.CompanyID
    AND t.ProjectID = b.ProjectID AND t.TaskID = b.ProjectTaskID
WHERE b.CompanyID = @CompanyID AND b.ProjectID = @ProjectID
ORDER BY b.ProjectTaskID, b.AccountGroupID, b.CostCodeID, b.InventoryID
```

## Branch-specific project actuals

One history row per budget key, stored period, and branch. This block exposes both financial PTD and transaction PTD series. Select the period and series used by the inquiry before comparing amounts.

```sql
SELECT h.BranchID, h.PeriodID, h.ProjectTaskID, h.AccountGroupID, h.CostCodeID,
       h.InventoryID, h.FinPTDCuryAmount, h.TranPTDCuryAmount
FROM PMHistory h
WHERE h.CompanyID = @CompanyID AND h.ProjectID = @ProjectID
  AND h.BranchID = @BranchID AND h.PeriodID = @PeriodID
ORDER BY h.ProjectTaskID, h.AccountGroupID, h.CostCodeID, h.InventoryID
```

For a known source document, use its original module, document type, and reference in the writer's lineage fields. Inspect the line reference, branch, account groups, release flags, and amounts before reconstructing a budget total.

```sql
SELECT p.TranID, p.OrigLineNbr, p.BranchID, p.ProjectID, p.TaskID,
       p.AccountGroupID, p.OffsetAccountGroupID, p.CostCodeID, p.InventoryID,
       p.Released, p.TranCuryAmount, p.ProjectCuryAmount, p.Amount
FROM PMTran p
WHERE p.CompanyID = @CompanyID AND p.OrigModule = @OrigModule
  AND p.OrigTranType = @OrigTranType AND p.OrigRefNbr = @OrigRefNbr
ORDER BY p.OrigLineNbr, p.TranID
```

## Open commitment and source PO line

One row per matching PO line, with a row for the commitment when the PO link is absent. Use the stored open fields. Check tracking and source line completion state before diagnosing a difference. Inspect the budget targeting and currency rules separately if reconciliation is needed.

```sql
SELECT c.CommitmentID, c.Type, c.Status, c.BranchID, c.ProjectID,
       c.ProjectTaskID, c.AccountGroupID, c.CostCodeID, c.InventoryID,
       c.OpenQty, c.OpenAmount, c.ReceivedQty, c.InvoicedQty, c.InvoicedAmount,
       p.OrderType, p.OrderNbr, p.LineNbr, p.Completed, p.CompletePOLine
FROM PMCommitment c
LEFT JOIN POLine p ON p.CompanyID = c.CompanyID AND p.CommitmentID = c.CommitmentID
WHERE c.CompanyID = @CompanyID AND c.CommitmentID = @CommitmentID
ORDER BY p.OrderType, p.OrderNbr, p.LineNbr
```

## Change Order release and budget lines

One row per Change Order budget line and type, with a header-only row when there are no budget lines. Inspect the header and line states before comparing the stored adjustment against the applicable budget row.

```sql
SELECT c.RefNbr, c.ProjectID, c.Status, c.CostReleased, c.Released,
       b.LineNbr, b.Type, b.Released AS LineReleased, b.ProjectTaskID,
       b.AccountGroupID, b.CostCodeID, b.InventoryID, b.Amount
FROM PMChangeOrder c
LEFT JOIN PMChangeOrderBudget b ON b.CompanyID = c.CompanyID AND b.RefNbr = c.RefNbr
WHERE c.CompanyID = @CompanyID AND c.RefNbr = @ChangeOrderNbr
ORDER BY b.LineNbr, b.Type
```

## Billing and AR release

Start with the billing record when looking for a direct AR result. This example returns one row per billing tag for one project run record. A populated pro forma reference is a cue to inspect its revision separately.

```sql
SELECT b.RecordID, b.BillingTag, b.ProformaRefNbr, b.ARDocType, b.ARRefNbr,
       a.Released AS ARReleased, a.Status AS ARStatus, a.CuryID, a.CuryDocBal
FROM PMBillingRecord b
LEFT JOIN ARRegister a ON a.CompanyID = b.CompanyID
    AND a.DocType = b.ARDocType AND a.RefNbr = b.ARRefNbr
WHERE b.CompanyID = @CompanyID AND b.ProjectID = @ProjectID AND b.RecordID = @RecordID
ORDER BY b.BillingTag
```

Use the exact pro forma revision from the case. The left join retains a revision with no linked AR record and exposes the AR release state when present.

```sql
SELECT p.RefNbr, p.RevisionID, p.Released AS ProformaReleased, p.Corrected,
       p.ARInvoiceDocType, p.ARInvoiceRefNbr, a.Released AS ARReleased,
       a.Status AS ARStatus, a.CuryID, a.CuryDocBal
FROM PMProforma p
LEFT JOIN ARRegister a ON a.CompanyID = p.CompanyID
    AND a.DocType = p.ARInvoiceDocType AND a.RefNbr = p.ARInvoiceRefNbr
WHERE p.CompanyID = @CompanyID AND p.RefNbr = @ProformaRefNbr AND p.RevisionID = @RevisionID
```

## AP document line and payment applications

For project attribution, match the AP line to its typed header and display the line account's group. A group association is one input to release processing. Investigate retainage document type and actual transaction lineage separately. For an AR inquiry, the corresponding tables are `ARTran` and `ARRegister` and the line type is also `TranType`.

```sql
SELECT l.TranType, l.RefNbr, l.LineNbr, h.Released AS BillReleased,
       l.BranchID, l.ProjectID, l.TaskID, l.CostCodeID, l.AccountID, a.AccountGroupID
FROM APTran l
JOIN APRegister h ON h.CompanyID = l.CompanyID
    AND h.DocType = l.TranType AND h.RefNbr = l.RefNbr
LEFT JOIN Account a ON a.CompanyID = l.CompanyID AND a.AccountID = l.AccountID
WHERE l.CompanyID = @CompanyID AND l.TranType = @APDocType AND l.RefNbr = @APRefNbr
ORDER BY l.LineNbr
```

For settlement, use applications of the affected bill. The adjusted and adjusting branches are exposed separately. Verify voids and cash records as needed for the payment question.

```sql
SELECT a.AdjdDocType, a.AdjdRefNbr, a.AdjdLineNbr, a.AdjdBranchID,
       a.AdjgDocType, a.AdjgRefNbr, a.AdjgBranchID, a.AdjNbr, a.Released
FROM APAdjust a
WHERE a.CompanyID = @CompanyID AND a.AdjdDocType = @APDocType AND a.AdjdRefNbr = @APRefNbr
ORDER BY a.AdjgDocType, a.AdjgRefNbr, a.AdjNbr, a.AdjdLineNbr
```

## Direct PM and GL links

One row per linked GL line, or one PM-only row when the direct link is absent. Separate PM release from GL batch posting. For a PM-only result, check the originating operation and its posting rules.

```sql
SELECT p.TranID, p.Released AS PMReleased, p.BranchID AS PMBranchID,
       g.Module, g.BatchNbr, g.LineNbr, g.BranchID AS GLBranchID,
       g.DebitAmt, g.CreditAmt, b.Posted AS BatchPosted
FROM PMTran p
LEFT JOIN GLTran g ON g.CompanyID = p.CompanyID AND g.PMTranID = p.TranID
LEFT JOIN Batch b ON b.CompanyID = g.CompanyID AND b.Module = g.Module
    AND b.BatchNbr = g.BatchNbr
WHERE p.CompanyID = @CompanyID AND p.TranID = @TranID
ORDER BY g.Module, g.BatchNbr, g.LineNbr
```

## Compliance and joint payees

For a known AP line, inspect compliance bill links using the full document and line reference. This identifies one kind of link. For a scenario using typed references, follow `ComplianceDocumentReference` and the relevant document note identity. Check the enforcement setup and attempted action separately.

```sql
SELECT l.DocType, l.RefNbr, l.LineNbr, d.ComplianceDocumentID,
       d.ProjectID, d.Required, d.Received, d.Status, d.ExpirationDate
FROM ComplianceDocumentBill l
JOIN ComplianceDocument d ON d.CompanyID = l.CompanyID
    AND d.ComplianceDocumentID = l.ComplianceDocumentID
WHERE l.CompanyID = @CompanyID AND l.DocType = @APDocType
  AND l.RefNbr = @APRefNbr AND l.LineNbr = @APLineNbr
ORDER BY d.ComplianceDocumentID
```

For the same line, inspect the payee and any payment assignments. The result is at payee and assignment grain. Follow the payment references for release, application, and cash evidence.

```sql
SELECT j.JointPayeeID, j.APDocType, j.APRefNbr, j.APLineNbr, j.CuryJointAmountOwed,
       p.JointPayeePaymentId, p.PaymentDocType, p.PaymentRefNbr,
       p.CuryJointAmountToPay, p.IsVoided
FROM JointPayee j
LEFT JOIN JointPayeePayment p ON p.CompanyID = j.CompanyID AND p.JointPayeeID = j.JointPayeeID
WHERE j.CompanyID = @CompanyID AND j.APDocType = @APDocType
  AND j.APRefNbr = @APRefNbr AND j.APLineNbr = @APLineNbr
ORDER BY j.JointPayeeID, p.JointPayeePaymentId
```

## RFI to Change Request and Change Order

One row per saved Change Request linked to the RFI, with an RFI-only row when none is found. Inspect the cost and general Change Order references separately and use the release states to choose the next check. For a Project Issue, use the corresponding `PMChangeRequest.ProjectIssueID` relationship.

```sql
SELECT r.RequestForInformationId, r.RequestForInformationCd, r.Status AS RFIStatus,
       q.RefNbr AS ChangeRequestNbr, q.CostChangeOrderNbr, q.ChangeOrderNbr,
       c.CostReleased, c.Released AS CostOrderFullyReleased,
       o.Released AS ChangeOrderReleased
FROM RequestForInformation r
LEFT JOIN PMChangeRequest q ON q.CompanyID = r.CompanyID AND q.RFIID = r.RequestForInformationId
LEFT JOIN PMChangeOrder c ON c.CompanyID = q.CompanyID AND c.RefNbr = q.CostChangeOrderNbr
LEFT JOIN PMChangeOrder o ON o.CompanyID = q.CompanyID AND o.RefNbr = q.ChangeOrderNbr
WHERE r.CompanyID = @CompanyID AND r.RequestForInformationId = @RFIID
ORDER BY q.RefNbr
```
