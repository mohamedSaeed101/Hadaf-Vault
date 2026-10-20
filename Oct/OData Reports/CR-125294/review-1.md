# Review round 1 — CR_125294   base db 8a3f097c5 / erp 84dc84ff0e / front 69b8fb2428   head = base + uncommitted working tree   verdict: pass

Worked from `CR-125294 - Source.md` (A1–A4), `decisions.md` (D1–D7), `CR-125294 - Legacy Analysis.md`, `CR-125294 - OData Reports.md` and `HANDOFF.md`. The set has no `spec.md` or `facts.md`. Legacy SQL was checked directly against `AccFlex_ERP\HRManagement\Payroll.Reports\HR\{EmployeeUnPaidAdvancedPaymentsBalance,EmployeesAdvance,EmployeesDeductions}\*.xsd` and the MVC `AccountingReportsController`.

| # | file:line | severity | rule / spec line | finding | required change |
|---|---|---|---|---|---|
| 1 | AccFlex_Cloud_Front/accflex-erp/projects/payroll/src/app/modules/accounting-reports/containers/advance-report-shell/advance-report-shell.component.ts:35 (same in employee-deduction-shell.component.ts:35, unpaid-advanced-payments-shell.component.ts:36) | should | Front `core.md` "Subscriptions: `SubSink`" | `getLang().subscribe(...)` on the root `BehaviorSubject` is never unsubscribed. Each visit to the screen leaves a subscriber holding the destroyed component. Copied from the `employee-accurals-details-shell` sibling, but these are new lines | Add a `SubSink`, `subs.add(...)` the subscription and unsubscribe in `ngOnDestroy` in all three shells |
| 2 | …/advance-report-shell.component.ts:50,61; employee-deduction-shell.component.ts:50,61; unpaid-advanced-payments-shell.component.ts:73 | nit | Front `core.md` "avoid adding new `any`" | New `(e: any)` in `handleEmployeeIdChange` and an untyped `onDetailExpand(e)` | Type `onDetailExpand(e: DetailExpandEventArgs)` (it exists in `report-grid-multi-request/DetailExpandEventArgs.ts`). Use a small `{ selectedRowKeys: number[]; isSelectAll: boolean }` type for the employee change |
| 3 | AccFlex_Cloud_ERP/…/AnalyticsReader.Api/ODataViewsConfigurations/Payroll/AdvanceAndPurchaseRptConfigs/AdvanceAndPurchaseRptConfigs.cs:1 | nit | ERP `report-backend.md` "Artifact 2: EF Configuration" (`{EntityName}Config.cs`; several in one file only for master-detail) | Three unrelated reports' configs share one file | Optional: split into `UnpaidAdvancePaymentsConfig.cs`, `EmployeesAdvanceConfig.cs` (header and repayment), `EmployeePurchaseConfig.cs` (header and repayment) |
| 4 | AccFlex_Cloud_ERP/…/ODataControllers/Payroll/PayrollOdataController.cs:206,228,249,270,291 | nit | backend: ERP `accflex-erp-api.md` §API Layer | `[ProducesResponseType(StatusCodes.Status200OK)]` without a type and no 400 `ProblemDetails` attribute. Every sibling action in this controller is the same (lines 54, 82, 112, 143, 177) | Optional: keep sibling style |
| 5 | AccFlex_Cloud_ERP/…/ODataViews/Payroll/EmployeesAdvanceRpt/EmployeesAdvance.cs:28; EmployeePurchaseRpt/EmployeePurchase.cs:28 | nit | backend: ERP `report-backend.md` §Master-Detail Reports | The `List<…Repayment>` is exposed as an OData navigation property but ignored in EF, so `$expand=…Repayment` on the header endpoint returns 500. The Front never sends `$expand`; `PurchaseReturnsReportPrinter` has the same pattern | Optional: leave to match precedent |
| 6 | AccFlex_Cloud_ERP/…/AngularReports/Payroll/AdvanceAndPurchaseReports/UnpaidAdvancePaymentsRptAng.cs:41-45 | nit | backend: ERP `report-backend.md` §Artifact 4 | `Parameters` carries only fromDate / toDate; the applied in-service filter does not reach the print layout | Only if the 0413 layout shows it: add `inServiceFilter` to `Parameters` |
| 7 | AccFlex_Cloud_Database/…/dbo/Functions/PR_UnpaidAdvancePaymentsReport.sql:6 (and the other 4 TVFs) | nit | sql: DB `report-database-functions.md` §Standard Parameter Patterns | `@EmployeeIds NVARCHAR(MAX)` has no `= NULL` default. No runtime effect: every caller passes all arguments and `ISNULL(@EmployeeIds,'') = ''` treats NULL as "all". Sibling `PR_EmployeeAdvanceTransactionsReport` is the same | Optional: `= NULL` default |

Merged by main from the Opus backend-reviewer (0 block / 0 should / 3 nit) and sql-reviewer (0 block / 0 should / 1 nit). Both confirm: TVF names, parameter order and columns match the entities; unpaid TVF is numerically identical to the legacy query (GetDayEnd 23:59:59.997 normalises to 23:59:59 like legacy); advance repayment `Amount AS PaiedAmount` is legacy-verbatim; 0413 seed is free on Master_Stable/Stage_Beta/Stage_Stable, has no GO, and is idempotent via `dbo.InsertLayout`. Reviewers ran on Opus 5.5 because Fable 5.1 was out of credits; the code was written by Sonnet 5.5, so the reviewer is still a different model.

## Checked, no finding

