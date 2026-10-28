# CR-125291 — change note 1 (QA return, 2026-10-20)

Source: Sabreen's ADO comment 10010793 (2026-10-20), the work item back to In Development. Brief Balance Sheet passed on Beta. The screenshot `125291-equity-no-total.png` could not be read (ADO VS402330, see [[open-questions]]); the comment text is enough to act on.

| Item | |
|---|---|
| What | (1) Equity Changing grid: add the per-type closing rows the legacy pivot prints as its "الرصيد / Balance" grand-total row. (2) Equity Changing grid: hide the English `RowKind` code column; `RowCaption(Arabic)` already names the row. (3) Cash Flow grid: print negatives as `(x)` like legacy, with tenant decimals. (4) Cash Flow grid: Section in Arabic on the Arabic screen. |
| Where | DB `dbo/Functions/Acc_EquityChangingReport.sql` (adds the `Closing` rows: num 4, `Balance` / `الرصيد`, Amount = SUM of the type's Opening + Change + NetProfit rows); DB `dbo/Functions/Acc_CashFlowStatementReport.sql` (new `SectionArabic` column, appended last; Arabic names from the legacy `ArabicGroupName`, without its `النمويل` typo; `All` → `الكل`); DB `Scripts/ReferenceDataScripts/0437_GL_FinancialStatementsLayout.sql` (both Equity pivots: `fAllRows` `TotalsVisibility="None"` so the pivot doesn't add its own total on top of the new Closing rows; ReferenceData re-runs on every deploy and `InsertLayout` updates the system row); API `ODataViews/GL/FinancialStatements/CashFlowReport.cs` (`SectionArabic`); Front `report-grid.component.ts` + `ColumnIndex.ts` + `utils/approximate-formater.ts` (opt-in `Format: 'money-parens'`: LDML `#,##0.00;(#,##0.00)` with the tenant ApproximateNo decimals); Front `cash-flow-shell.component.ts` (Section/SectionArabic by language, Amount `money-parens`); Front `equity-changing-shell.component.ts` (RowKind hidden). |
| Test | MSBuild sqlproj 0 errors; AnalyticsReader build 0 errors; `npm run testing` exit 0 + prettier. SQL on a tenant with the branch TVFs: Closing row per type = Opening + Change + NetProfit (= legacy pivot "Balance" row); Opening/Change/NetProfit rows unchanged against parity-125291. Cash Flow numbers unchanged (only a text column added). |
| Risk | The Equity pivot would double the closing row if the layout change didn't ship with the TVF; both are in the same DB deploy. A user's saved copy of the Equity print design still has the old custom total and would show a doubled "الرصيد" row. The shared report-grid change is additive (a new Format case); existing `'money'` columns are untouched. |
| Rollback | Revert the iterate commit on `cr125291` in each repo; the next deploy restores the TVFs and layouts. |

## Test results (2026-10-21, ELGHONEIM on db-all, 2025-01-01 to 2025-12-31, all branches)
- **Deploy:** `worktrees\cr125291\deploy-cr125291-iter1-elghoneim.sql` (not committed). It does CREATE OR ALTER of the 2 TVFs and runs the last 4 InsertLayout calls of 0437 (Cash Flow ar/en, Equity ar/en), with sqlcmd exit 0. Both Equity system layouts now have `fAllRows TotalsVisibility="None"`. No user-saved Equity designs exist on this tenant.
- **SQL check: PASS.**
  - Equity rows 1–7 are byte-identical to the pre-deploy snapshot.
  - The 4 Closing rows each equal the sum of their type's components (diff 0): 6,040,000 / −5,541,692 / 38,301,338.7075 / 0. Their total, 38,799,646.71, equals the legacy pivot "Balance" total read in P6.
  - All 16 Cash Flow rows are identical to the snapshot. `SectionArabic` is filled on every row (6 sections).
