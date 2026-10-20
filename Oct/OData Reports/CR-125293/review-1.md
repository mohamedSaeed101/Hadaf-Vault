# Review round 1 — CR_125293   verdict: pass

Bases / heads (`git diff origin/Master_Stable...HEAD`, working trees clean):
- AccFlex_Cloud_Database  base 489493497bb  head 3a7a8d86c  (a1da17c2a TVFs, 512ee1255 layouts, 3a7a8d86c insurance fraction fix)
- AccFlex_Cloud_ERP       base 20e781f504a  head 857d878a94 (ee183e8d1b AnalyticsReader, 857d878a94 insurance toDate fix)
- AccFlex_Cloud_Front     base 0abc198bbd4  head d7d4c5f353

No `spec.md` / `facts.md` exist (the CR ran through `mvc-to-odata-report-migration`). This review ran against `CR-125293 - Plan.md` (Contract, Decisions D1–D3, Fixes) and the ticket acceptance criteria A1–A4. Data-parity evidence: `parity\results-R1-R3.md`, `results-R4-R5.md`, `results-seeded.md` (all PASS after the two fix commits; the seeded run closes the earlier coverage gaps for AllTerminated, IsPaid = 0, Suspend mapping and the Insurance EndWorkingDate fix).

## Acceptance coverage

| AC / plan line | Evidence in the diff | Test |
|---|---|---|
| A1 five reports via `analyticsreaderapi/odata` (entity + EF config + DbSet + Angular report) | 5 × `ODataViews/Payroll/*Rpt/*.cs`, `SalariesRptConfigs.cs` (`ToFunction("PR_*Report")`), `DataContext.cs:+579-583`, 5 × `AngularReports/Payroll/SalariesReports/*RptAng.cs`, 5 endpoints in `PayrollOdataController.cs:+208-312`; 5 TVFs registered in the `.sqlproj` | parity R1–R5 + seeded (vault) |
| A2 no `accflex-report-iframe` | all 5 shells now render `<report-grid>`; grep for `iframe` / `ReportSrcHandler` in the 5 shell folders returns nothing; `AccflexReportShellComponent` base dropped | front gate `npm run testing` EXIT 0 (HANDOFF) |
| A3 Excel/PDF via Report Grid | `report-grid` with `[ReportName]` + `[ApplicationId]="4"`; ar + en layouts seeded by `20261014191001..005` through `dbo.InsertLayout` (update-or-insert, re-runnable, no `GO`, no DDL) | 10/10 layouts render to PDF (plan status) |
| A4 permissions via ModuleId | routes `data: { ModuleId: 545 / 548 / 550 / 552 / 771 }`; `[PermissionModuleId((int)ModuleIds.*)]` + `ViewPolicy` on every endpoint, ids match the plan | — |
| Contract: names, RowNo BIGINT first, nullable props, id lists NULL = all, same split function as legacy | checked per TVF against the xsd `CommandText` (`Acc_ConvertStringListToTable` for Salaries Items / Insurance, `Acc_ConvertIntListToTable` for PayCheck / Receipt / Bonus) and per entity column list | parity |
| Fix 1 PayCheck `@IsPaid` | `PR_PayCheckReport.sql:48`; front radio 1 → omit, 2 → `'true'`, 3 → `'false'` (`pay-check-shell.component.ts:+134-136`); backend `bool.TryParse` → `bool?` | seeded R2 Fix table 4/4 |
| Fix 2 Insurance `EndWorkingDate >= CAST(GETDATE() AS DATE)` | `PR_InsuranceRegistrationReport.sql:138` | seeded R4 (b) |
| Fix 3 Insurance Int/Fraction in SQL, blank unless > 0 | `PR_InsuranceRegistrationReport.sql:214-229` (fraction = `FLOOR(v*100) - FLOOR(v)*100`, no overflow on .50) | R4 re-run 88/88 |
| Insurance `toDate` = legacy midnight | `InsuranceRegistrationRptAng.cs:34`, controller `:+284` use `GetDayStart()` for both ends | R4 "narrow midnight" 19/19 |
| Bonus `toDate` day end | `GetDayEnd()` (`EmployeeBonusRptAng.cs:42`, controller `:+307`) | R5 8/8 |

Scope: every changed line traces to the plan. The deleted `employee-bonus-report-form` component was used only by the bonus shell and became an orphan of this change (Coding guidelines 3, "clean up your own mess"); no other reference remains. No shipped DTO, route, column or TVF signature was changed; everything is additive. No secret, port or local path in any diff (the only tokens are the public DevExpress `PublicKeyToken`).

