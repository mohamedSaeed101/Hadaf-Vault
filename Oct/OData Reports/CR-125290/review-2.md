# Review round 2 — CR_125290   base = HEAD (uncommitted; Database 489493497bb6, ERP 20e781f504a1, Front 0abc198bbd44)   verdict: pass

Re-check of the round-1 rows only, against `git diff origin/Master_Stable` plus the untracked files in the three repos (2026-10-16). Plus the one post-round-1 change (P6 header fix).

## Round-1 rows

| # | file:line | severity | rule / spec line | finding | required change |
|---|---|---|---|---|---|
| 1 | vault `p6-app-check.md`; `HANDOFF.md` P6 | — | facts AC3 | **done, verified.** 20/20 renders 200 (5 reports × ar/en × PDF/XLS), R2 ar viewed on screen, legacy MVC Net Profit = TVF (−11,310.31) line by line, open question 8 settled. Residual stated honestly in "Not covered": R3/R4 rows and R1/R2 budget columns rendered empty (UNP-Ali has no budgets); only R2 viewed visually. Accepted: P5 parity covers those numbers; the layouts for R1/R3/R4/R5 deserialised and rendered without error, which was the block. | none |
| 2 | `0436_…Layout.sql` R3/R4 pivots | — | plan Columns R3/R4 (ABS) | **disagree accepted.** `CellFormat FormatString="#,##0.00;#,##0.00"` on the 16 pivot data fields renders negatives unsigned while totals use `N2`; that is the legacy `ColumnValueType == Value` rule. Residual (per-dimension custom-total rows under month columns signed vs legacy ABS) could not be seen in P6 (no budget rows on UNP-Ali). | none now; if QA reports signed subtotal rows on a budget tenant, record it as a quirk in `decisions.md` |
| 3 | `IncomeStatementPerMonthReportAng.cs:44-45` | — | D2 | **done, verified:** `fromMonth`/`toMonth` = `range.FromMonth`/`range.ToMonth`, same as R3/R4. | none |
| 4 | `IncomeStatementBudgetReportConfigurations.cs` | — | report-backend.md Artifact 2 | **done** (no change; bend to be cited in the PR). | none |
| 5 | `DataContext.cs:70,395-399` | — | report-backend.md Artifact 3 | **done, verified:** `using AnalyticsReader.Api.ODataViews.GL.IncomeStatementBudgetReports;` added, 5 DbSets use short names. | none |
| 6 | `DataContext.cs:944-952` `GetCostCentersName` | — | HANDOFF merge overlap | **done, verified:** byte-identical to `cr125288` copy (diff empty). | none; name it in the PR description |
| 7 | `IncomeStatementBudgetReportOptions.cs` parsers | — | guidelines 4 | **done** (none now; no AnalyticsReader test project). | none |
| 8 | TVF `SortOrder` | — | guidelines 2 | **done** (none; contract column). | none |
| 9 | `Scripts/ReferenceDataScripts/0436_GL_IncomeStatementBudgetReportsLayout.sql` | — | sqlproj-registration | **done, verified:** file renamed, sqlproj `<None Include="…0436_…">`, plan P4 row and HANDOFF P4 row say 0436; no `0432` left in vault notes or project sources (only in `obj/` build output). | none |
| 10 | `0436_…sql:15` guards | — | db-rules | **disagree accepted:** house ReferenceDataScripts seeds omit `SET XACT_ABORT ON; SET NOCOUNT ON;`; matching the neighbours is the right call. | none |
| 11 | R1/R2 TVF NetProfit includes cancelled type 1/2 rows | — | plan open question 8 | **done, verified by P6:** legacy MVC Net Profit −11,310.31 = TVF; excluding them would give 0.00. | none |
| 12 | R1/R2 TVF `DimensionName` width | — | plan Columns R1/R2 | **done, verified:** plan line 57 now says source width (300/500, no cast, no C# MaxLength); no `MaxLength`/`StringLength` in the 5 entities or configs. | none |
| 13 | `IncomeStatementBudgetReportOptions.cs:129-144` `RevisedCaption` | — | accflex-erp-domain.md Validation and Localization | **done, verified:** 9 keys in `ReportStrings.resx` / `.en.resx` / `Designer.cs`; wording matches the legacy note verbatim (lines 74, 834, 1355); resolved via `ReportStrings.Culture`. Not reusing the 3 existing keys is justified (their English differs from legacy R5 `lblRevised`). | none |
| 14 | 5 configs in one file | — | report-backend.md Naming | **disagree accepted:** related-entity family file. | none |
| 15 | `GLODataController.cs:216` | — | core.md naming | **done, verified:** local is `periodId`. | none |
| 16 | 5 forms `resetFilters()` | — | AP SRP | **done, verified:** `resetFilters` on all 5 forms; every shell is `onClearFilterClicked = (): void => this.FormRef.resetFilters();`. | none |
| 17 | 5 shells duplicate logic | — | AP DRY | **done:** clear logic lives in the forms; `updateQueryOptions`/`initColumnOptions` copies kept identical deliberately. | none |
| 18 | shells filter sources | — | AP one source of truth | **done, verified:** `costCenterIds` read from `FormRef.CostCenterLookupRef.CostCenterForm.value.costCenterIds` (R1/R3/R5), branches from `BranchForm.BranchList`, journal types from `JournalTypeForm.JournalTypeList`; no `FilterForm.branchesIds/costCenterIds` patch remains in the reset path. | none |
| 19 | cost-center reset via widget | — | AP direct widget manipulation | **done, verified:** `CostcenterChecklistComponent.clear()` (`unselectAll` + `patchValue({ costCenterIds: [] })` + `emit([])`) at `costcenter-checklist.component.ts:111-115`; called from the three cost-center forms' `resetFilters`. | none |
| 20 | hidden-column map | — | AP column chooser | **disagree accepted:** `report-grid.component.ts:612` `showInColumnChooser = colOption?.ShowInColumnChooser ?? x.visible`; `Visible: false` columns already stay out of the chooser. | none |
| 21 | `gridQueryOptions` type | — | AP readability | **done, verified:** `Record<string, string> = {}` in all 5 shells. | none |
| 22 | `String(accountingPeriodId)` | — | AP nullable | **done, verified:** `String(accountingPeriodId ?? '')` in both period shells. | none |
| 23 | `initColumnOptions` in `ngOnInit` | — | AP RTL parity | **done** (house pattern). | none |

## Post-round-1 change (P6 header fix)

`AnalyticsReader.Api/AngularReports/GeneralLedger/IncomeStatementBudgetReports/IncomeStatementBudgetReportOptions.cs:90-106` `JournalTypeFilter` + `ReportFilterAll` in `ReportStrings.resx` ("الكل") / `ReportStrings.en.resx` ("All") / `ReportStrings.Designer.cs`.

- Scope: AC3 print parity. The legacy prints never listed journal types; printing ~95 names filled page 1, so collapsing a full selection to "All" is a fair reading of "same print", and the row is recorded in `decisions.md` / `p6-app-check.md`.
- Correctness: `journalTypes` is the parsed id list (`TryParseIds` output: validated ints joined by `,`, or `null` for "all"), so the interpolated `{journalTypes}` is a parameter, no injection. `SqlQuery<int>` with `COUNT(*) AS Value` is the EF 8 scalar shape. `Acc_ConvertIntListToTable` returns column `number`; `Acc_JournalType` has no soft-delete column, so "every row" is the right set. `null` is short-circuited before the SQL (the TVF would otherwise map NULL to `'0'`). Verified at render time in P6 ("أنواع القيود: الكل").
- Simplicity: one query + one resource key, no new abstraction. The 9 revised-caption keys and `ReportFilterAll` share the `ReportStrings.Culture` set pattern of the sibling.
- No block, no new row. Observation (nit, no action): when the user deselects every journal type the parsed list is `null` → TVF reads all types → header prints "" rather than "All"; that is also what the legacy header did (it never listed journal types), so it is consistent with D3 parity.

## Findings

| # | file:line | severity | rule / spec line | finding | required change |
|---|---|---|---|---|---|
| — | — | — | — | no open rows | — |

Round 3: not needed.