- **App check, Arabic grid (local AnalyticsReader :5655 → ELGHONEIM; front :4200):**
  - **Equity: PASS.** The columns are البيان / نوع حقوق الملكية / القيمة, and RowKind is gone. The الرصيد rows come last, with the same values as the SQL; the 11th row is on page 2 because the grid pages at 10. Decimals follow the session company's GL ApproximateNo (3).
  - **Equity print** (layout 574, ar, read from the viewer's brick model): **PASS.**
    - The rows are رصيد أول المدة / التغير… / صافى… / الرصيد, with **one** الرصيد row and no pivot custom total under it, on 1 page.
    - Grand Total column: 40,062,724.49 / −1,263,077.78 / 0.00 / 38,799,646.71, equal to the legacy figures in P6.
    - The print uses 2 decimals (ELGHONEIM's ApproximateNo).
  - **Cash Flow grid: PASS after a fix.**
    - The first run still showed `-3,709,375.625`. `report-grid.component.ts` sets `customizeText = value.toLocaleString('en-US')` on every column (to force Western digits), and that overrides `format`. So the LDML `money-parens` format was set but never rendered. The plain `'money'` format is equally ignored in the grid, which is existing behaviour and out of scope.
    - Fix: `approximateParenthesesFormater(value, approximateNo)` now returns text, `ABS(value)` with the tenant's decimals and in `(…)` when negative. `customizeText` uses it for `Format: 'money-parens'` columns, and the case itself keeps the ordinary money format.
    - Re-run: all 16 rows have Arabic sections, negatives print as `(3,709,375.62)` / `(6,134,631.98)` / `(1,294,551.25)`, and every value equals the SQL / P6.
    - `npm run testing` exit 0; prettier clean.
  - The DB server was unreachable for a while mid-check (VPN dropped); the check resumed after reconnecting.
- **Second local round** (same day, pushed code: db 51d97d13e / erp 28fb47dd5f / front 26aa8f53b8, ELGHONEIM, 2025):
  - **Arabic Equity grid on the final code:** unchanged; the report-grid fix doesn't touch `'money'` columns.
  - **Cash Flow with a branch filter** (`branchesIds=2,4`, the two busiest branches): all 16 grid rows equal `Acc_CashFlowStatementReport(…,'2,4')`. For example Operating (12,273,765.86), Net 4,098,743.73, End 1,942,737.80.
  - **English Equity grid:** Item / Equity Type / Amount, with no Kind column; all 11 rows, ending with the 4 Balance rows.
  - **English prints:** the viewer rendered layout 575. Its content was read through the same report's Excel export: one Balance row, Grand Total 38,799,646.71.
  - **Excel exports, ar 572/574 and en 573/575:**
    - Captions are in the right language and amounts are stored as numbers equal to the SQL.
    - Cash Flow cells use Excel built-in format 39 `#,##0.00_);(#,##0.00)`, so negatives show in parentheses, as legacy did.
    - Equity cells use format 4 `#,##0.00`, the same as the legacy pivot.
  - **PDF exports** of all four layouts: valid `%PDF-1.4`, 1 page each. The content wasn't decoded, because the fonts are CID-encoded; the viewer and Excel cover the content.
  - **Branch caption:** Arabic shows "Branch_2, Branch_4" and English "فرع_2, فرع_4". This is ELGHONEIM data: `BranchName` holds the English text and `BranchNameSecondLanguage` the Arabic. `GetBranchesName` maps Arabic → `BranchName` as the house convention says, so it's not a defect.
- **Not covered locally:** other tenants (P5 had 5), and Stage_Beta (nothing deployed there).
- **Setup note:** the signed-in company is Sabreen, which is in the Beta environment. Local `config.json` therefore pointed the remote APIs at `localbeta`, or the front bounced to localbeta.hadaf.website. The report data comes from ELGHONEIM through DebugTenantConnection.

Rules followed: `report-database-functions.md` (RowNo first, decimal(19,4)); `db-rules.md` (new column appended at the end of the result table); `report-backend.md` (entity property = TVF column); Front `core.md` (Arabic + English). Bent: none.