Tests: there is no unit-test precedent for AnalyticsReader TVF reports; the plan's phase-5 gate (legacy query vs TVF, same params, zero diff except the listed Fixes) is the regression test for this kind and it is met and documented. The seeded run is rollback-only and verified non-persisting.

## Findings

| # | file:line | severity | rule / spec line | finding | required change |
|---|---|---|---|---|---|
| 1 | AccFlex_Cloud_Database/…/Scripts/PostScripts/20261014191002_PR_PayCheckReportLayout.sql:4; 20261014191003_PR_EmployeeSalaryReceiptReportLayout.sql:4; 20261014191004_PR_InsuranceRegistrationReportLayout.sql:4; AccFlex_Cloud_ERP/…/AngularReports/Payroll/SalariesReports/PayCheckRptAng.cs:40-48 | should | Plan "Decisions" D1 (differences from legacy only where listed under Fixes) and Plan:88 "Layout deviations to confirm" | Three print deviations from legacy are shipped without a recorded decision: PayCheck month header "MonthName / yyyy" (legacy MM/yyyy) and grouping by Branch/Department; Receipt now prints its income lines (legacy printed none); Insurance English texts are new translations. The plan itself marks them "to confirm". | Get the user's yes/no on each and record it in the plan as D4 (or align the layout / month string to legacy where refused) before the PR. No code change if accepted. |
| 2 | AccFlex_Cloud_ERP/…/AngularReports/Payroll/SalariesReports/EmployeeSalaryReceiptRptAng.cs:7,99-108 | nit | C:\Hadaf_Work\CLAUDE.md "Coding guidelines 2. Simplicity First" | Computes a culture-specific month name and returns `Parameters["month"]`, but the Receipt layout declares no `month` parameter (its only parameters are the standard CompanyName/Address/…/UserName), so the value and the `System.Globalization` import are unused. PayCheck's copy is used (its layout binds `Parameters.month`). | Either drop the parameter + import here, or bind `Parameters.month` in the Receipt layout if the header should show the month. Optional. |
| 3 | AccFlex_Cloud_Front/…/containers/employee-salary-receipt-shell/employee-salary-receipt-shell.component.ts (old :9-14), employees-financials-shell.component.ts (old :9-14), insurance-registration-report-shell.component.ts (old :10-15), pay-check-shell.component.ts (old :15-20) | nit | C:\Hadaf_Work\CLAUDE.md "Coding guidelines 3. Surgical Changes" (don't "improve" adjacent comments) | The `@component / @author / @package / @version` doc headers were deleted while rewriting the shells. The sibling CR 125294 did the same, so this is consistent, but the lines did not have to change. | Optional: restore the four header blocks. |
| 4 | AccFlex_Cloud_Database/…/dbo/Functions/PR_EmployeesSalariesItemsReport.sql:60-88 | nit | Plan Contract §1 ("`@EmployeeIds` non-null = IN list. Otherwise legacy WHERE verbatim") | When both `@EmployeeIds` and `@InServiceFilter` are passed they AND together (legacy had one `@empIds` string, so the two were mutually exclusive). The front never sends both (`employees-financials-shell.component.ts:+75-93` sends one or the other), so no observable difference today. | None required; noted so a future caller does not pass both expecting the legacy precedence. |

No `block` rows. Verdict: pass. Round 2 not needed unless the answer to row 1 changes a layout.

## Merged rows (main, round 1)
Row 1 (layout deviations): resolved — user accepted all three on 2026-10-14, recorded as D5 in decisions.md and PLAN.md. No code change.

| # | file:line | severity | rule / spec line | finding | required change |
|---|---|---|---|---|---|
| S1 | AccFlex_Cloud_Database\...\dbo\Functions\PR_EmployeesSalariesItemsReport.sql:65 | should | sql: report-database-functions.md §Comma-Separated ID List Handling | @EmployeeIds parsed with Acc_ConvertStringListToTable (nvarchar) vs INT EmployeeId; rule names Acc_ConvertIntListToTable. Legacy used the String variant (PLAN: same split function as legacy). Non-numeric token → conversion error. | Switch to Acc_ConvertIntListToTable, or record the deviation as intentional. |
| S2 | AccFlex_Cloud_Database\...\dbo\Functions\PR_InsuranceRegistrationReport.sql:146 | should | sql: report-database-functions.md §Comma-Separated ID List Handling | Same as S1. | Same as S1. |
| S3 | AccFlex_Cloud_Database\...\dbo\Functions\PR_InsuranceRegistrationReport.sql:193 | nit | sql: report-database-functions.md §ROW_NUMBER() Keying | ORDER BY EmployeeName not unique → RowNo non-deterministic for duplicate names. | Add tie-breaker: ORDER BY EmployeeName, InsuranceNum, IDNumber. |
| S4 | AccFlex_Cloud_Database\...\dbo\Functions\PR_EmployeeBonusReport.sql:33 | nit | sql: style | 'Yes'/'No' varchar vs N'' Arabic branches. | Optional N'Yes'/N'No'. |
| B1 | AccFlex_Cloud_ERP\...\PayrollOdataController.cs:285 + InsuranceRegistrationRptAng.cs:34 | nit (resolved by D4) | backend: report-backend.md §Artifact 4 Key Rules | toDate GetDayStart drops same-day start dates with a time part. | None: deliberate parity decision D4 (decisions.md); legacy behaves the same. |
| B2 | AccFlex_Cloud_ERP\...\PayrollOdataController.cs:211,230,252,272,293 | nit | backend: accflex-erp-api.md §API Layer | ProducesResponseType without type / 400 ProblemDetails (copies controller precedent). | Leave for consistency. |
| B3 | AccFlex_Cloud_ERP\...\SalariesRptConfigs\SalariesRptConfigs.cs:1 | nit | backend: report-backend.md §Artifact 2 / §Naming Conventions | Five unrelated configs in one file; rule reserves multi-config files for master-detail. | Split into {Entity}Config.cs files. |
| F1 | AccFlex_Cloud_Front$F/employees-financials-shell/employees-financials-shell.component.ts:52-65 | should | AP: DRY | In-service/terminated/ids logic duplicates EmployeeMonthFormComponent.getQuery (shared/components/employee-month-form). | Main's call: keep local (moving it means editing a shared component outside the CR — root CLAUDE.md Coding guideline 3). Implementer may mark disagree. |
| F2 | AccFlex_Cloud_Front$F/insurance-registration-report-shell/insurance-registration-report-shell.component.ts:46-54 | should | AP/R: report-module-scaffold §Date Range Validation | No ToDate >= FromDate / SQL min-date check before preview (bonus shell has it). | Add onPreviewClick(e: PreviewArgs) with COMMON._dateOutOfRangeMessage_ toast + e.Canceled = true, as employee-bonus-shell. |
| F3 | AccFlex_Cloud_Front\accflex-erp/src/assets/i18n/en-US/payroll.json:672, ar-EG/payroll.json:670 | should | AP/R: report-module-scaffold §Common Shared Keys | 17 SALARYODATAREPORTS keys duplicate shared.json ODATAREPORTS (Amount, BankName, BranchName, CurrencyName, DepartmentName, Description, EmployeeArabicName, EmployeeName, EmployeeNumber, JobName, ProjectName, SalaryDate, SalaryMonth, SalaryYear, SerialNumber, Suspend, TotalDeductions). | Use ODATAREPORTS.<key> for those columns; keep only payroll-specific keys; do NOT add an ODATAREPORTS block to payroll.json (shallow merge). |
| F4 | AccFlex_Cloud_Front$F/pay-check-shell/pay-check-shell.component.ts:50-54 | nit | AP/R: front core §UI | Status radio labels hard-coded ar/en. | Translate keys in both languages. |
| F5 | AccFlex_Cloud_Front$F/*-shell.component.ts (gridQueryOptions, EmployeeIdList, BankList) | nit | AP: any types / front core §TypeScript | object/any[] typing. | Record<string, string>, number[]. |
| F6 | AccFlex_Cloud_Front$F/employees-financials-shell/employees-financials-shell.component.ts:14-15, .html:133 | nit | AP: readability | sharedEmplyeeListRef misspelled. | Rename to sharedEmployeeListRef. |

**Main decisions for the implementer:** apply S1, S2 (Acc_ConvertIntListToTable — ids are numeric only, front never sends text), S3, S4, F2, F3, F4, F5, F6. B1 resolved (D4). B2 leave (controller precedent). B3 leave (sibling CR 125294 precedent, one config file per CR). F1 disagree allowed (surgical changes).
**Merged verdict round 1: pass — block 0, should 6 (1 resolved D5, F1 kept local), nit 10.**

## Status (implementer, round 1)

| Row | Status |
|---|---|
| 1 | done (resolved by the user as D5, no code change) |
| 2 | not in the binding list for this round; left as is |
| 3 | not in the binding list for this round; left as is |
| 4 | not in the binding list for this round; left as is |
| S1 | done |
| S2 | done |
| S3 | done |
| S4 | done |
| B1 | left (resolved by D4) |
| B2 | left (controller precedent) |
| B3 | left (sibling CR 125294 precedent) |
| F1 | disagree: moving the filter logic means editing the shared employee-month-form outside the CR (surgical changes) |
| F2 | done |
| F3 | done |
| F4 | done |
| F5 | done |
| F6 | done |
