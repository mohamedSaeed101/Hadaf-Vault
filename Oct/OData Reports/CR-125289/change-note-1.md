# CR-125289 — change note 1 (QA return, 2026-10-20)

Source: ADO comment 10010795 (Sabreen Abubakr, 2026-10-20), state back to In Development. Iterate path: Merge Desk ticket 12514 is Solved with the stage PRs merged; same branch `cr125289`, no new PR.
The comment's screenshot `125289-brief-income-mismatch.png` could not be read: ADO returned VS402330 (unauthorized area read).

## Findings (2026-10-21, read-only)

| # | QA point | Cause found | Status |
|---|---|---|---|
| 1a | Brief (R1) on Beta/Sabreen shows 0 / 0 / net 1,250 vs legacy 1,879,185.13 / 4,448,762.71 / (2,570,827.58) | Not reproduced yet. 1,250 = the tax line alone (NetProfit = NPBT + ROUND(ABS(tax))), so the screen's request hits a window or lists where only a tax journal exists. The shell, form, checklists and API parse the same values the legacy route takes; the TVF matched the legacy on 13 param sets. A live request is needed. | blocked: db-all needs VPN; Beta pane is at the sign-in page |
| 1b | Net loss shows positive | `Total` is ABS by design (D2); the sign lives in the hidden `IsNegativeShownInParens`. The grid never renders the parens. | fix: R1 Total (and NPBT) shown in parentheses when the flag is set, as the legacy print does |
| 2 | R4/R5/R6 grids have no totals | report-grid has group summaries only (`groupSummaryOptions`); the shells pass none; no total-summary support exists. Legacy is a pivot (item × branch) with row totals, column totals and the surplus/deficit. | design question to the engineer |
| 3 | Percentage shows 0.35 | `report-grid.component.ts:741` sets `customizeText = value.toLocaleString('en-US')` on every column, overriding `Format: 'percent-m'` (and `money`). | fix: per-column `CustomizeText` hook in ColumnIndex, used by the percent columns (R2, R7) |
| 4 | R7 (detail by activity) returns nothing without a cost center | The legacy cost-center form already has `costCenterIds: Validators.required`; the legacy report requires it. | confirm: keep it required and say so on Preview |

## Engineer's answers (2026-10-21)
- Repro of 1a: the engineer signs in to Sabreen on Beta in the browser pane; the agent reads the screen's OData request.
- Totals (R4–R6): group + grand totals. A Balance sum per main item, plus a grand total labelled «الفائض / العجز». Per-branch cross-tab totals stay in the print.
- R7: keep the cost center required, as the legacy form does. Preview now says so instead of staying greyed out.

## Done, uncommitted (front only)
- `report-grid`: opt-in `totalSummaryOptions` input (copied from report-grid-multi-request) and an opt-in `ColumnIndex.CustomizeText`. The default text is unchanged for every other report.
- `income-statement-report-grid.ts`: `percentText`, `parenthesizedTotal`, `incomeStatementPivotSummaries`. The period columns (R7/R8) use `percentText`.
- R1: Total shows parentheses when `IsNegativeShownInParens` is set. R2: `PercentageOfReport` uses `percentText`. R4/R5/R6: group and grand summaries.
- Cost-center shell: Preview is enabled on valid dates and toasts `_CostCenterRequired_` when no cost center is chosen. New i18n keys: `_SurplusDeficit_` and `_CostCenterRequired_` (en and ar).

## Point 1a reproduced on Beta (2026-10-21, Sabreen, the engineer's session)
- Request on Preview with the defaults: `fromDate=2025-10-01&toDate=2026-10-21&revised=&journalTypes=1..97&costCenterIds=&branchesIds=` with all 17 branches, then `$orderby=RowNo`. Every filter is sent.
- Response and grid: income 1,879,185.13, expenses 4,448,762.7147, NPBT / net 2,570,827.5847 with `IsNegativeShownInParens=true`. These match the legacy print.
- QA's "0 / 0 / 1,250" is rows 4–6 of the same response (other income 0, general expenses 1,250, other expenses 0). The filters are not lost. The real gaps against the legacy are display ones:
  1. Money shows up to 3 decimals (`4,448,762.715`), because the grid's default text ignores `Format: 'money'`. Fix: `moneyText` (2 dp, the print's `{0:N2}`) on all 18 money columns of the 9 reports.
  2. The loss shows without parentheses. Fixed by `parenthesizedTotal` above.
- The dates load before Preview can be clicked, so a dates race is ruled out.

## Gates and screen check (2026-10-21)
- `npm run testing` exits 0 on the final code, with no TS errors.
- Screen check: the local dist build on :4200 against the Beta APIs, Sabreen (the backend is unchanged).
  - R1 shows 1,879,185.13 / 4,448,762.71 / NPBT and net (2,570,827.58). This matches the legacy print.
  - R7 with no cost center: Preview is enabled and the toast reads «اختر مركز تكلفة واحد على الأقل».
  - R4 is empty on Sabreen (no IncomeStatment mapping), so the totals were not seen on screen.
  - R2/R7 percentages were not seen either: Sabreen has no cost-center data.
  - Switching the session to Faro-ehab (R4/R5) or dbMarbo-tech (R2/R6/R7) was refused by the permission check. That is the engineer's call.
- Local-only: the dist `config.json` points at Beta (dist is untracked), and `D:\Hadaf\.claude\launch.json` has the entry `front-cr125289-dist`.

