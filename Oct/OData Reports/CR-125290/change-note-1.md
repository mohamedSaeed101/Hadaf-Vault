# CR-125290 — change note 1 (iterate, 2026-10-21)

Trigger: ADO comment 10010794 (Sabreen Abubakr, 2026-10-20). Ticket back to In Development: reports 3, 4 and 5 show no totals in the grid.

- **What:** the report grids of R3 (cost center vs budget), R4 (branch vs budget) and R5 (per month) get default grouping plus summed totals. R3/R4 group by Section > Dimension > account type, and sum Budget / Actual. That gives per-item year totals, per-dimension totals (GOP), the Dimension-section grand total, and the Summary section total (profit). R5 groups by main item > sub item and sums Balance, which gives per-main-item and per-sub-item totals; the profit rows already come from the TVF. Groups follow the legacy order (AccountTypeId for R3/R4; RowNo, which the TVF orders by SortGroup, MainItemId and OrderInReport, for R5), not the alphabetical one. This works through a new optional `ColumnIndex.GroupSortField` in the shared report-grid: on load it records each group's smallest value of that field and orders the groups through `sortingMethod`. `calculateSortValue` was tried first and does not work: DevExtreme 24.2 `getGroupDataSourceParameters` ignores it for groups.
- **Where:** Front only, 9 files.
  - `report-grid/ColumnIndex.ts`: the optional `GroupSortField`.
  - `report-grid.component.ts` (~25 lines): `pagingEnabled` input, `groupOrder` map, `onLoaded` → `buildGroupOrder`, and `sortingMethod` on a column that has `GroupSortField`.
  - `report-grid.component.html`: `<dxo-paging [enabled]="pagingEnabled">` (default `true`, as DevExtreme's own default).
  - The 3 shells `costcenter-income-budget-shell`, `branch-income-budget-shell`, `branch-statment-month-report-shell`: `.ts` (column grouping, `GroupSortField`, `groupSummaryOptions`) and `.html` (`[groupSummaryOptions]`, `[pagingEnabled]="false"`).
  - Paging is off on these 3 grids so that grouping and sums cover the whole result, not one page (review-3 row 1). No TVF, API, layout or parity change.
- **Test:** `npm run testing` exit 0 and prettier clean. In the app, against a tenant with budgets (dbriyadh_Primary, as in the parity run), the group sums equal the legacy pivot totals: per type per year, GOP per dimension, profit.
- **Risk:** low. Default grouping disables manual grouping on these 3 grids, and per-month totals across items are not shown at the same time (decision taken by the engineer on 2026-10-21; the print layouts' pivots still show them). `GroupSortField` and `pagingEnabled` are opt-in (absent / `true` by default), so other reports are unaffected.
- **Rollback:** revert the commit on cr125290.

## Result (2026-10-21, uncommitted)
- `npm run testing` exit 0 (run twice); prettier clean on the changed lines. `report-grid.component.ts` and `ColumnIndex.ts` were already unformatted at HEAD and were left alone.
- App check: built front served on :4200, local AnalyticsReader on :5455 → db-all/Sabreen_Primary. Proof: a `sys.dm_exec_sessions` row with program `cr125290-local-ar` from DESKTOP-KPT7EFB, plus the API log 200. R5 2026 shows its groups with sums. In English the order is Total Profit, Total Profit Before Tax, Net Profit (RowNo order; alphabetical would put Net Profit first). Sabreen has no non-zero balances or budgets, so the sum values were not checked against real figures. Torn down: servers stopped, `SelectedLang` restored to ar-EG, the AnalyticsReader `wwwroot` bundles rewritten by the Debug build were restored.
- Review round 3 ([[review-3]]), Fable 5.1 reviewer plus a Sonnet front anti-pattern scan: 1 block, 2 should, 4 nit. Applied by main (Opus 5.5): row 1 (remote paging could split groups and sums) → `pagingEnabled=false` on the 3 grids. Proof: after the rebuild, the API log on Sabreen shows the R5 requests with no `$top`/`$skip` (before the fix each Preview also sent `$top=10`), and the grid shows no pager. Rows 2, 5, 6 done; nits 3, 4, 7 accepted. Rebuild: the first try was a Node heap OOM while another Node build ran in parallel; the retry gave `npm run testing` exit 0.
- Not verified: sums over more than 20 real rows (no tenant with the new TVFs has that data).
- Next: commit and push cr125290 (Stage_Beta PRs are already merged, so the route to stage needs the engineer's call). The ADO reply draft still needs the engineer's OK. The ADO reply draft is in the session scratchpad and still needs the engineer's OK.

Not code, answered in the ADO reply:
- Sabreen 2026 "no data" (R4) is the same data as legacy. Sabreen's 3 `Acc_AccountBudget` rows have `AccountingSubPeriodId` NULL, so no month matches. Both legacy R4 queries (ComparisonBranchIncome.Fill, Acc_ComparisonIncomeStatment.FillByBranch) return 0 rows (checked on db-all/Sabreen_Primary on 2026-10-21). The old print showed the empty pivot's grand-total captions with 0.
- R1 "%" row always 0: a legacy quirk reproduced on purpose (decisions.md, "Quirks reproduced"). Every value is ABS, so the revenue divisor is never set.
