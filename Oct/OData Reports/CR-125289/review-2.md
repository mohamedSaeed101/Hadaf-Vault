# Review round 2 — CR_125289   base = HEAD (nothing committed)   verdict: changes required

Bases (= HEAD, unchanged since round 1): Database `489493497bb6`, ERP `20e781f504a1`, Front `0abc198bbd44`. Reviewed: `git diff origin/Master_Stable` plus the untracked files of each repo, excluding bin/obj/node_modules/dist. Scope of this round: the 28 rows of `review-1.md`, plus one new row (29) for a `block` the fix cycle introduced.

## Round-1 rows

| # | file:line | severity | rule / spec line | finding | required change |
|---|---|---|---|---|---|
| 1 | p6-app-check.md; 0431_*.sql, 0432_*.sql | closed (was block) | facts AC3; Coding guidelines 4 | P6 ran on UNP-Ali: 9 grid `$query` 200 with row counts equal to SQL, 18 PDF and 18 XLS exports 200, print totals equal to SQL (R1 2,319,136.85 / R3 -2,319,136.85 / R7 0.00), no layout-load or missing-field error. The only finding it raised became row 28. | none |
| 2 | Acc_IncomeStatementCostCenterPeriodReport.sql, Acc_IncomeStatementBranchPeriodReport.sql; IncomeStatementCostCenterPeriodReport.cs, IncomeStatementBranchPeriodReport.cs; the 2 shells; i18n | closed (was should) | decisions "Parity verdicts" | `PrintedOnly*` is gone from the 3 repos (0 matches outside bin/obj); the TVF comments now read "NetProfit = Calculate* over all nature-1 types" (CostCenter :26-27, Branch :27-28); the NetProfit row sums only `Calculate*` (:148-152 / :149-153); the 2 entities carry 22 properties matching the 22 TVF columns; the 6 i18n keys are absent; `0432` still binds nothing named PrintedOnly. The only remaining references are in `D:\Hadaf\worktrees\cr125289\parity-125289.sql` (set root, not a repo file, historical P5 script). | none |
| 3 | brif-income-statment-branche-report-shell.component.ts:87, brif-income-statment-costcenter-report-shell.component.ts:81, brif-income-statment-report-shell.component.ts:84-85 | closed (was should) | facts AC2; Legacy "sort by MainItemId" | `CellValueExpr` prefixes the group value with `MainItemId.` (R4/R5/R6) and `SortOrder.` (R9, with the translated `_RowType_` for the computed rows). `report-grid.component.ts:672-673` maps it to `calculateCellValue`, and the grid has no `remoteOperations`, so DevExtreme groups locally on that string; ids are 1-9, so string order = id order. R9 translation keys `_GrossProfit_ / _NetProfitBeforeTax_ / _NetProfit_` exist in both languages. | none |
| 4 | 0431_*.sql (44x `{0:N2}`), 0432_*.sql (197x) | accepted disagreement (was should) | facts AC2; contracts-R1-R3 "legacy = n<ApproximateNo>" | The implementer's evidence holds: shipped `0404` (123252) and cr125288's `0430` print `{0:N2}` and neither reads `ApproximateNo`; the deviation is recorded in `decisions.md` Technical choices :25 and the grid keeps full precision. Row dropped. | name it in the PR, as decisions.md says |
| 5 | 0432_*.sql | closed (was nit) | contracts-R7-R9 "`{0:0%}`" | 12x `{0:0%}`, 0x `{0:0.00%}` in 0432; `0431` keeps its 2. | none |
| 6 | the 2 period TVFs `LabelShift`, `PeriodFrom…LastYearTo`; `AddPeriodLabels` | skipped, confirmed optional | Coding guidelines 2 | Still duplicated (TVF :154-184 and the C# labels). Harmless; the grid hides the 6 columns and the layouts use the parameters. | optional, unchanged |
| 7 | IncomeStatementReportsConfigurations.cs | closed (was nit) | report-backend.md Artifact 2 | The `HasNoKey()` bend is recorded in `decisions.md` :26. | name it in the PR |
| 8 | report-grid.component.ts:871 | closed (was nit) | Coding guidelines 3 | Still a 1-line hunk (`git diff --stat` 2 +-). | name it in the PR with cr125288 |
| 9 | DataContext.cs:947-955 | closed (was nit) | Coding guidelines 3 | `GetCostCentersName` unchanged, same insertion point after `GetBranchesName`. | name it in the PR with cr125288 |
| 10 | IncomeStatementReportOptions.cs:20-29 | skipped, confirmed optional | Coding guidelines 2 | Double trim/parse still there; harmless. | optional, unchanged |
| 11 | IncomeStatementReportOptions.cs:76-103 | closed (was nit) | Coding guidelines 4 | No test project exists; P5 parity (117 + 27 runs) and P6 end-to-end stand in. | none |
| 12 | brif-income-statment-report-shell.component.ts:97-105 (R1 grid) | skipped, confirmed optional | decisions D2 | `Total` is plain money, `IsNegativeShownInParens` hidden; a string `CellValueExpr` would lose the money format, as the implementer says. The print applies the rule. | optional, unchanged |
| 13 | R2/R3 TVF `Description` vs i18n `_GroupTotal_/_ReportTotal_` vs 0432 literals | skipped, confirmed optional | core.md "one wording per concept" | Three wordings remain; PO choice. | optional, unchanged |
| 14 | Acc_CostCenterBriefIncomeStatementReport.sql:21-34, 65-73 | closed (was should) | report-database-functions.md Performance (1, 6) | `Acc_GetAccountJournalActionsBetweenDates` is inlined once (:28-29); `TypeBalance` sums `CostCenterAccountBalance` RIGHT JOIN `Acc_AccountType` (nature 1), which equals the dropped per-account CTE because SUM over (account, cost center) groups = SUM per account. The 14 contract columns and types (`PercentageOfReport DECIMAL(19,10)`) are intact (:167-181). R2 parity re-run reported identical SUMMARY rows on 4 tenants. | none |
| 15 | Acc_BranchBriefIncomeStatementReport.sql:23-36, 66-74 | closed (was should) | same | Same fold from `BranchAccountBalance`; 14 contract columns intact (:165-179), `PercentageOfReport` NULL as the contract says. | none |
| 16 | Acc_IncomeStatementByBranchProductionReport.sql | closed (was nit) | D2 | No change, as agreed. | none |
| 17 | Acc_IncomeStatementByBranchProductionReport.sql FLOAT columns | closed (was nit) | D2 | No change. | name the deviation in the PR |
| 18 | R3 `PercentageOfReport`, R8 `*Percentage` always NULL | closed (was nit) | Performance (6) | Kept for shape parity. | state the reason in the PR |
| 19 | 0431_*.sql, 0432_*.sql guards | skipped, confirmed optional | db-rules.md guards | No `SET XACT_ABORT ON; SET NOCOUNT ON;`, like 0404/0412. No `GO` (0 matches). | optional, unchanged |
| 20 | IncomeStatementReportOptions.cs `TryParseIds` / `IsDate` | closed (was nit) | duplicated helpers | Kept; follow-up after both CRs merge. | none |
| 21 | GLODataController.cs:14-15 | closed (was nit) | Coding guidelines 3 | The original using order is back; the 2 new usings are appended after `SharedKernel.Web...`. | none |
| 22 | financial-reports/shared/income-statement-report-grid.ts:28-58 | closed (was should) | DRY | `incomeStatementPeriodColumns(translate)` is the single 12-column + 9-hidden definition; used by the branche shell (:113, R8) and the costcenter shell (:100, R7). The R1 shell has no period report and correctly does not import it. The hidden list no longer contains `PrintedOnly*`. | none |
| 23 | income-statement-report-grid.ts:6-25; the 3 shells `updateQueryOptions` | closed (was should) | DRY | One helper, `null` when `from > to`; each shell toasts and sets `args.Canceled = true`. Arguments per shell: R1 (cc, branches), costcenter (cc, `null`), branche (`null`, branches), matching the controller signatures. `revised` trimmed, lists stringified with `''` for null, which the backend maps to NULL. | none |
| 24 | en-US/general-accounting.json `_GrossProfit_` | closed (was should) | core.md UI | "Gross Profit". | none |
| 25 | the 3 shells :65 / :65 / :63 | closed (was nit) | report-module.md Common Patterns 1 | `COMMON._dateOutOfRangeMessage_`. | none |
| 26 | the 3 shells :36 / :36 / :33 | closed (was nit) | core.md TypeScript | `gridQueryOptions: Record<string, unknown> = {}`. | none |
| 27 | the 3 shells `getReportParams` | skipped, confirmed optional | core.md Subscriptions | Unchanged `route.queryParams.subscribe` without SubSink, pre-existing code. | optional, unchanged |
| 28 | 0431_*.sql, 0432_*.sql (all 18 layouts) | closed (was block) | facts AC3; p6-app-check.md finding 1 | Verified in the files: every `?journalReviseFilter / ?journalTypeFilter / ?branchFilter / ?costCenterFilter` binding sits inside a `ReportHeaderBand` (0431: 26 bindings, 0432: 32; 0 in any `PageHeaderBand`). All 18 layouts have a `ReportHeaderBand`; the `PageHeaderBand` (HeightF 72, column headers only) exists in 10 of 18 (R1-R3, R7/R8), none in the cross tabs, as described. 18 `InsertLayout` calls, no `GO`. Render evidence (implementer, DevExpress 24.2, 95 journal types, 17 branches): R1 en 27 -> 2 pages, R3 en 69 -> 2, R4 en 19 -> 2, R7 en 20 -> 2, no overlap; redeployed to UNP-Ali ids 2840-2857. MSBuild 0 errors. | none |

## New row (introduced during the fix cycle)

| # | file:line | severity | rule / spec line | finding | required change |
|---|---|---|---|---|---|
| 29 | AccFlex_Cloud_ERP/AccFlex_Cloud_ERP/AnalyticsReader/AnalyticsReader.Api/wwwroot/css/ace/ace.bundle.css, css/designer.part.bundle.css, css/thirdparty.bundle.css, js/designer.part.bundle.js, js/thirdparty.bundle.js | block | Coding guidelines 3 (every changed line traces to the request); review-1 "Applied" note "the wwwroot bundles were restored afterwards" | The five tracked bundle files are 0 bytes in the working tree: `git diff origin/Master_Stable --stat` shows 17,655 deletions, 0 insertions (HEAD sizes 38 KB / 643 KB / 839 KB / 9.1 MB / 785 KB; working tree 0 bytes each). They are not gitignored, so a `git add -A` commits the AnalyticsReader designer and viewer assets as empty files, and the restore claimed in review-1 did not happen (the `dotnet build` of the fix cycle truncated them again). Nothing in the spec touches wwwroot. | `git -C D:\Hadaf\worktrees\cr125289\AccFlex_Cloud_ERP checkout -- AccFlex_Cloud_ERP/AnalyticsReader/AnalyticsReader.Api/wwwroot`, then confirm `git status --porcelain` lists only `DataContext.cs`, `GLODataController.cs` and the untracked IncomeStatement files. Do this after the last `dotnet build`, or build with `BaseOutputPath` outside the repo so the bundles are never rewritten. |

## Checked and clean (round 2)

- sqlproj: still 9 `<Build Include>` functions + 2 `<None Include>` seeds, nothing else.
- Controller: 9 actions unchanged in shape; R7 still returns an empty list when `CostCenterIds` is null.
- Shell templates: all 3 bind `[endpoint]="reportName"`, `[QueryOptions]="gridQueryOptions"`, `[columnIndex]="headerColumns"`, `(OnPreviewClick)="updateQueryOptions($event)"`, `[ApplicationId]="1"`; Print buttons read `_PrintPreviousDesign_`.
- i18n: `INCOMESTATEMENTREPORTS` block identical key set in ar-EG and en-US (56 keys each), no `PrintedOnly*`.
- No secrets, ports or machine paths in the diff.

## Verdict

1 block (row 29, new), 0 should, 0 nit open. Rows 1-28: 20 closed, 1 disagreement accepted (row 4), 7 optional nits confirmed skipped (6, 10, 12, 13, 19, 27 and the 0431/0432 guard). Verdict: **changes required** until the wwwroot bundles are restored. Round 3 is not needed beyond re-running `git status --porcelain` on AccFlex_Cloud_ERP and checking the five files are back to their HEAD sizes; the orchestrator can do that check itself.

## Row 29 — resolved by main (2026-10-15)
`git checkout -- AccFlex_Cloud_ERP/AnalyticsReader/AnalyticsReader.Api/wwwroot` restored the 5 bundles (thirdparty.bundle.js is back to 784,909 bytes). `git status --porcelain` now lists only DataContext.cs, GLODataController.cs and the untracked IncomeStatement files. This is the check the reviewer specified, so no third round is needed.
**Final verdict: pass.** 0 block, 0 should open.
