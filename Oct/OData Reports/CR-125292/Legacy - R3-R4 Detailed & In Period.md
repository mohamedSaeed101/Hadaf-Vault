# CR 125292 — Legacy inventory B: Employees Detailed Salaries + Employees Salaries In Period

All sources read from `origin/Master_Stable` (read-only). Repo prefixes:
`ERP` = `D:\Hadaf\AccFlex_ERP`, `FRONT` = `D:\Hadaf\AccFlex_Cloud_Front\accflex-erp`,
`DB` = `D:\Hadaf\AccFlex_Cloud_Database\AccFlex_Cloud_Database_State\AccFlex_Cloud_Database_State`.

Shared plumbing for both reports:

- Controller: `ERP\AccFlexContainer\AccFlexContainer.MVC\Controllers\PayrollReports\AccountingReportsController.cs` (netcoreapp3.1, DevExpress 20.2.3).
- `BaseController` (same folder's parent `Controllers\BaseController.cs`) sets **static** `Payroll.Reports.MainConfigrationData.SecurityLevel` = 5 if the `isAdmin` claim is true, else `int.Parse(securityLevel claim)`; also sets the static `ConnectionString` / `UserName`. `ChangeThreadCulture(lang)`: `lang == "en-US"` → en-US, **anything else → ar-EG**.
- `ReportView.cshtml` (`ERP\AccFlexContainer\AccFlexContainer.MVC\Views\Report\ReportView.cshtml`) loads a **per-user saved layout** from `dbo.ACFX_ReportLayout WHERE Name = Model.GetType().Name AND UserId = @UserId AND Language = <culture>` (`Services\ReportLayoutDatabaseStore.cs`) and, if found, `LoadLayout` over the designer layout. Note: it is the **same** `ACFX_ReportLayout` table the cloud uses, keyed by the CLR type name (`rptEmployeesSalariesDetails`, `rptEmployeeSalariesBetweenPeriod`), not the `Name` property set in the ctor. No `.repx` exists on disk (no `D:\Hadaf\ReportLayout`, no `.repx` for these in any repo) — the designer `.Designer.cs` is the only layout source unless a tenant user saved one.
- Base class `ERP\HRManagement\Payroll.Reports\rptMainReport.cs` (+ `.designer.cs`): `BeforePrint` fills `PR_SystemConfiguration` (row 0) → ReportHeader: Logo, CompanyName, Email, Fax, Telephone, Address; PageFooter: page info, `PC:{MachineName}`, `User:{UserName}`.
- Front (both shells): `FRONT\projects\payroll\src\app\modules\accounting-reports\…`, form `components\salary-report-form\salary-report-form.component.{ts,html}`, URL built by `FRONT\src\app\shared\services\report-src-handler\report-src-handler.service.ts`:
  `${printRedirectUrl}${path}?lang=${lang}&${query}` (+ `&access_token=…` when not production). `lang` = `'ar-EG'` unless the UI language is `en-US`.
  Query serialized by `FRONT\src\app\shared\services\query-serialize\query-serialize.service.ts`: `Date` → `addHoursUTCDifferent(d).toISOString()` (shifts by the browser TZ offset so the ISO string carries the **local wall-clock time with a `Z` suffix**, e.g. `2026-05-01T00:00:00.000Z`); arrays → `encodeURIComponent(array)` = **CSV** (`Array.toString`). `CleanObjectService.cleanNullAndEmptyString` drops null/''/' '/undefined keys.
  `accflex-report-iframe-post` (`FRONT\src\app\shared\components\report-iframe-post\…`) de-serializes that query and **POSTs** it as hidden form fields to the `/mvc/…` endpoint (target = iframe).
  ASP.NET Core 3.1 `DateTimeModelBinder` parses the `…Z` value with `AdjustToUniversal`, so the controller receives the user's local wall-clock date/time (Kind=Utc).
- Route parent: `FRONT\projects\payroll\src\app\routes.ts` → `accounting-reports` (lazy, componentless, `data: { ModuleId: 285 }`). Guard `FRONT\projects\payroll\src\app\core\interceptors\can-activate\can-activate-route.guard.ts` reads `route.data.ModuleId`, admins bypass, else needs `AllowView` in `UserPermissions<HR app>`.

---

## Report 3 — Employees Detailed Salaries

### a. Input contract

| Key | Type sent | Built from | Notes |
|---|---|---|---|
| `lang` | `ar-EG` / `en-US` | ReportSrcHandlerService | |
| `employeeIds` | CSV string of ints, **or key omitted** | form `EmployeeIdList` (grid `selectedRowKeys`) | Form: if none selected → `getAllEmployeeIds().split(',')` (all ids in the shared employee list). Shell: if `selected.length === allEmployees.length` → `null` → key removed → controller gets `null` → SQL `@EmployeeIds IS NULL` = **all employees in the DB** (no security-level filter). Otherwise CSV. |
| `month` | ISO string (`Date`), required | form `Month` (dx-date-box `MM/yyyy`, default `new Date()` = now incl. time) | Only `.Month` / `.Year` are used by the controller. |

Shell: `containers\employees-detailed-salaries-shell\employees-detailed-salaries-shell.component.{ts,html}`. Form flags: `isShowSharedEmployeeList=true`, `isShowPostedSalaryCheck=true`, `isInPeriodDate=false`, branch/department/income hidden. The **"posted salary" checkbox (`IsPosted`) is shown and emitted but the shell ignores it** — never sent. Validation: `isFormValid()` = `Month` truthy.

Example: `…/mvc/AccountingReports/EmployeesDetailedSalaries?lang=ar-EG&employeeIds=12,15,19&month=2026-05-14T10:22:31.000Z`

### b. Controller

```csharp
[Route("mvc/AccountingReports/EmployeesDetailedSalaries")]
public IActionResult EmployeesDetailedSalaries(string lang, string employeeIds, DateTime month)
{
    ChangeThreadCulture(lang);
    var report = new Payroll.Reports.Accounting.Salary.rptEmployeesSalariesDetails(month.Month, month.Year, employeeIds);
    return View(REPORTS_ROOT_VIEW, report);
}
```
Ctor order is `(salaryMonth, salaryYear, employeesIds)`. No security level is passed or used.

Report class: `ERP\HRManagement\Payroll.Reports\Accounting\Salary\rptEmployeesSalariesDetails.cs` (+ `.Designer.cs`, `.resx`), DataSet `…\Salary\dsEmployeesSalariesDetails.xsd`. `Name` = `rptEmployeeSalariesDetails` (en) / `rptEmployeeSalariesDetailsAreg` (ar) — not used for layout lookup (type name is).

### c. SQL and C#

**TableAdapter `EmployeeSalaryDetail.Fill(@Month, @Year, @EmployeeIds)`** (verbatim; `@Month int`, `@Year int`, `@EmployeeIds nvarchar` nullable):
```sql
    SELECT DISTINCT
            dbo.PR_Employee.EmployeeName ,
            dbo.PR_Employee.EmployeeArabicName ,
            dbo.PR_Bank.BankName ,
            dbo.PR_EmployeeBank.AccountNo ,
            dbo.Acc_Currency.CurrencyName ,
            dbo.PR_Branch.BranchName ,
            dbo.PR_Department.DepartmentName ,
            dbo.PR_SalaryMain.SalaryMonth ,
            dbo.PR_SalaryMain.SalaryYear ,
            PR_Projects.ProjectName ,
            dbo.PR_Salaries.InsuranceCompany ,
            PR_Salaries.EmployeeId ,
            PR_Salaries.SalaryId
    FROM    dbo.PR_SalaryDetail
            INNER JOIN dbo.PR_Income ON dbo.PR_Income.IncomeId = dbo.PR_SalaryDetail.EmployeeIncomeId
            INNER JOIN dbo.PR_Salaries ON dbo.PR_Salaries.SalaryId = dbo.PR_SalaryDetail.SalaryId
            INNER JOIN dbo.PR_Employee ON dbo.PR_Employee.EmployeeId = dbo.PR_Salaries.EmployeeId
            INNER JOIN dbo.PR_SalaryMain ON dbo.PR_SalaryMain.SalaryMainId = dbo.PR_Salaries.SalaryMainId
            INNER JOIN dbo.Acc_Currency ON dbo.Acc_Currency.CurrencyId = dbo.PR_Salaries.CurrencyId
            LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
            LEFT OUTER JOIN dbo.PR_Department ON dbo.PR_Employee.DepartmentId = dbo.PR_Department.DepartmentId
            LEFT OUTER JOIN dbo.PR_Branch ON dbo.PR_Employee.BranchId = dbo.PR_Branch.BranchId
            LEFT OUTER JOIN dbo.PR_EmployeeBank ON dbo.PR_EmployeeBank.EmployeeId = dbo.PR_Employee.EmployeeId
                                                   AND dbo.PR_EmployeeBank.CurrencyId = dbo.PR_Salaries.CurrencyId
            LEFT OUTER JOIN dbo.PR_Bank ON dbo.PR_Bank.BankId = dbo.PR_EmployeeBank.BankId
    WHERE   ( @EmployeeIds IS NULL
              OR PR_Salaries.EmployeeId IN (
              SELECT    number
              FROM      dbo.iter$simple_intlist_to_tbl(@EmployeeIds) AS iter$simple_intlist_to_tbl_1 )
            )
            AND SalaryMonth = @Month
            AND SalaryYear = @Year;
```

**TableAdapter `incomeGroup.Fill(@SalaryId)`** (verbatim; `@SalaryId nvarchar(1024)` = CSV built in C#):
```sql
SELECT  dbo.PR_Income.IncomeName ,
        dbo.PR_IncomeGroup.IncomeType ,IncomeId,
        IncomeAmount ,
        SalaryId
FROM    dbo.PR_SalaryDetail
        INNER JOIN dbo.PR_Income ON dbo.PR_Income.IncomeId = dbo.PR_SalaryDetail.EmployeeIncomeId
        INNER JOIN dbo.PR_IncomeGroup ON dbo.PR_IncomeGroup.IncomeTypeId = dbo.PR_Income.IncomeTypeId
WHERE   SalaryId IN (
        SELECT  number
        FROM    dbo.iter$simple_intlist_to_tbl(@SalaryId) AS iter$simple_intlist_to_tbl_1 )
ORDER BY SalaryId;
```

DataSet relation `DataTable1_incomeGroup`: parent `EmployeeSalaryDetail.SalaryId` → child `incomeGroup.SalaryId`. PKs declared: `EmployeeSalaryDetail(SalaryId)`, `incomeGroup(IncomeId)` (!), but `EnforceConstraints = false` and `ClearBeforeFill = true` (initial-load path, rows are appended, not merged), so duplicates survive silently.

**C# in `rptEmployeesSalariesDetails_BeforePrint`:**
1. Arabic → RTL.
2. Fill `EmployeeSalaryDetail(salaryMonth, salaryYear, employeesIds)`.
3. `SalaryIds = string.Join(",", EmployeeSalaryDetail.Select(u => u.SalaryId))` → Fill `incomeGroup(SalaryIds)`. (If the first query returns 0 rows, `SalaryIds = ""` → split fn converts `''` → 0 → no rows.)
4. `TotalEmployeeInsurance.Text = Convert.ToDecimal(incomeGroup.Where(u => u.IncomeId == 10).Sum(u => u.IncomeAmount)).ToString();` — **hard-coded IncomeId 10** (employee insurance share), summed across **all** salaries in the report, raw `decimal.ToString()` under the thread culture (money scale 4 → e.g. `1234.5600`). The unused local `IncomeAmount` duplicates the same sum.
No rounding anywhere in C#.

### d. Printed layout (designer `rptEmployeesSalariesDetails.Designer.cs`, A4 portrait, Dpi 254)

Main report `DataMember = EmployeeSalaryDetail` (one iteration per salary row, **no sort/group fields → SQL row order of the DISTINCT**). Bands:
- ReportHeader (base): company logo/name/address/tel/email/fax.
- PageHeader: `lblReportName` = "Employee Salaries Details" / ar "تقرير مرتبات الموظفين تفصيلي".
- DetailMain: empty.
- GroupHeader2 (Level 1, height 0, no group fields): empty.
- **DetailReport** (`DataMember = EmployeeSalaryDetail.DataTable1_incomeGroup`, i.e. the income lines of the current salary; no sort):
  - GroupHeader1 (RepeatEveryPage, KeepTogether) — per salary/employee header table + values:
    | # | Caption (en / ar) | Binding |
    |---|---|---|
    | 1 | Employee Name / اسم االموظف | `EmployeeName` (**English name in both languages**; `EmployeeArabicName` fetched but unused) |
    | 2 | Bank Name / البنك | `BankName` |
    | 3 | Account No / رقم الحساب | `AccountNo` |
    | 4 | Currency Name / العملة | `CurrencyName` (Acc_Currency.CurrencyName in both languages) |
    | 5 | Month / الشهر | `SalaryMonth` (int) |
    | 6 | Year / السنة | `SalaryYear` (int) |
    | 7 | Insurance Company / حصة الشركة من التامينات | `InsuranceCompany` (no format string → raw money, 4 dp) |
    then the income column header row: Income Name / الدخل · Income Type / نوع الدخل · Income Amount / القيمة.
  - Detail (one row per income line): `IncomeName`, `IncomeType` (PR_IncomeGroup.IncomeType), `IncomeAmount` (no format → raw 4 dp).
- GroupFooter1 (main report, no group fields → printed once after the last record):
  - "Total Insurance Company" / "اجمالي حصة الشركة من التامينات": summary of `InsuranceCompany`, Func default **Sum**, `Running = Report`, format `{0:0.00}`.
  - "Total Employees Insurance" / "اجمالي حصة الموظفين من التامينات": `TotalEmployeeInsurance` — text set in C# (step 4 above); its summary has `Running = None`, so the `{0:0.00}` format is not applied.
- Not printed: BranchName, DepartmentName, ProjectName, EmployeeArabicName, EmployeeId, SalaryId.

**Dynamic salary items:** the incomes are **rows** in a sub-band (master/detail via the DataSet relation), **not pivoted columns**. A fixed-column OData entity works: one row per (SalaryId, income line) carrying the employee header columns repeated, plus grand totals computed in SQL (or as report summaries).

### e. Cloud DB dependencies (all under `DB\dbo\…`, all present and registered in the `.sqlproj`)

| Object | Exists | Path | Notes |
|---|---|---|---|
| PR_SalaryDetail | Y | Tables\PR_SalaryDetail.sql | Has `Suspend`, `Deduction`, `UserAmount` — legacy ignores `Suspend` |
| PR_Income | Y | Tables\PR_Income.sql | `IncomeTypeId` NULLable → such incomes drop out of query 2 (INNER JOIN PR_IncomeGroup) but still qualify the salary in query 1 |
| PR_IncomeGroup | Y | Tables\PR_IncomeGroup.sql | `IncomeType nvarchar(50)` |
| PR_Salaries | Y | Tables\PR_Salaries.sql | `InsuranceCompany money`; cloud also has `DepartmentId` (salary-time dept) — legacy uses employee's current dept (not printed here) |
| PR_SalaryMain | Y | Tables\PR_SalaryMain.sql | `IsVacationSalary`, `IsDeleted` exist; **legacy MVC filters neither** |
| PR_Employee | Y | Tables\PR_Employee.sql | |
| Acc_Currency | Y | Tables\Acc_Currency.sql | |
| PR_Projects | Y | Tables\PR_Projects.sql | |
| PR_Department | Y | Tables\PR_Department.sql | |
| PR_Branch | Y | Tables\PR_Branch.sql | |
| PR_EmployeeBank | Y | Tables\PR_EmployeeBank.sql | **No unique key on (EmployeeId, CurrencyId)** → multiple accounts duplicate the salary row |
| PR_Bank | Y | Tables\PR_Bank.sql | |
| dbo.iter$simple_intlist_to_tbl | Y | Functions\iter_simple_intlist_to_tbl.sql | multi-statement; NULL → '0'; byte-identical body to Acc_ConvertIntListToTable |
| PR_SystemConfiguration | Y | Tables\PR_SystemConfiguration.sql | header only (base report) |
| Vw_Pr_SalaryDetail (candidate) | Y | Views\Vw_Pr_SalaryDetail.sql | Close but **not** a drop-in: dept via `ISNULL(PR_Salaries.DepartmentId, PR_Employee.DepartmentId)`, lacks InsuranceCompany/ProjectName/EmployeeId/IncomeId/SalaryDetailId-per-header, already INNER JOINs PR_IncomeGroup |

Precedent `DB\dbo\Functions\PR_EmployeeTotalSalariesReport.sql` (inline TVF, `@Month, @Year, @SecurityLevel, @EmployeeIds = NULL, @InServiceFilter = NULL`): same base tables, but it **pivots a fixed list of IncomeIds into columns**, filters `IsVacationSalary = 0`, and applies `EmployeeSecurityLevel <= @SecurityLevel`. Not composable for this report (different grain: one row per salary vs per income line; different filters). Reuse its parameter shape/conventions (Month/Year/SecurityLevel/EmployeeIds CSV via `Acc_ConvertIntListToTable`) and write a new TVF directly over the base tables reproducing the two legacy queries joined on SalaryId.

### f. Route / permission
`FRONT\projects\payroll\src\app\modules\accounting-reports\accounting-reports.module.ts`: path `employees-detailed-salaries-report` → `EmployeesDetailedSalariesShellComponent`, `canActivate: [CanActivateRouteGuard, AccflexAuthGuard]`, **`data: { ModuleId: 542 }`**. `Acc_Module` 542 = "Employees Detailed Salaries Report" / "تقرير مرتبات الموظفين تفصيلي", group "Accounting Report" (`DB\Scripts\ReferenceDataScripts\0002_Acc_Module_Data.sql` line ~488). Title i18n `ACCOUNTINGREPORTS._EmployeesDetailedSalaries_`. Not in the payroll home-page tiles.

### g. Risks for 1:1 reproduction
1. **No security-level filter** in legacy (unlike precedent TVF). With "all selected" the shell sends no `employeeIds` → every employee in the tenant with a salary that month, regardless of the user's security level. Decide: reproduce (identical numbers) or add `@SecurityLevel` (deliberate deviation — record in decisions).
2. **No `Posted`, `IsVacationSalary`, `IsDeleted`, `Suspend` filters** — vacation salaries and unposted salaries appear. (The desktop copy `ERP\HRManagement\PayRoll\Report\dsEmployeesSalariesDetails.xsd` *does* add `IsVacationSalary = 0` and has no NULL branch — the MVC copy differs.)
3. **Duplicate salary rows** when an employee has >1 `PR_EmployeeBank` row for the salary currency: DISTINCT keeps both (different Bank/AccountNo), the employee block prints twice, each with the full income list (relation by SalaryId), and the "Total Insurance Company" running sum **double-counts**. "Total Employees Insurance" is *not* doubled (incomeGroup query has no bank join). A TVF that joins bank per income line would multiply income rows the same way — must reproduce deliberately, or flag.
4. **Hard-coded IncomeId 10** for "Total Employees Insurance" (vs `PR_SystemConfiguration.EmployeeInsuranceIncomeId` used by report 4). Reproduce literally.
5. Incomes with `PR_Income.IncomeTypeId IS NULL` (or orphan type) are silently missing from the printed income lines and from the IncomeId-10 total.
6. **Ordering is undefined**: no ORDER BY on the DISTINCT, no sort fields; income lines ordered only by SalaryId (within a salary: physical order). Choose an explicit order (e.g. SalaryId, SalaryDetailId) and accept it as a layout change.
7. Display: money values printed raw (4 decimals) except the `{0:0.00}` grand total; Employee name is always the English `EmployeeName` even in Arabic; `TotalEmployeeInsurance` uses `decimal.ToString()` in the thread culture.
8. Per-user custom layouts may exist in tenant `ACFX_ReportLayout` (Name `rptEmployeesSalariesDetails`, Language `ar-EG`/`en-US`) — check before trusting the designer as "the" layout.
9. Dead input: the Posted checkbox on the form is never sent; the new screen should either drop it or wire it (deviation).

---

## Report 4 — Employees Salaries In Period

### a. Input contract

| Key | Type sent | Built from | Notes |
|---|---|---|---|
| `lang` | `ar-EG` / `en-US` | ReportSrcHandlerService | Decides FillEnglish vs FillArabic (month text) |
| `employeeIds` | CSV string of ints — **always sent** | form `EmployeeIdList` | Shell: if empty → `ReportFormRef.getAllEmployeeIds()` (CSV of every id in the shared employee list, `inServiceOnly=false`). Never null from this shell. Controller passes `null` to SQL only if empty/null. |
| `fromDate` | ISO string, required | form `FromDate` (dx-date-box `dd/MM/yyyy`, `max=ToDate`, default `new Date()` = now **with current time**) | |
| `toDate` | ISO string, required | form `ToDate` (`min=FromDate`, default now) | |

Shell: `containers\employees-salaries-in-peroid-shell\employees-salaries-in-peroid-shell.component.{ts,html}`, form flags `isShowSharedEmployeeList=true`, `isInPeriodDate=true`, `isShowPostedSalaryCheck=false`. `collectSalaryInPeriodReport` emits `{FromDate, ToDate, EmployeeIdList}` after `isFormDateValid()`.

Example: `…/mvc/AccountingReports/EmployeeSalariesInPeroid?lang=en-US&employeeIds=1,2,3&fromDate=2026-01-01T00:00:00.000Z&toDate=2026-06-30T00:00:00.000Z`

### b. Controller

```csharp
[Route("mvc/AccountingReports/EmployeeSalariesInPeroid")]
public IActionResult EmployeeSalariesInPeroid(string lang, string employeeIds, DateTime fromDate, DateTime toDate)
{
    ChangeThreadCulture(lang);
    var report = new Payroll.Reports.Accounting.Salary.rptEmployeeSalariesBetweenPeriod(employeeIds, fromDate, toDate);
    return View(REPORTS_ROOT_VIEW, report);
}
```
Report class `ERP\HRManagement\Payroll.Reports\Accounting\Salary\rptEmployeeSalariesBetweenPeriod.cs` (+ `.Designer.cs`), DataSet `…\Salary\dsEmployeesSalaryBetweenPeriod.xsd`. Ctor captures `UserSecurityLevel = MainConfigrationData.SecurityLevel` (static set by BaseController: 5 for admins, else the `securityLevel` claim). `Name` = `rptEmployeeSalariesBetweenPeriod` / `…Areg`.

### c. SQL and C#

**TableAdapter `Salary.FillEnglish(@employees, @fromDate, @toDate, @EmployeeSecurityLevel)`** (verbatim; `@employees nvarchar` nullable, `@fromDate datetime`, `@toDate datetime`, `@EmployeeSecurityLevel int`):
```sql
   SELECT   PR_Salaries.* ,
            EmployeeName ,
            EmployeeNumber ,
            DateOfWork ,
            BranchName ,
            DepartmentName ,
            ISNULL(( SELECT SUM(IncomeAmount)
                     FROM   dbo.PR_SalaryDetail
                     WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                            AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                            TaxIncomeId
                                                     FROM   dbo.PR_SystemConfiguration
                                                   )
                   ), 0) AS TaxAmount ,
            ISNULL(( SELECT SUM(IncomeAmount)
                     FROM   dbo.PR_SalaryDetail
                     WHERE  PR_SalaryDetail.SalaryId = dbo.PR_Salaries.SalaryId
                            AND EmployeeIncomeId = ( SELECT TOP ( 1 )
                                                            EmployeeInsuranceIncomeId
                                                     FROM   dbo.PR_SystemConfiguration
                                                   )
                   ), 0) AS InsuranceAmount ,
            CASE WHEN SalaryMonth = 1
                 THEN 'Jan ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 2
                 THEN 'Feb ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 3
                 THEN 'Mar ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 4
                 THEN 'Apr ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 5
                 THEN 'May ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 6
                 THEN 'Jun ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 7
                 THEN 'Jul ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 8
                 THEN 'Aug ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 9
                 THEN 'Sep ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 10
                 THEN 'Oct ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 11
                 THEN 'Nov ' + CAST(SalaryYear AS VARCHAR(4))
                 WHEN SalaryMonth = 12
                 THEN 'Dec ' + CAST(SalaryYear AS VARCHAR(4))
            END AS Mnth
   FROM     dbo.PR_Salaries
            INNER JOIN dbo.PR_SalaryMain ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
            INNER JOIN dbo.PR_Employee ON PR_Employee.EmployeeId = PR_Salaries.EmployeeId
            LEFT OUTER JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
            LEFT OUTER JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
            LEFT JOIN dbo.PR_Job ON PR_Job.JobId = PR_Employee.JobId
            LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
   WHERE    ( @employees IS NULL
              OR PR_Employee.EmployeeId IN (
              SELECT    *
              FROM      dbo.Acc_ConvertIntListToTable(@employees) )
            )
            AND PeriodFrom BETWEEN @fromDate AND @toDate
            AND PR_Employee.EmployeeSecurityLevel <= @EmployeeSecurityLevel
            AND Posted = 1
   ORDER BY PR_Employee.EmployeeId ,
            PeriodFrom;
```
**`FillArabic`** — identical except (a) the `Mnth` CASE yields Arabic month names: `N'يناير ' , N'فبراير ' , N'مارس ' , N'أبريل ' , N'مايو ' , N'يونيو ' , N'يوليو ' , N'أغسطس ' , N'سبتمبر ' , N'أكتوبر ' , N'نوفمبر ' , N'ديسمبر '` + `CAST(SalaryYear AS VARCHAR(4))`, and (b) the WHERE lists `AND Posted = 1` before the security-level predicate (no semantic difference). Same params.

**C# in `rptEmployeeSalariesBetweenPeriod_BeforePrint`:**
- Arabic → RTL.
- `lblDateFrom.Text = from.ToString("dd/MM/yyyy")`, `lblDateTo.Text = to.ToString("dd/MM/yyyy")` (page header).
- `string.IsNullOrEmpty(employeeIds) ? null : employeeIds`; `isArabic ? FillArabic : FillEnglish` with `UserSecurityLevel`.
No rollups or rounding in C#; all totals are designer summaries.

### d. Printed layout (designer `rptEmployeeSalariesBetweenPeriod.Designer.cs`, A4 portrait)

`DataMember = Salary`. Bands:
- ReportHeader (base company header); PageFooter (base).
- PageHeader: title "Employees Salaries In Peroid" / "مرتبات الموظفين خلال فترة"; "From" `lblDateFrom` — "To" `lblDateTo`.
- **GroupHeader1** — `GroupFields: EmployeeId ASC`, RepeatEveryPage: "Employee" `EmployeeName` · "Employee Number" `EmployeeNumber` · "Work Date" `DateOfWork {0:dd/MM/yyyy}`; then column headers.
- **DetailMain** (one row per salary, SQL order EmployeeId, PeriodFrom):

  | # | Header (en / ar) | Bound field | Format |
  |---|---|---|---|
  | 1 | Serial / المسلسل | summary `RecordNumber`, Running=Group (1..n per employee) | |
  | 2 | Month / الشهر | `Mnth` | |
  | 3 | **Main Salary / الاساسي** | **`InsuranceCompany`** (!) | `{0:n2}` |
  | 4 | Deductions / الاستقطاعات | `TotalDeductions` | `{0:n2}` |
  | 5 | Insurance / التأمينات | `InsuranceAmount` | `{0:n2}` |
  | 6 | Tax / الضرائب | `TaxAmount` | `{0:n2}` |
  | 7 | Total / الاجمالي | `Total` | `{0:n2}` |

- **GroupFooter1** (per employee): "Totals" / "الاجمالي" then Sum (Running=Group) of `InsuranceCompany` `{0:n2}`, `TotalDeductions`, `InsuranceAmount`, `TaxAmount`, `Total` — **only the first summary has a format string**; the other four print the raw money sum (4 dp).
- No report-level grand total.
- Fetched but not printed: all other `PR_Salaries.*` columns (incl. `BasicSalary`, `TotalAdditions`, `TotalTax`), `BranchName`, `DepartmentName`.

### e. Cloud DB dependencies (all under `DB\dbo\…`, present and registered)

| Object | Exists | Path | Notes |
|---|---|---|---|
| PR_Salaries | Y | Tables\PR_Salaries.sql | `PR_Salaries.*` in cloud also returns `SickLeaveAccrualNote`, `DepartmentId` (not in the typed DataSet; harmless) |
| PR_SalaryMain | Y | Tables\PR_SalaryMain.sql | `PeriodFrom datetime NOT NULL`; `IsVacationSalary`, `IsDeleted` **not filtered** by legacy |
| PR_Employee | Y | Tables\PR_Employee.sql | `EmployeeSecurityLevel int NOT NULL DEFAULT 1`, `DateOfWork datetime NOT NULL` |
| PR_Department / PR_Branch | Y | Tables\… | joined via employee's **current** dept/branch (not printed) |
| PR_Job / PR_Projects | Y | Tables\… | joined but no column used (LEFT JOIN 1:1 on PK → no row multiplication) |
| PR_SalaryDetail | Y | Tables\PR_SalaryDetail.sql | correlated sums |
| PR_SystemConfiguration | Y | Tables\PR_SystemConfiguration.sql | `TaxIncomeId int NULL`, `EmployeeInsuranceIncomeId int NULL`; `TOP(1)` without ORDER BY |
| dbo.Acc_ConvertIntListToTable | Y | Functions\Acc_ConvertIntListToTable.sql | column `number`; NULL → '0' |

Precedent `PR_EmployeeTotalSalariesReport` is single-month (`@Month/@Year`), pivots incomes, filters `IsVacationSalary = 0`, and does not filter `Posted` — **not reusable** for a date-range, posted-only, per-salary list. This report is a straightforward inline TVF over `PR_Salaries ⋈ PR_SalaryMain ⋈ PR_Employee` with the two correlated sums; follow the precedent's param conventions (`@SecurityLevel`, `@EmployeeIds` CSV via `Acc_ConvertIntListToTable`) and add `@FromDate`, `@ToDate`, plus `@IsArabic` (or return both month labels / `SalaryMonth`+`SalaryYear` and format in the layout).

### f. Route / permission
`accounting-reports.module.ts`: path `employees-salaries-in-peroid-report` → `EmployeesSalariesInPeroidShellComponent`, `canActivate: [CanActivateRouteGuard, AccflexAuthGuard]`, **no `data.ModuleId`**. With Angular's default `paramsInheritanceStrategy: 'emptyOnly'` and a componentless lazy parent, it inherits the parent's `ModuleId: 285` (Accounting Reports group) — so the guard checks 285, not the report's own module. `Acc_Module` **543** = "Employees Salaries In Peroid Report" / "تقرير مرتبات الموظفين خلال فتره" exists in `0002_Acc_Module_Data.sql` (line ~489) but is not wired to the route. Title i18n `ACCOUNTINGREPORTS._EmployeesSalariesBetweenDate_`.

### g. Risks for 1:1 reproduction
1. **"Main Salary" column shows `PR_Salaries.InsuranceCompany`**, not `BasicSalary` — a legacy binding bug. Same-numbers means reproducing it (or a documented, user-approved fix). Same for the group-footer first total.
2. **Date semantics**: filter is `PeriodFrom BETWEEN @fromDate AND @toDate` on the salary period start (not salary date, not month/year). Inputs arrive with time-of-day if the user never touches the date boxes (defaults = now) — `fromDate` with a time after 00:00 excludes a salary whose `PeriodFrom` is that day at midnight; `toDate` at 00:00 includes only salaries starting exactly at midnight of that day. The new screen must send the same wall-clock values (date-only at 00:00 when picked) to match.
3. **Filters present**: `Posted = 1`, `EmployeeSecurityLevel <= @SecurityLevel`. **Filters absent**: `IsVacationSalary`, `IsDeleted` — vacation salaries are listed. (Desktop copy `ERP\HRManagement\PayRoll\Accounting\Reports\EmployeesSalariesBetweenPeriods\dsEmployeesSalaryBetweenPeriod.xsd` differs: explicit column list, extra currency join and CurrencyNameArabic — the MVC copy is the reference.)
4. **Security level is a process-wide static** (`MainConfigrationData.SecurityLevel`) captured in the report ctor; concurrent requests from users with different levels can race. The OData version should take it from the token claim (admin → 5), matching intent.
5. `TaxAmount` / `InsuranceAmount` resolve the income id from `SELECT TOP(1) … FROM PR_SystemConfiguration` with no ORDER BY; if the config id is NULL the sum is 0. Reproduce with the same subquery.
6. Employee list: shell always sends an explicit CSV (all ids visible in the shared employee list when none selected) — the new screen should send the same list (or NULL meaning "all", which with the security filter is equivalent only if the employee list API returns exactly the employees with level ≤ user level — verify).
7. Display: 4 of 5 footer totals unformatted (raw 4-dp money); serial resets per employee; Mnth text is language-dependent (`'Jan 2026'` vs `N'يناير 2026'`); typed column `Mnth` has MaxLength 8 but constraints are off, so Arabic labels are not truncated.
8. Permission: route uses inherited ModuleId 285; module 543 exists. Decide which to put on the new route (543 matches the report; 285 matches current behaviour).
9. Per-user custom layouts may exist in `ACFX_ReportLayout` (Name `rptEmployeeSalariesBetweenPeriod`).

---

## Reuse summary
- Neither report can compose over `PR_EmployeeTotalSalariesReport` (different grain and filters: it is single-month, vacation-excluded, pivoted). Both should be new inline TVFs over the same base tables, using the precedent's parameter conventions (`@SecurityLevel`, `@EmployeeIds` CSV via `dbo.Acc_ConvertIntListToTable`, which is functionally identical to `iter$simple_intlist_to_tbl`).
- Report 3 → one fixed-column row per income line (employee header columns repeated); grand totals: Sum(InsuranceCompany) over distinct salary rows (with the bank-duplication caveat) and Sum(IncomeAmount WHERE IncomeId = 10).
- Report 4 → one row per posted salary; group by EmployeeId in the layout; per-employee sums in the layout or SQL window functions.
- Every dependency exists on `origin/Master_Stable` in the cloud DB and is registered in the `.sqlproj`; no missing objects.
