---
type: change-note
cr: 125294
iteration: 1
updated: 2026-10-21
source: QA comment 10010791 (Sabreen Abubakr, 2026-10-20), ADO back to In Development; Merge Desk ReadyForTest
---

# CR-125294 — iterate 1: grid totals + Paid column

- **What:** the three OData grids get the totals the legacy prints had (legacy designers, root-level GroupFooter2 without group fields = report total): Unpaid Σ BeforeDateAmount / PeriodAdvance / PeriodPayment / EndDateAmount; Advance Σ AdvanceAmount (total + per-employee group, since the grid groups by EmployeeName); Purchase: see open point. The repayments tab `Paid` column shows COMMON._Yes_ / _No_ instead of raw true/false (advance + purchase).
- **Where (front; DB + API for Purchase only):** `report-grid.component.{ts,html}` gets an additive `totalSummaryOptions` input copied from `report-grid-multi-request` (default null, no effect on other reports); `report-grid-multi-request.component.ts` honours `ColumnIndex.CellValueExpr` like `report-grid` already does (no current multi-request consumer passes it); the three shells pass the summary options; advance + purchase detail `Paid` gets a `CellValueExpr`.
- **Test:** `npm run testing` exit 0; in-app on a tenant with data, totals equal parity-results sums (Advance 139,436.23).
- **Risk:** shared grid edits are additive; Excel export carries the summary rows (DevExtreme exports total items).
- **Rollback:** revert the iterate commits on `cr125294` (db, erp, front).
- **Purchase (engineer's call 2026-10-21: add the DB column):** legacy total is Σ instalment `Amount` over all purchases; nothing forces it to equal Σ PurchaseAmount. `PR_EmployeePurchaseReport` gains `RepaymentsAmount` (OUTER APPLY Σ `PR_PurchaseRepayment.Amount`, ISNULL 0), `EmployeePurchase.RepaymentsAmount` in AnalyticsReader, a visible «إجمالي الأقساط / Installments Total» column with total + per-employee group sum. Size now M (DB + API + front); needs the DB, AnalyticsReader and Web Container deploys again.
- **Not acted on:** QA's note on PRs !67197 / !67198 — both were abandoned 2026-10-14 and replaced by !67199 / !67200 from `cr125294_Stage_Beta` (HANDOFF).