## R4/R5 totals on screen (2026-10-21, BETA-dbriyadhbn, 01/01/2026–21/10/2026)
- R4 group sums:
  - 1. ايرادات التشغيل: 141,815,856.28
  - 2. مصروفات التشغيل: -122,361,206.70
  - 3. ايرادات اخرى: 17,634,994.47
  - 4. مصروفات عموميه واداريه: -6,962,129.34
  - 5. مصروفات اخرى: -9,001,265.00
- R4 grand total «الفائض / العجز: 21,126,249.72». The 1-cent gap against the sum of the rounded groups (…249.71) is rounding: the total sums the unrounded balances.
- **R5 bug found and fixed.** The R5 TVF returns the legacy pivot's all-branches column as rows with BranchCode `2147483647` («إجمالى الكمية المنتجة»). A plain Balance sum counted every balance twice: groups ×2 and surplus 42,252,499.43. The fix is `incomeStatementPivotSummaries(translate, '2147483647')`, a custom summary that sums only those rows. Those rows also include lines with no branch, as the legacy total column did. report-grid's total item now takes `custom` like the group items do (column vs showInColumn, `calcExpr`).
- After the fix, R5 groups equal R4's and the surplus is 21,126,249.72. The grid pages on the client (2 pages), and the summaries still cover every row.
- Build gate: `npm run testing` exits 0 after the R5 fix.
- R6/R2/R7 on screen, also on BETA-dbriyadhbn. dbMarbo-tech is not among the engineer's 121 Beta companies; the parity run reached it on db-all directly. Cost centers: select all.
  - R6: item 1 sums to 141,815,856.28 over 17 cost-center rows, the same as R4, and the group spans pages. «الفائض / العجز: 18,810,035.72». That is below R4 because R6 drops lines with no cost center (a legacy quirk in decisions.md).
  - R2: النسبة shows 5.52% / 0.01% / 0.03% on the sub-profit rows, instead of raw fractions.
  - R7: the three % columns show 5.52% / 0.47% / 0.96% (project 1008). Money is 2 dp. The R2 and R7 period % agree.
- Every QA point has now been seen on screen.

## Remaining reports and English (2026-10-21, BETA-dbriyadhbn, 01/01/2026–21/10/2026)
- R3: 2 dp, 12 rows over 2 pages. NPBT and net are 21,126,249.72, the same as the R4 surplus and R1's net.
- R8: 2 dp. The % columns are blank, as the parity verdicts record for the legacy.
- R9: 2 dp, and all 9 main items are present over 8 pages. **The group order is wrong:** 7, 8, 9, 6, 3, 1, 5, 2, 4 instead of 1..9. That is an Arabic alphabetical sort on the raw `MainItemName`, with the computed rows (no name) first. DevExtreme sorts groups on the field value, not on the `CellValueExpr` text "SortOrder. name". It dates from the original delivery: R9 was not changed in this iteration and QA did not report it. R4–R6 showed 1..5 in order on this tenant.
- R1 in English: LTR layout, English headers and descriptions, 2 dp, net 21,126,249.72 (a profit, so no parentheses).
- `SelectedLang` on localhost was restored to ar-EG. The server is stopped.

## R9 group order fixed (2026-10-21)
- **Cause, confirmed by request capture.** Paging is remote, so DevExtreme asks the server to sort the groups with `$orderby=MainItemName,RowNo`. The raw Arabic names sort alphabetically, and the computed rows (no name) come first. The "SortOrder. name" text exists only in the browser. `calculateSortValue` does not affect group sorting; only `calculateGroupValue` does (tested live).
- **Fix: `ColumnGrouping.SortField`, opt-in, main grid only.** report-grid sets `calculateGroupValue = SortField`. The group header (now the grid-level `mainGroupCellTemplate`, moved out of the `*ngIf`'d `<dxo-summary>`) shows `CellValueExpr` of the group's first row. A header that ends a page has no row of its own, so `ODataStore.onLoaded` also keeps a SortField→label map from every loaded row. Other reports render `gdata.value` as before.
- Shells: R9 `SortField: 'SortOrder'`; R4/R5/R6 `SortField: 'MainItemId'`, which had the same latent text-sort assumption.
- Build: `npm run testing` failed twice with an Angular parallel-TS worker assertion (`parallel-worker.js` `assert(compilation)`), not a code error, while other sessions' builds were running. It passes with `NG_BUILD_PARALLEL_TS=0` (219 s).
- Screen, BETA-dbriyadhbn, Arabic:
  - R9: `$orderby=SortOrder,RowNo`, groups 1→9 on all 8 pages, every header labelled (English checked too).
  - R5: page 1 now ends on «4. مصروفات عموميه واداريه» (it was a bare «4»). The sums and the surplus 21,126,249.72 are unchanged.
  - R4: 1–5, surplus 21,126,249.72.
  - R6: 9 pages, 1–5, every header labelled, surplus 18,810,035.72 (it equals the sum of the groups).
- Visible change: group headers now show «1. ايرادات التشغيل» without the «البند الرئيسي:» caption and row count, because the shared template is used.

## Plan
- Front: report-grid `CustomizeText` hook (1 line + ColumnIndex field); percent columns in R2/R7; parens on R1 Total; R4–R6 summaries per the engineer's answer; R7 preview guard.
- Point 1a: reproduce on Beta (network request) or db-all (TVF with the screen's params), then fix the cause.
- Gates: `npm run testing`; app check on the screen; ERP build only if the backend changes.
- Rules: front `core.md`, `report-module.md` (Pattern 1 report-grid); root CLAUDE.md Karpathy 3 (surgical: report-grid change is opt-in per column, default unchanged).
