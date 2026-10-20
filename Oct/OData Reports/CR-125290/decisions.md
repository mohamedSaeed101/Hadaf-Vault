# CR-125290 — decisions

Taken by the engineer on 2026-10-15, at the plan gate.

| # | Decision | Effect |
|---|---|---|
| D1 | **Full interactive report grid** on all 5 screens, as in CR-125288 / 125292 D1 (not printOnlyMode). | Each report gets one `odata/<Name>` action in `GLODataController`, an `IAngularReport`, and a seeded ar/en print layout. |
| D2 | **Port the numbers exactly, with the English legacy variant as the reference.** Numeric quirks are reproduced and listed for the PO. **Language-only bugs are not copied**: report 3's Arabic sign flip, report 2's blank Arabic account-type captions, and report 4's swapped Ar/En month names. | Parity requires zero divergence from the English legacy SQL. The TVFs return both En and Ar names, with no `@IsArabic`. |
| D3 | **Keep the old print** as "Print (previous design)": the form's existing Print button is relabelled and still opens the iframe. | No `-legacy` route. |
| D4 | **Reports 3, 4 and 5 stay pivots** ("also use pivot"). | The TVFs return long rows (dimension × item × month), and the print layouts use `XRPivotGrid` (DevExpress 24.2; seeds 0188 and 0376 already use it). The pivot computes the totals, as in the legacy report. The grid shows the long rows, and the user can group them. |

## Quirks reproduced (to report to the PO)
- **Reports 1/2:**
  - The "%" row is always 0 %. Every value is ABS, so the revenue divisor is never set.
  - The YTD budget sums only the sub-periods before the selected one.
  - The Diff columns are ABS, so their GOP sums are not real variances.
- **Reports 3/4:**
  - The budget month is `Acc_AccountBudget.AccountingSubPeriodId` used as a month number, with no year.
  - Only accounts with a budget row appear, so actuals without a budget are dropped.
  - `SELECT DISTINCT` can collapse identical rows.
- **Reports 3/4/5:** the "6 to 12" half starts on June 1, so June appears in both halves.
- **Report 5:**
  - Taxes are Credit − Debit and are then subtracted, so tax raises net profit.
  - `fromMonth` is always 0.
  - The Taxes query has no `number IS NOT NULL` filter.

## Agent changes during P6 (2026-10-16)
- When every journal type is selected, the print header shows "الكل" / "All" instead of ~95 names. The legacy print showed no journal types at all, and the form selects all of them by default. New resx key: `ReportFilterAll`.
