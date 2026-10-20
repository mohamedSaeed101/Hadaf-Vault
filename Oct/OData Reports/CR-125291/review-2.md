# Review round 2 — CR_125291   base db 489493497 / erp 20e781f504 / front 0abc198bbd   head = base (all changes uncommitted in the working trees)   verdict: pass

Reviewer: Fable 5.1, read-only re-check of the 18 rows in `review-1.md`. Diff rebuilt per repo as `git diff origin/Master_Stable` plus every untracked file (`git status --porcelain -uall`); the `??` set is unchanged from round 1. No new rows: no fix introduced a `block`.

| # | file:line | severity | rule / spec line | finding | required change |
|---|---|---|---|---|---|
| 1 | AccFlex_Cloud_Database/…/dbo/Functions/Acc_CompareBalanceSheetReport.sql:98,103-108,115,124-142,152; AccFlex_Cloud_ERP/…/ODataViews/GL/FinancialStatements/CompareBalanceSheetReport.cs:13; AccFlex_Cloud_Front/…/one-date-shell/one-date-shell.component.ts:101-110 | should → verified done | D1, Acceptance 3 | `DescriptionArabic NVARCHAR(500)` added to `StatementRows` (5 header captions, `SubItemName` for sub-items, 4 summary captions) and the final SELECT; additive only: `SortOrder`, `RowType`, `MainItemId`, `Balance`, `PriorBalance`, `RowNo` expressions and the `ROW_NUMBER() OVER (ORDER BY SortOrder)` key are byte-identical to round 1, so numbers and order cannot have moved. Entity gets `string? DescriptionArabic`; the Compare branch of `initColumnOptions` picks it by `IsRtlEnabled` and hides the other; `ODATAREPORTS.DescriptionArabic` exists in both `shared.json`. Implementer-reported Compare parity 15/15 on 2 tenants accepted (reviewer has no DB access). | none |
| 2 | AccFlex_Cloud_ERP/…/FinancialStatements/CashFlowReportAng.cs:32, EquityChangingReportAng.cs:28, GLODataController.cs:279,298 | should → verified done | Coding guidelines 2; report-backend.md:250 | `DayEnd` helper gone from `FinancialStatementReportOptions.cs`; all four call sites use `toDate.GetDayEnd()` / `to.GetDayEnd()` from `SharedKernel.Logic`. | none |
| 3 | Front i18n `ODATAREPORTS._PrintPreviousDesign_` | nit → disagree accepted | consistency with cr125290 | Accepted; no collision, named in the PR description. Row dropped. | none |
| 4 | one-date-shell.component.ts:12-17 `reportTitles` | nit → disagree accepted | Coding guidelines 3 | Accepted; shared shell, visible fix on `balance-sheet` goes into the PR description + HANDOFF for fx123513. Row dropped. | none |
| 5 | (whole CR) tests | nit → disagree accepted | checklist 5 | Accepted; house precedent for OData report CRs; English print read stays a gate-4 Stage Beta step. Row dropped. | none |
| 6 | FinancialStatementReportOptions.cs:62 `isArabic ? "الكل" : "All"` | should → disagree accepted | core.md §Error Handling | Verified: `Shared/SharedKernel.Logic/Resources/Resource.en.resx:456-458` has `<data name="All"><value /></data>` (empty), while `Resource.resx:457` has `الكل`. `Resource.All` would print a blank English branch caption; the literal is the correct call here. Row dropped. | none |
| 7 | cash-flow-shell.component.ts:52-58 | should → done, deviation accepted | report-module-scaffold §Date Range Validation | Preview enabled when both dates are set (`isPreviewDisabled` only checks presence); from > to cancels the preview (`e.Canceled = true`) and shows the `COMMON._dateOutOfRangeMessage_` toast; `$event` passed from the html. Scaffold §Date Range Validation also asks for `setErrors` on FromDate, but the implementer's reason holds (a sticky error on `fromDate` after `toDate` is corrected would block the iframe Print path, which validates on its own) and the `e.Canceled` + toast shape is the live precedent in `bank-balance-reprot.component.ts:120-125` and `bank-guarantee-report.component.ts:161-165`. User gets the reason; intent of the rule met. | none (name the deviation in the PR) |
| 8 | equity-changing-shell.component.ts:52-58 | should → done, deviation accepted | report-module-scaffold §Date Range Validation | Identical to row 7 (diff against cash-flow-shell shows only report name, column set and the dropped `branchesIds`). | none |
| 9 | 3 shells, duplicated handlers | should → disagree accepted | DRY vs core §Follow the code that is there | Accepted; matches the existing copy-paste shells. Row dropped. | none |
| 10 | GLODataController.cs 5 actions, no `ProducesResponseType(400)` | nit → disagree accepted | accflex-erp-api.md §API Layer | Accepted; matches every existing action in the controller. Row dropped. | none |
| 11 | 5 `*Config.cs` HasNoKey + AsNoTracking | nit → disagree accepted | report-backend.md §Artifact 2 | Accepted documented exception. Row dropped. | none |
| 12 | Acc_EquityChangingReport.sql:53,58 double TVF call | nit → disagree accepted | §Performance Guidelines | Accepted; parity-verified TVF left untouched. Row dropped. | none |
| 13 | Acc_CashFlowStatementReport.sql:79,90,91 | nit → verified done | §Comma-Separated ID List Handling | All three `@BranchList` uses wrapped in `NULLIF(@BranchList, N'')`, including the `IS NULL` join guard. | none |
| 14 | Acc_CompareBalanceSheetReport.sql SortOrder stride 1000 | nit → disagree accepted | §ROW_NUMBER() Keying | Accepted; unreachable at realistic counts. Row dropped. | none |
| 15 | 5 `Acc_*Report.sql` + `0437_GL_FinancialStatementsLayout.sql` | nit → verified done | repo convention BOM + CRLF | All six files start with `EF BB BF`; every line ends CRLF (0 LF-only lines in each). | none |
| 16 | Acc_FinancialPositionStatementReport.sql SubParentItemName NVARCHAR(MAX) | nit → disagree accepted | §Data Type Conventions | Accepted; source column is NVARCHAR(MAX). Row dropped. | none |
| 17 | one-date-shell.component.ts:41,59-61; .html:15 | nit → verified done | core §Follow the code that is there | `printLabelKey` is a field set once in the `queryParams` handler and bound as `[printLabelKey]="printLabelKey"`; no template ternary. | none |
| 18 | one-date-shell.component.ts:55 queryParams subscription without SubSink | nit → disagree accepted | core (SubSink) | Accepted; pre-existing subscription. Row dropped. | none |

## Summary for the orchestrator

- verdict: **pass**
- rows re-checked: 18 (7 `done` verified in code, 11 `disagree` all accepted with evidence; none restated)
- counts remaining: block 0, should 0, nit 0
- block rows: none
- Row 6 evidence: `Resource.en.resx:457` `<value />` for `All`; literal kept rightly.
- Rows 7/8: toast + `e.Canceled` instead of `setErrors(fromDate)`; accepted as the house precedent (`bank-balance-reprot.component.ts:120-125`), name it in the PR.
- Row 1: `DescriptionArabic` is strictly additive; key/order/number expressions unchanged; i18n key present in ar/en.
- Round 3: not needed.
