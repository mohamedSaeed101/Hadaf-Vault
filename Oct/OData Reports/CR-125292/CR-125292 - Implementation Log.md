---
type: implementation-log
cr: 125292
created: 2026-10-14
updated: 2026-10-14
tags: [cr, cr-125292, implementation, payroll, odata, report-migration]
---

> [!info] Everything done on CR-125292 so far, in order. Facts: [[CR-125292 - Source]] · Plan: [[CR-125292 - Plan]] · Decisions: [[decisions]] · Open: [[open-questions]] · Resume: [[HANDOFF]]

# CR-125292 — Implementation log: payroll salary reports to OData

**State on 2026-10-14:** all code written for the 8 reports (DB + backend + layouts + front), **uncommitted** (engineer's rule: no commit until told). DB and backend builds green. Front not built yet (needs `npm install`). Parity on UnitedPlastic not run yet (env-pin hook blocks `web-test`).

## 1. Intake and analysis

- Read ADO 125292 (Change Request, PayRoll, Web, parent 68516, due 2026-12-31). `az boards` has no devops extension on this PC → read through the `azure-devops` MCP.
- Method: `mvc-to-odata-report-migration` skill inside the `onboard-ticket` spine. Size **L**.
- Precedents read:
  - Total Salaries **fx123253** (OData, `printOnlyMode`) + **fx124062** (old print kept beside it). Its entity hard-codes one tenant's salary items as columns: not copied.
  - Sibling set **cr125294** (advance/purchase payroll reports, uncommitted, local): interactive `report-grid` / `report-grid-multi-request`, actions in `PayrollOdataController`. Used as the grid template, never edited.
- Legacy dissection: 4 parallel read-only agents, 2 reports each, reading `origin/Master_Stable` via `git show` (main checkouts sit on `cr94062` / `Stage_Beta`). Output: the four `Legacy - …` notes in this folder.
- Findings (details in [[CR-125292 - Source]]):
  - Every SQL object the legacy queries use already exists in the cloud DB. `PR_EmployeeTotalSalariesReport` reusable by none of the 8.
  - No report pivots salary items to columns; R2 and R3 are master-detail.
  - Legacy layouts live in designer `.cs` files; per-user overrides are in `ACFX_ReportLayout` (same table the cloud uses) keyed by the rpt class name, so new layout names must differ.
  - Legacy defects: R6/R8 end-of-work join, R8 1024-char id cut, R3 double bank account, R4 "Main Salary" = `InsuranceCompany`, R5 single employee header.
  - Routes without ModuleId (admins only): R1, R5, R7; R4 inherits 285.

## 2. Decisions taken by the engineer (2026-10-14)

All recommended options → [[decisions]] D2–D6:
- D2 full interactive report grid (ticket AC), R2/R3 master-detail.
- D3 keep the old print during transition.
- D4 port legacy SQL exactly, drop only the 1024-char cut; R3/R4/R6/R8 defects go to the PO as separate Bugs.
- D5 user's security level in all 8.
- D6 menu ModuleIds on routes and endpoints: 514 / 537 / 542 / 543 / 539 / 540 / 538 / 541.
- Q7 parity tenant: **UnitedPlastic** on `web-test` (SQL login; password kept in `D:\Hadaf\.env.local`, git-ignored, never in chat).

## 3. Setup

| Step | Result |
|---|---|
| Vault | notes here (`D:\accflex-features` does not exist on this PC) |
| Merge Desk | `merge-desk` MCP had no PAT → `D:\Hadaf\.env.local` created (git-ignored) with `MERGEDESK_ADO_PAT` + `SQLCMDPASSWORD`, filled by the engineer, Claude Code restarted. `whoami` = Developer |
| Merge Desk ticket | created **#12459**: Beta, owner Mohamed Saeed, status Acknowledge, repos Database / API / WebContainer. Merge Desk cut `cr125292` off Master_Stable: DB `8a3f097c5`, API `84dc84ff0e`, Front `69b8fb2428` |
| Worktree set | `new-cr.ps1 -Kind CR -Id 125292 -Repos db,erp,front` → `D:\Hadaf\worktrees\cr125292`, tracking `origin/cr125292`, **port offset 200**. Front `node_modules` not linked (package.json differs from main) |
| ADO | 125292 already **In Development**, assigned Mohamed Saeed. Board lane shows STABLE although a CR goes to Beta (left alone) |
| env-pin | the `accflex-env-pin` plugin lists `web-test` as retired and blocks every command naming it. The auto-mode classifier refused Claude editing the plugin (self-modification / security weaken), so the engineer edits it (see §6) |

## 4. Implementation (phase table of [[CR-125292 - Plan]])

### P1 + P2 — SQL functions (wave 1, two implementers in parallel)

Folder `AccFlex_Cloud_Database_State\AccFlex_Cloud_Database_State\dbo\Functions\`:

| # | Function | Parameters |
|---|---|---|
| R1 | `PR_EmployeeSalariesSignatureReport` | @Month, @Year, @SecurityLevel, @EmployeeIds |
| R2 | `PR_EmployeeSummarizedSalariesReport` + `…Lines` | same |
| R3 | `PR_EmployeesDetailedSalariesReport` + `…Lines` | same |
| R4 | `PR_EmployeesSalariesInPeriodReport` | @FromDate, @ToDate, @SecurityLevel, @EmployeeIds |
| R5 | `PR_SalariesByIncomeGroupReport` | @Month, @Year, @IncomeId, @SecurityLevel, @EmployeeIds |
| R6 | `PR_DepartmentsMonthlySalariesReport` | @Month, @Year, @SecurityLevel, @DepartmentIds, @BranchIds |
| R7 | `PR_EmployeesNoIssuedSalariesReport` | @Month, @Year, @BranchId, @SecurityLevel |
| R8 | `PR_PostedSalariesReport` | @Month, @Year, @SecurityLevel, @IsPost, @EmployeeIds |

- Legacy SQL copied verbatim (joins, CTEs, DISTINCT lists, overrides); `RowNo` added outside the DISTINCT so rows don't change. Checked side by side against the legacy notes; P1 files parsed with ScriptDom TSql160.
- Security filter `PR_Employee.EmployeeSecurityLevel <= @SecurityLevel` everywhere (D5). NULL / '' ids = all. Raw money, no rounding.
- Extras: `EmployeeArabicName` (and Arabic/English currency + salary source, R4 `Mnth` / `MnthArabic`) — depend only on keys already in the DISTINCT lists, numbers unchanged.
- R3 lines carry `EmployeeInsuranceAmount` (income id 10) for the "Total Employees Insurance".
- Deviations: R3 lines also drop a 1024-char salary-id cut; R1/R2 empty list = all employees of the chosen month (what users always saw). R6/R7 keep their legacy filters (no employee filter added).

### P3 — sqlproj registration

- 10 `<Build Include="dbo\Functions\…" />` lines after `PR_EmployeeTotalSalariesReport`.
- VS 2022 **Community** MSBuild: green, 520 pre-existing warnings, none in new files. All 10 functions verified in the dacpac `model.xml`.

### P5 — AnalyticsReader backend (one implementer: shared files)

`AccFlex_Cloud_ERP\AnalyticsReader\AnalyticsReader.Api\`:
- `ODataViews\Payroll\<Name>Rpt\<Name>.cs` × 8 (R2/R3 files also hold the Lines entity), key `RowNo`, all else nullable.
- `ODataViewsConfigurations\Payroll\SalaryReportsConfigs\SalaryReportsConfigs.cs` — 10 configs, `ToFunction(...)`.
- `Models\DataContext.cs` — 10 DbSets.
- `ODataControllers\Payroll\PayrollOdataController.cs` — 7 ModuleIds added to the enum (R1 reuses `SalaryReport = 514`), 10 actions appended at the end.
- `AngularReports\Payroll\SalaryReports\<Name>RptAng.cs` × 8 + `SalaryReportOptions.cs` (period / id-list parsing, period label).

Routes (`odata/<Name>` = ReportName = layout name) and query options:

| Route | ModuleId | Options |
|---|---|---|
| EmployeeSalariesSignature | 514 | period, employeeids |
| EmployeeSummarizedSalaries / …Lines | 537 | period, employeeids |
| EmployeesDetailedSalaries / …Lines | 542 | period, employeeids |
| EmployeesSalariesInPeriod | 543 | fromDate, toDate, employeeids |
| SalariesByIncomeGroup | 539 | period, incomeId (required), employeeids |
| DepartmentsMonthlySalaries | 540 | period, departmentids, branchids |
| EmployeesNoIssuedSalaries | 538 | period, branchId (required) |
| PostedSalaries | 541 | period, isPost, employeeids |

- Bad input → empty list, never throws. Missing `isPost` = false (legacy default).
- R4 dates: start of "from" day to end of "to" day (legacy used raw timestamps).
- Own id-list parser (`RemoveQuotesWithConvertTolist` throws on `""`); the old `a..b` range syntax is not supported.
- Build: `dotnet build AnalyticsReader.Api.csproj -p:LibraryRestore=false` → **0 errors** (LibMan can't find node_modules in the set). The build rewrites 5 tracked `wwwroot` bundles → restored with `git checkout` after every build.

### P6 — print layouts

- `Scripts\ReferenceDataScripts\0414_PR_SalaryReportsLayout.sql` (0412 highest on the branch, 0413 taken by cr125294): 16 × `EXEC dbo.InsertLayout`, ApplicationId 4, `الافتراضي` ar-EG (RTL master) + `Default` en-US per report. XML names `rpt<ReportName>` (no legacy class names). Registered as `<None Include>`.
- Legacy structure kept (columns, order, grouping, totals), palette and alignment per `accflex-report-layout`. R5's single-header bug fixed (groups by employee). R4 "Main Salary" binds `InsuranceCompany` (D4). Money `{0:N2}` on the raw field.
- Checks: sqlproj build green, `postdeploy.sql` references 0414, all 16 XMLs load with `[xml]`, matching cell weights.
- **Fix by the main session:** R3's "Total Employees Insurance" summed the lines attached to every header row, which doubles for a second bank account (legacy counted each line once). Now `EmployeesDetailedSalariesRptAng` sums the lines list once and passes report parameter `totalEmployeesInsurance` (N2); both R3 layouts declare `Item13 Ref="100099"` and bind `?totalEmployeesInsurance`. Rebuilt: backend 0 errors, sqlproj green.

### P7 — front

`AccFlex_Cloud_Front\accflex-erp\projects\payroll\src\app\modules\accounting-reports\`:
- 8 shells (`.ts` + `.html`): R1, R4–R8 on `report-grid`; R2, R3 on `report-grid-multi-request` (lines filtered by `SalaryId`). ApplicationId 4, `TranslationObjectKey="SALARYREPORTS"`, order by `RowNo`, preview disabled until required filters are set.
- Existing filter forms reused (read through `#ReportFormRef`), so the input contract is unchanged; `employeeids` omitted when nothing or everything is selected.
- `accounting-reports.module.ts`: ModuleIds added for salary-report 514, salary-by-income 539, no-salary-issued 538, salaries-in-peroid 543.
- Old print (D3): the existing "Print" button of `salary-report-form` and `income-group-report-form` (used only by these 8 screens) relabelled **"Print (previous design)"**; it still runs the unchanged iframe path.
- `src\assets\i18n\{en-US,ar-EG}\payroll.json`: new `SALARYREPORTS` block (35 keys) after `SALARY`, away from cr125294's insert.
- Checks: JSON parses; **`npm run testing` EXIT 0** (full shell build, 2026-10-14).
- Grid has no totals row (no input for it); totals live in the print layouts. Currency / salary source follow the UI language.

## 5. Changed files (uncommitted, branch `cr125292`)

- **DB (12):** `.sqlproj`; 10 `dbo\Functions\PR_*.sql`; `Scripts\ReferenceDataScripts\0414_PR_SalaryReportsLayout.sql`.
- **ERP (19 paths):** `DataContext.cs`, `PayrollOdataController.cs`; 8 `ODataViews\Payroll\*Rpt\*.cs`; `SalaryReportsConfigs.cs`; 8 `*RptAng.cs` + `SalaryReportOptions.cs`.
- **Front (21):** module, 2 form templates, 8 shells × 2, 2 `payroll.json`.

## 6. Still open

1. ~~`npm install` + `front-verify-build`~~ **done 2026-10-14**: `npm run testing` EXIT 0, no TS/NG errors; Prettier warnings on all 19 files are pre-existing on the base (line endings).
2. **P4 parity** on UnitedPlastic (`web-test`): the engineer edits the installed env-pin copy `C:\Users\Hadaf\.claude\plugins\cache\hadaf-accflex\accflex-env-pin\0.2.0\hooks\register.ts` (`server: 'web-test'`, `database: 'UnitedPlastic'`, `retired: []`; also the marketplace copy if a restart re-syncs it, or `/env`), restarts. Then legacy queries vs TVFs, same params, set comparison; R4 with date-only values. Zero difference = pass.
3. **P8** app check: local AnalyticsReader (+200) + front, print and export each report in AR/EN, compare with the old print; settle Q8 (R2 employee list once vs per employee).
4. Then `/review-code 125292` (engineer's trigger), `remove-redundant`, ship via Merge Desk Solved.
5. PO Bugs from D4 (R3, R4, R6/R8) — to raise.
6. Merge with cr125294: adjacent-line conflicts expected in `DataContext.cs`, `PayrollOdataController.cs`, `accounting-reports.module.ts`, `payroll.json`, `.sqlproj`.

## 7. P4 parity on UNP-Ali (2026-10-14, second PC)

- Tenant **UNP-Ali** on **db-all** (engineer's choice, replaces Q7's UnitedPlastic / web-test). SQL login from `C:\Hadaf_Work\.env.local` (`ACCFLEX_DB_USER` / `ACCFLEX_DB_PASSWORD`), db_owner. The 10 TVFs are **not** deployed there; read-only check: TVF bodies from `origin/cr125292` run verbatim as queries, legacy SQL verbatim from the AccFlex_ERP `origin/Master_Stable` `.xsd` adapters + C# WHERE text. Temp tables only, nothing written.
- Code state at that time: committed and pushed, one commit per repo on `origin/cr125292` (DB `b4c7f47f5`, ERP `b22707afbb`, Front `80b98cabdb`); no PRs.
- Checks per case: row counts, EXCEPT both ways, grouped-count EXCEPT (duplicates), money sums. Scripts in `parity\` in this folder (`run.sh` loads `.env.local` without printing it).

| Report | Cases with data | Result |
|---|---|---|
| R1 | 2026/08 all (78), 2026/05 all (6), id lists | PASS |
| R2 header / lines | 2026/05 all + ids (4 / 5 rows; sums 35230.66 / 19600.60) | PASS (2026/08 empty both sides: nothing posted) |
| R3 header / lines | 2026/08 all (78 / 1458, sum 394014.61), 2026/05, ids | PASS |
| R4 | 04-01..08-31 all (81), ids, 07-01..07-31 (75) | PASS; Arabic month and order match |
| R5 | 2026/07 groups 3 / 1 / 6, all + ids (850 / 206 / 24 / 4) | PASS (2026/08 empty: nothing posted) |
| R6 | 2026/08 all / branch / 2 depts, 2026/07, 2026/05 | PASS, 4 money sums equal |
| R7 | 2026/08, 06, 09, 07 at branch 1 | PASS at level 5; level 1/3 drop one employee each = D5 |
| R8 | 2026/08 posted/unposted, 2026/07 ids, 2026/05 | PASS, also at level 1 |

**Not covered by this tenant's data:** end-of-work (0 rows in `PR_EmployeeEndWork`, so the R6/R7/R8 end-of-work path is untested); the R3 double bank account (no employee has 2 banks per currency); insurance / tax (InsuranceCompany, income 10, 11 all 0); security level below 5 only on R7/R8; 1024-char id cuts never triggered (88 employees = 276 chars).

**Observed, same on both sides (legacy behaviour kept):** R6 2026/05 prepaid-vacation rows: additions 2059.48 − deductions 0 ≠ net 2263.39. R4 legacy with time-of-day date boxes (default "now") returns 0 rows where the new date-only range returns 75: the documented legacy defect, fixed on purpose by the start/end-of-day rule. Candidates for the PO list beside D4.