- **A1**: all three shells now use `report-grid` / `report-grid-multi-request` against `UnpaidAdvancePayments`, `EmployeesAdvance(+Repayment)` and `EmployeePurchase(+Repayment)`. No `accflex-report-iframe*` is left in them, and no import was orphaned.
- **A2 / D1 (logic only)**:
  - The Unpaid TVF matches the legacy `dsEmployeeUnPaidAdvancesPayments` CTEs line for line: flags, `<`/`<=` window, inner Department/Branch joins, and the `TRIM` in-service filter.
  - The Advance and Purchase TVFs match the legacy `FillByEmployeeID` / `FillBy` exactly when employees are picked. With no employee picked they differ on purpose (D1).
  - Detail TVFs: Advance repayments use `PaiedAmount = Amount`, as in legacy. Purchase repayments use the real `PaiedAmount` column.
  - Day bounds: the backend `GetDayEnd()` (.997 ms, safe for DATETIME) is normalised again inside the TVFs, and the front sends `yyyy-MM-dd`.
  - Column types (MONEY → `decimal?`, INT → `int?`, BIT → `bool?`) match the entity properties.
- **Front in-service rule**: the Unpaid shell reproduces `employee-from-to-form.handleFilter`. Select-all or an empty pick sends no list. When the pick equals every in-service (or every terminated) employee, it sends `AllInService` / `AllTerminated` and no list. Otherwise it sends `employeeids`.
- **A3**:
  - `0413_PR_AdvanceAndPurchaseReportsLayout.sql` has 6 `InsertLayout` calls: `@ReportName` UnpaidAdvancePayments / EmployeesAdvance / EmployeePurchase, each with `ar-EG` (الافتراضي) and `en-US` (Default), all `@ApplicationId = 4`. This is the same shape as 0412.
  - Every ObjectDataSource type resolves to the new entity classes.
  - Every bound field exists on its entity: `[BeforeDateAmount]…[PeriodPayment]`, `[AdvanceAmount]`/`[PurchaseAmount]`, `[ArabicLetter]`/`[EnglishLetter]`, and the detail `DataMember` `EmployeesAdvanceRepayment` / `EmployeePurchaseRepayment` with fields `[PaymentDate] [Amount] [Paid] [PaidDate] [PaiedAmount]`.
  - The file is registered as `<None Include>`.
- **A4**:
  - ModuleIds 547 / 549 / 551 match `SharedKernel.Logic.Modules.Module` (EmployeeDeductionReport, UnPaidAdvancedPaymentsReport, AdvanceReport).
  - Each is used on its controller actions (header and detail) and on the routes' `data: { ModuleId }`.
- **D3**: `_userSession.SecurityLevel` is passed to all five TVFs, on both the OData path and the print path. The same mechanism is already used by `PR_BankSalaryReport`.
- **i18n**: every `ADVANCEPURCHASEREPORTS.*` key used by the shells is present in both `en-US` and `ar-EG` `payroll.json`. Reused keys (`ADVANCE._DateFrom_`/`_DateTo_` in shared.json, `EMPLOYEE._AdvanceCount_`, `ACCOUNTINGREPORTS.*`) exist. The currency column follows the UI language, and a language change reloads the page (`nav.service.ts`).
- **Template rule**: no template-bound getters. The literal arrays (`[detailqueryoptions]="[gridQueryOptions]"` etc.) are pure template literals, memoised by Angular, and follow the sibling pattern.
- **DB rules**:
  - Every TVF has `ROW_NUMBER() … AS RowNo` first, uses `Acc_ConvertIntListToTable`, has the `PR_` prefix, and has a `<Build Include>` in the sqlproj.
  - `RunReferenceDataScriptsGenerated.sql` is git-ignored.
- **Surgical / scope / compatibility**:
  - The changes are limited to the 3 shells, the routes' `data`, the i18n block, the new AnalyticsReader artifacts with 5 DbSets and 5 actions, and the DB objects.
  - No shipped DTO, route or column was changed.
  - The legacy MVC endpoints are untouched.
- **Secrets / ports / local paths**: none in the diff or in the new files.

## Not verified (not blocking)

- **A2 numbers**: `parity-125294.sql` has not been run on UnitedPlastic / support-db2 (D6) because DB credentials are blocked. This is the only test of the numbers. There is no automated test for the TVFs or the front: there is no Front test runner, and no AnalyticsReader test project exists.
- **A3 in-app**: print and Excel/PDF export in Arabic and English, the detail expand and the group-by have not been run in the app.

## Implementer (round 1)

Changes are uncommitted on purpose, because the engineer commits. Build gate: `npm run testing` was run against the main checkout's node_modules through a temporary junction, which was removed afterwards. It showed the known 4-error baseline, all in `projects/logistics/.../SalesQuotation/shared/sales-quotation-data.service.ts` (client-version mismatch). There were 0 errors in payroll.

| # | status |
|---|---|
| 1 | done: all three shells hold a `SubSink`, `subs.add(...)` the `getLang()` subscription, and implement `OnDestroy` with `this.subs.unsubscribe()` |
| 2 | done: `onDetailExpand(e: DetailExpandEventArgs)` in advance-report and employee-deduction (the unpaid shell has no detail grid). `handleEmployeeIdChange(e: { selectedRowKeys: number[]; isSelectAll: boolean })` in all three, which matches what `shared-employee-list` emits |
| 3 | skipped: optional, kept sibling style (reviewer accepted) |
| 4 | skipped: optional, kept sibling style (reviewer accepted) |
| 5 | skipped: optional, kept sibling style (reviewer accepted) |
| 6 | skipped: optional, kept sibling style (reviewer accepted) |
| 7 | skipped: optional, kept sibling style (reviewer accepted) |
