# CR 125292 – Legacy inventory C: Salaries By Income Group (#5) and Departments Monthly Salaries (#6)

All sources read from `origin/Master_Stable` (AccFlex_ERP, AccFlex_Cloud_Front, AccFlex_Cloud_Database, AccFlex_Cloud_ERP). Nothing was checked out or modified.

Shared plumbing (both reports):

- **Iframe URL**: `ReportSrcHandlerService.getIframeSrc(path, query)` (`accflex-erp/src/app/shared/services/report-src-handler/report-src-handler.service.ts`) builds `${printRedirectUrl}${path}?lang=${lang}&${query}`, adding `&access_token=…` when not production. `lang` is `ar-EG` (the default, also when null) or `en-US`.
- **Serialization**: `QuerySerializeService.serialize` (`accflex-erp/src/app/shared/services/query-serialize/query-serialize.service.ts`): `Date` values are sent as `addHoursUTCDifferent(date).toISOString()`, meaning local wall-clock time with a `Z` suffix (e.g. `2026-10-14T10:23:45.123Z`). Everything else goes through `encodeURIComponent(value)`, so a JS array `[1,2,3]` becomes `1,2,3` (CSV) and `[]` becomes the empty string.
- **Transport**: `accflex-report-iframe-post` (`accflex-erp/src/app/shared/components/report-iframe-post/`) does not load the URL in the iframe. It deserializes the query and **POSTs a hidden-field form** (`method="POST" target="reportFrame"`) to `/mvc/<path>`. ASP.NET Core binds the action params from the form fields; an empty string binds to `null` for `string` params.
- **MVC base**: `AccFlexContainer/AccFlexContainer.MVC/Controllers/BaseController.cs`.
  - Sets `Payroll.Reports.MainConfigrationData.SecurityLevel` = 5 when the `isAdmin` claim is true, else the `securityLevel` claim.
  - `ConnectionString` = the **tenant connection string**. The MVC report reads the same tenant DB the cloud uses.
  - `ChangeThreadCulture(lang)`: `en-US` gives en-US, anything else gives `ar-EG`. `MainConfigrationData.IsArabic` is `CurrentUICulture.Name == "ar-EG"` (`HRManagement/Payroll.Reports/MainConfigrationData.cs`).
- **Layout**: `Views/Report/ReportView.cshtml` calls `ReportLayoutDatabaseStore.GetReportLayoutByNameAndLanguage(Model.GetType().Name, culture)` (`Services/ReportLayoutDatabaseStore.cs`).
  - It runs `SELECT … FROM dbo.ACFX_ReportLayout WHERE Name=@Name AND UserId=@UserId AND Language=@Language`, so the lookup is **per user** and keyed on the **class name** (`rptSalaryByIncomeGroup` / `rptDepartmentSalary`), not on `this.Name`.
  - If no row exists, the compiled designer layout (`rpt*.Designer.cs`) is used. No `.repx` for either report exists on disk (none under `D:\Hadaf\ReportLayout`) or in Cloud DB reference-data scripts.
  - **Note**: the legacy MVC store is the same `dbo.ACFX_ReportLayout` table. This contradicts the field-guide claim that it is a different table/system.
- **Base report** `rptMainReport` (`HRManagement/Payroll.Reports/rptMainReport.cs`): its BeforePrint fills `PR_SystemConfiguration` for the company header: logo, CompanyName, Email, Fax, Telephone, Address, `PC:<machine>`, `User:<name>`.

---

## Report 5 — Salaries By Income Group (`mvc/AccountingReports/SalaryByIncome`)

### a. Input contract

Front files (`accflex-erp/projects/payroll/src/app/modules/accounting-reports/`):

- Shell: `containers/employee-salary-by-income-shell/employee-salary-by-income-shell.component.ts|html`
- Form: `components/income-group-report-form/income-group-report-form.component.ts|html` (selector `pay-income-group-report-form`)

The form emits `{ Month, EmployeeIdList, IncomeGroupId }`. The shell maps these to the keys below:

| Query key | Source control | Type sent | Notes |
|---|---|---|---|
| `lang` | global language | `ar-EG` / `en-US` | added by ReportSrcHandlerService |
| `employeeIds` | `pay-shared-employee-list` (multiple selection, `inServiceOnly` not set, so the component default `false` applies) | CSV string of ints | See the employee-list notes below this table. |
| `month` | `dx-date-box` (`displayFormat="MM/yyyy"`, `maxZoomLevel: 'year'`), default `new Date()` | ISO string (local time + `Z`) | required; only `.Month` / `.Year` are used |
| `incomeId` | `dx-lookup` over `GET {apiUrl}/IncomeGroup`, `valueExpr="IncomeGroupId"`, `displayExpr="IncomeGroupName"` | int | required (`isFormValid` returns false without Month and IncomeGroupId). Cloud EF maps `IncomeGroup.Id` → `PR_IncomeGroup.IncomeTypeId` and `IncomeGroupName` → `IncomeType` (`AccFlex_Cloud_ERP/Payroll/Payroll.Data/EFConfigurations/IncomeGroupConfigurations.cs`) |

Notes on `employeeIds`:

- When nothing is selected, `getAllEmployeeIds()` sends every employee in the list, as `Employee.map(i => i.EmployeeId).toString()`.
- When rows are selected, it sends the `selectedRowKeys` array, which serializes to CSV.
- So `employeeIds` is effectively **always a non-empty CSV**. It is empty, and binds to null meaning "all", only if the employee list itself is empty.
- The list comes from `GET api/Payroll/Employee/false/WorkingDate/{today}`. That endpoint calls `EmployeeRepo.GetAllEmployees(false, today)`, which applies `IgnoreQueryFilters()` and `HiringDate <= today`, and **does not filter by security level**.

### b. Controller action

`AccFlexContainer/AccFlexContainer.MVC/Controllers/PayrollReports/AccountingReportsController.cs`:

```csharp
[Route("mvc/AccountingReports/SalaryByIncome")]
public IActionResult SalaryByIncome(string lang, string employeeIds, int incomeId, DateTime month)
{
    ChangeThreadCulture(lang);
    var report = new Payroll.Reports.Accounting.Salary.rptSalaryByIncomeGroup(employeeIds, incomeId, month.Year, month.Month);
    return View(REPORTS_ROOT_VIEW, report);
}
```

The constructor is `rptSalaryByIncomeGroup(string _employeeIds, int _incomeType, int _year, int _month)`, and the argument order matches. `incomeId` is a non-nullable int: if it is missing it becomes 0, which returns no rows.

### c. SQL and C# logic

Code-behind: `HRManagement/Payroll.Reports/Accounting/Salary/rptSalaryByIncomeGroup.cs`. `rptSalaryByIncomeGroup_BeforePrint` does the following:

- Sets RTL when Arabic.
- Sets `lblYear.Text = year.ToString()` and `lblMonth.Text = month.ToString()`. The month prints as a number, not a name.
- Calls `incomeGroupTableAdapter.FillByEmployeeIdIncomeTypeMonthYear(dsIncomeGroupDetails1.IncomeGroup, incomeType, employeeIds, month, year)`.
- Has **no C# computations, no filters and no rollups**.
- In the constructor: `Name = isArabic ? "rptSalaryByIncomeGroupAreg" : "rptSalaryByIncomeGroup"`, plus `localizer1.ApplyArabic()`.

Typed DataSet: `HRManagement/Payroll.Reports/Accounting/Salary/dsIncomeGroupDetails.xsd`, compiled as `dsIncomeGroupDetails.Designer.cs`. The compiled CommandText was checked identical to the xsd.

- One TableAdapter `IncomeGroupTableAdapter`, one query `FillByEmployeeIdIncomeTypeMonthYear`.
- Parameters:
  - `@typeId` int
  - `@employeeIds` NVarChar(0). A C# null becomes DBNull; an empty string is passed as `''`.
  - `@month` int?
  - `@year` int?

Verbatim SQL:

```sql
SELECT  PR_SalaryDetail.IncomeAmount ,
        PR_SalaryDetail.Suspend ,
        PR_Employee.EmployeeId ,
        PR_Employee.EmployeeName ,
        PR_Employee.EmployeeNumber ,
        PR_Projects.ProjectName ,
        PR_Branch.BranchName ,
        PR_Department.DepartmentName ,
        PR_IncomeGroup.IncomeTypeId ,
        PR_Income.IncomeName ,
        PR_IncomeGroup.IncomeType ,
        PR_Income.Deduction ,
        PR_SalaryMain.SalaryMonth ,
        PR_SalaryMain.SalaryYear
FROM    PR_SalaryDetail
        INNER JOIN PR_Income ON PR_SalaryDetail.EmployeeIncomeId = PR_Income.IncomeId
        INNER JOIN PR_IncomeGroup ON PR_Income.IncomeTypeId = PR_IncomeGroup.IncomeTypeId
        INNER JOIN PR_Salaries ON PR_SalaryDetail.SalaryId = PR_Salaries.SalaryId
        INNER JOIN PR_Employee ON PR_Salaries.EmployeeId = PR_Employee.EmployeeId
        INNER JOIN PR_SalaryMain ON PR_Salaries.SalaryMainId = PR_SalaryMain.SalaryMainId
        LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
        LEFT JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
        LEFT JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
WHERE   ( PR_IncomeGroup.IncomeTypeId = @typeId )
        AND ( @employeeIds IS NULL
              OR PR_Employee.EmployeeId IN (
              SELECT    *
              FROM      dbo.iter$simple_intlist_to_tbl(@employeeIds) )
            )
        AND PR_SalaryMain.SalaryMonth = @month
        AND PR_SalaryMain.SalaryYear = @year
        AND PR_Salaries.Posted = 1;
```

Semantics to reproduce:

- **One row per `PR_SalaryDetail` line**: no aggregation.
- **Filters**:
  - posted salaries only (`PR_Salaries.Posted = 1`)
  - the income group, through `PR_Income.IncomeTypeId`
  - month and year from `PR_SalaryMain`
  - the employee CSV, parsed by `dbo.iter$simple_intlist_to_tbl`
- **No filter** on any of these:
  - `PR_SalaryMain.IsDeleted`
  - `PR_SalaryMain.IsVacationSalary` (prepaid-vacation salary runs are included)
  - `PR_SalaryDetail.Suspend` (suspended lines are included)
  - security level
- `Deduction` comes from `PR_Income`, not `PR_SalaryDetail`.
- `IncomeAmount` is the raw `MONEY` value from `PR_SalaryDetail`.
- If `@employeeIds = ''` (not null): `iter$simple_intlist_to_tbl('')` inserts `convert(int,'')`, which is 0, so no rows come back. The MVC binder turns `''` into null, so in practice null means all employees.

### d. Printed output

Layout: designer `rptSalaryByIncomeGroup.Designer.cs`, DX version 19.1, A4 portrait, TenthsOfAMillimeter, margins 50. Alternatively a per-user `ACFX_ReportLayout` row named `rptSalaryByIncomeGroup` for the language.

- **ReportHeader** (inherited): company header.
- **PageHeader**:
  - title `lblName` "Employees Salaries By Income Group" / "تقرير المرتبات بفئة الدخل"
  - "Month" + `lblMonth` (the month number)
  - "Year" + `lblYear`
- **GroupHeader2** has **no `GroupFields`**, so DevExpress prints it **once, before the first detail row**, bound to the first row. It contains:
  - "Employee" → `EmployeeName`
  - "Employee No" → `EmployeeNumber`
  - "Branch" → `BranchName`
  - "Department" → `DepartmentName`
  - the column-header table (silver): **Income Type | Income Name | Amount | Deducation** (Arabic: الفئة | الدخل | القيمة | استقطاع)
- **DetailMain**, one per row:
  - `IncomeType` (group name)
  - `IncomeName`
  - `IncomeAmount` (no FormatString, so the raw decimal is printed)
  - `xrCheckBox1.CheckState ← Deduction`
- **No totals, no summaries, no sort fields.** Row order is the SQL order, which is unspecified.
- Selected but not printed: `Suspend`, `EmployeeId`, `ProjectName`, `IncomeTypeId`, `SalaryMonth`, `SalaryYear`.

### e. Cloud DB dependencies

Paths are under `AccFlex_Cloud_Database_State/AccFlex_Cloud_Database_State/`, and every object below is registered in the sqlproj.

| Object | Exists | Path | Notes |
|---|---|---|---|
| `PR_SalaryDetail` | Y | `dbo/Tables/PR_SalaryDetail.sql` | `IncomeAmount MONEY`, `Suspend BIT`, `EmployeeIncomeId`, `SalaryId` present |
| `PR_Income` | Y | `dbo/Tables/PR_Income.sql` | `IncomeName nvarchar(200)`, `IncomeTypeId`, `Deduction BIT` present |
| `PR_IncomeGroup` | Y | `dbo/Tables/PR_IncomeGroup.sql` | `IncomeTypeId` identity, `IncomeType nvarchar(50)` |
| `PR_Salaries` | Y | `dbo/Tables/PR_Salaries.sql` | `Posted BIT`, `EmployeeId`, `SalaryMainId` present; also has `DepartmentId` (salary-time snapshot), which the legacy query ignores |
| `PR_SalaryMain` | Y | `dbo/Tables/PR_SalaryMain.sql` | `SalaryMonth` / `SalaryYear` present; also `IsDeleted` and `IsVacationSalary`, which the legacy query does not filter |
| `PR_Employee` | Y | `dbo/Tables/PR_Employee.sql` | `EmployeeName nvarchar(1000)`, `EmployeeNumber nvarchar(100)`, `DefaultProjectId`, `BranchId` / `DepartmentId` (NOT NULL) present |
| `PR_Projects` | Y | `dbo/Tables/PR_Projects.sql` | `ProjectName nvarchar(500)` |
| `PR_Branch` | Y | `dbo/Tables/PR_Branch.sql` | `BranchName nvarchar(1000)` |
| `PR_Department` | Y | `dbo/Tables/PR_Department.sql` | `DepartmentName nvarchar(50)` |
| `dbo.iter$simple_intlist_to_tbl` | Y | `dbo/Functions/iter_simple_intlist_to_tbl.sql` (file name uses `_`, the object is `iter$…`) | multi-statement TVF returning `number int`; NULL input becomes `'0'` |

### f. Route / permission

- Route `accounting-reports/salary-by-income-report` in `accounting-reports.module.ts` (lines ~86-90). It has **no `data.ModuleId`**; guards are `[CanActivateRouteGuard, AccflexAuthGuard]`.
- The menu uses ModuleId **539**:
  - `AccFlex_Cloud_ERP/Payroll/Payroll.Service/MenuList/WebMenuItem.cs:114`: `Salaries_By_Income_Group = new WebMenuItem("8_3_2", Module.SalariesByIncomeGroupReport, …, "accounting-reports/salary-by-income-report")`
  - `Shared/SharedKernel.Logic/Modules/Module.cs:488`: `SalariesByIncomeGroupReport = new Module(539, …, 4, 41)`
- The payroll `CanActivateRouteGuard` (`projects/payroll/src/app/core/interceptors/can-activate/can-activate-route.guard.ts`) looks up `route.data.ModuleId` in the user's permissions. With the id undefined, **non-admin users are always denied**: an existing bug.
- The new route should carry `data: { ModuleId: 539 }`.

### g. Ambiguities and risks

1. **Header shows only the first employee.** `GroupHeader2` has no group fields, so with several employees the printed employee name, number, branch and department belong only to the first row. All income lines of all employees then follow with no per-employee separation and no totals.
   - A 1:1 data reproduction is easy because there are no computations.
   - A 1:1 visual reproduction would reproduce a bug. Grouping by employee in the new layout is a deliberate improvement; decide and record it.
2. **Employee scope comes from the front.** The SQL has no security-level filter, so security is whatever the employee list returns, and that endpoint uses `IgnoreQueryFilters` with no security filter.
   - A TVF taking `@EmployeeIds` reproduces this.
   - Adding `@SecurityLevel` (as the precedent does) would change results for restricted users.
3. **Inclusions the new TVF must keep:**
   - suspended detail lines
   - prepaid-vacation runs
   - soft-deleted salary runs (`IsDeleted` is not checked)
4. **No ORDER BY.** For a deterministic diff, sort both sides, e.g. by EmployeeId, IncomeId, SalaryDetailId. `SalaryDetailId` is not selected; add it as a key column in the TVF.
5. **Amount formatting.** `IncomeAmount` has no format string, so the legacy print shows MONEY's default decimal text, e.g. `1500.0000`. Choose `n2` in the new layout knowingly.
6. **Month labels.** The month is printed as a number. `month` is bound from an ISO `Z` string; a server time zone other than UTC can shift a date that is the 1st at 00:00 into the previous month (negligible with the default `new Date()`).

---

## Report 6 — Departments Monthly Salaries (`mvc/AccountingReports/DepartmentSalary`)

**Months are NOT columns.** This is a single-month, per-employee list grouped by Branch → Department, with a fixed column set. There is no pivot in SQL, C# or the designer.

### a. Input contract

- Shell: `containers/department-salary-shell/department-salary-shell.component.ts|html`
- Form: the shared `components/salary-report-form/salary-report-form.component.ts|html` (`pay-salary-report-form`) with:
  - `isShowBranch=true`
  - `isShowDepartment=true`
  - `isShowIncome=false`
  - `isShowSharedEmployeeList=false`
  - `isShowPostedSalaryCheck=false`
  - `isInPeriodDate=false`
- `collectReportData` therefore takes the `collectNoSalaryReport` path and emits `{ Month, BranchIdList, DepartmentIdList }`.

| Query key | Source control | Type sent | Notes |
|---|---|---|---|
| `lang` | global | `ar-EG` / `en-US` | |
| `branchIds` | `dx-drop-down-box` + multi-select grid over `GET {apiUrl}/Branch` (`BranchId`) | CSV or empty | Label shows `*`, but the guard `isShowBranch && !this.BranchIdList` never fires (`[]` is truthy), so an empty selection is sent as `''` |
| `departmentIds` | same pattern over `GET {apiUrl}/Department` (`DepartmentId`) | CSV or empty | optional |
| `month` | `dx-date-box` `MM/yyyy`, default `new Date()` | ISO string (local time + `Z`) | required (`isFormValid` checks `Month`) |

### b. Controller action

```csharp
[Route("mvc/AccountingReports/DepartmentSalary")]
public IActionResult DepartmentSalary(string lang, string branchIds, string departmentIds, DateTime month)
{
    ChangeThreadCulture(lang);
    var report = new Payroll.Reports.Accounting.Salary.rptDepartmentSalary(departmentIds, branchIds, month.Month, month.Year);
    return View(REPORTS_ROOT_VIEW, report);
}
```

The constructor `rptDepartmentSalary(string _depratmentId, string _branchId, int _month, int _year)` normalizes `null` or empty to `string.Empty` for both lists. `UserSecurityLevel = MainConfigrationData.SecurityLevel`, which is 5 for admins.

### c. SQL and C# logic

Code-behind: `HRManagement/Payroll.Reports/Accounting/Salary/rptDepartmentSalary.cs`. `rptDepartmentSalary_BeforePrint` does the following:

```csharp
monthSalaryTableAdapter.ClearBeforeFill = true;
monthSalaryTableAdapter.FillBy(dsDepartmentSalary1.MonthSalary, month, year, departmentId, branchId, UserSecurityLevel);
if (dsDepartmentSalary1.MonthSalary.Count <= 0) return;
string culture = !isArabic ? "en" : "ar-EG";
lblDate.Text = $"{CultureInfo.CreateSpecificCulture(culture).DateTimeFormat.GetMonthName(dsDepartmentSalary1.MonthSalary[0].SalaryMonth)} / {dsDepartmentSalary1.MonthSalary[0].SalaryYear}";
```

- There are no rollups in C#. The only C# computation is the header month-name label, taken from the first row.
- In the constructor: `Name = isArabic ? "rptDepartmentSalaryAreg" : "rptDepartmentSalary"`, and `ReportTitle` = "Department Salary Report" / "تقرير المرتبات الشهرية للادارات".

Typed DataSet: `HRManagement/Payroll.Reports/Accounting/Salary/dsDepartmentSalary.xsd`. The compiled code is `dsDepartmentSalary1.Designer.cs` (the csproj `LastGenOutput`). The FillBy CommandText was verified identical to the xsd after normalizing whitespace and escapes.

- TableAdapter `MonthSalaryTableAdapter` has three queries:
  - `Fill`: parameterless, all salaries ever. **Unused** here.
  - `FillPosted`: by `@EmployeeIdList` / `@IsPosted`, also selects `IDNumber`. **Unused** here.
  - `FillBy`: **the one used**.
- FillBy parameters:
  - `@SalaryMonth` `SqlDbType.Decimal`
  - `@SalaryYear` `SqlDbType.Decimal`
  - `@DepartmentId` VarChar(1024)
  - `@BranchId` VarChar(1024)
  - `@UserSecurityLevel` Int
- Generated FillBy throws `ArgumentNullException` on null lists; the constructor prevents that.

Verbatim FillBy SQL:

```sql
WITH PrepaidVacationDetails
AS (SELECT PR_SalaryDetail.SalaryId,
           SUM(   CASE
                      WHEN PR_SalaryDetail.EmployeeIncomeId <> 9994
                           AND PR_SalaryDetail.Deduction = 0 THEN
                          PR_SalaryDetail.UserAmount
                      ELSE
                          0
                  END
              ) AS TotalIncome,
           SUM(   CASE
                      WHEN PR_SalaryDetail.Deduction = 1 THEN
                          PR_SalaryDetail.UserAmount
                      ELSE
                          0
                  END
              ) AS TotalDeductions
    FROM PR_SalaryDetail
    GROUP BY PR_SalaryDetail.SalaryId),
     EndWorkDetailsCTE
AS (SELECT PR_EmployeeEndWork.EmployeeEndWorkId,
           PR_EmployeeEndWorkDetail.EmployeeEndWorkDetailId,
           PR_EmployeeEndWorkDetail.TotalPostedNotPaidSalary,
           PR_EmployeeEndWorkDetail.TotalSalary AS SalaryFromEndWork,
           PR_EmployeeEndWorkDetail.TotalBouns,
           PR_EmployeeEndWorkDetail.TotalPenalty,
           PR_EmployeeEndWorkDetail.TotalAdvance,
           PR_EmployeeEndWorkDetail.TotalPurchase,
           PR_EmployeeEndWork.EmployeeId,
           PR_EmployeeEndWork.LastWorkingDay,
           PR_EmployeeEndWorkDetail.CurrencyId
    FROM PR_EmployeeEndWorkDetail
        INNER JOIN PR_EmployeeEndWork
            ON PR_EmployeeEndWork.EmployeeEndWorkId = PR_EmployeeEndWorkDetail.EmployeeEndWorkId
    WHERE PR_EmployeeEndWorkDetail.TotalSalary >= 0),
     PrepaidVacationsCTE
AS (SELECT SalaryMainId,
           IsVacationSalary,
           SalaryMonth
    FROM PR_SalaryMain
    WHERE IsVacationSalary = 1)
SELECT DISTINCT
       PR_Employee.EmployeeId,
       PR_Employee.EmployeeNumber,
       PR_Employee.EmployeeName,
       PR_Job.JobName,
       PR_Salaries.InsuranceCompany,
       PR_Department.DepartmentName,
       PR_Department.DepartmentId,
       PR_Branch_1.BranchName,
       PR_Branch_1.BranchId,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               COALESCE(
               (
                   SELECT TotalIncome - TotalDeductions
                   FROM PrepaidVacationDetails
                   WHERE PrepaidVacationDetails.SalaryId = PR_Salaries.SalaryId
               ),
               0
                       )
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(EndWorkDetailsCTE.SalaryFromEndWork, 0)
           ELSE
               PR_Salaries.TotalAdditions - PR_Salaries.TotalDeductions
       END AS TotalSalary,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               COALESCE(
               (
                   SELECT TotalDeductions
                   FROM PrepaidVacationDetails
                   WHERE PrepaidVacationDetails.SalaryId = PR_Salaries.SalaryId
               ),
               0
                       )
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(
                           EndWorkDetailsCTE.TotalAdvance + EndWorkDetailsCTE.TotalPenalty
                           + EndWorkDetailsCTE.TotalPurchase,
                           0
                       )
           ELSE
               PR_Salaries.TotalDeductions
       END AS TotalDeductions,
       Acc_Currency.CurrencyName,
       Acc_Currency.CurrencyNameArabic,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               COALESCE(
               (
                   SELECT SUM(   CASE
                                     WHEN PR_SalaryDetail.EmployeeIncomeId <> 9994
                                          AND PR_SalaryDetail.Deduction = 0 THEN
                                         PR_SalaryDetail.IncomeAmount
                                     ELSE
                                         0
                                 END
                             )
                   FROM PR_SalaryDetail
                   WHERE PR_SalaryDetail.SalaryId = PR_Salaries.SalaryId
               ),
               0
                       )
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(
                           EndWorkDetailsCTE.SalaryFromEndWork + EndWorkDetailsCTE.TotalAdvance
                           + EndWorkDetailsCTE.TotalPenalty + EndWorkDetailsCTE.TotalPurchase,
                           0
                       )
           ELSE
               PR_Salaries.TotalAdditions
       END AS TotalAdditions,
       CASE
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(MONTH(EndWorkDetailsCTE.LastWorkingDay), 0)
           ELSE
               PR_SalaryMain.SalaryMonth
       END AS SalaryMonth,
       CASE
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               COALESCE(YEAR(EndWorkDetailsCTE.LastWorkingDay), 0)
           ELSE
               PR_SalaryMain.SalaryYear
       END AS SalaryYear,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               N'إجازة مدفوعة مقدماً'
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               N'اخلاء طرف'
           ELSE
               N'راتب شهري'
       END AS SalarySource,
       CASE
           WHEN PrepaidVacationsCTE.IsVacationSalary = 1 THEN
               'Prepaid Vacation'
           WHEN EndWorkDetailsCTE.EmployeeId IS NOT NULL THEN
               'End of Work'
           ELSE
               'Monthly Salary'
       END AS SalarySourceEng
FROM PR_Salaries
    INNER JOIN PR_SalaryMain
        ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId
    LEFT OUTER JOIN PR_Employee
        ON PR_Employee.EmployeeId = PR_Salaries.EmployeeId
    LEFT OUTER JOIN PR_Job
        ON PR_Job.JobId = PR_Employee.JobId
    LEFT OUTER JOIN PR_Department
        ON PR_Department.DepartmentId = PR_Employee.DepartmentId
    LEFT OUTER JOIN PR_Branch AS PR_Branch_1
        ON PR_Branch_1.BranchId = PR_Employee.BranchId
    LEFT OUTER JOIN Acc_Currency
        ON Acc_Currency.CurrencyId = PR_Salaries.CurrencyId
    LEFT OUTER JOIN PrepaidVacationsCTE
        ON PrepaidVacationsCTE.SalaryMainId = PR_Salaries.SalaryMainId
    LEFT OUTER JOIN EndWorkDetailsCTE
        ON EndWorkDetailsCTE.EmployeeId = PR_Employee.EmployeeId
        AND MONTH(EndWorkDetailsCTE.LastWorkingDay) = @SalaryMonth
              AND YEAR(EndWorkDetailsCTE.LastWorkingDay) = @SalaryYear
WHERE (
          (
              EndWorkDetailsCTE.EmployeeId IS NOT NULL
          )
          OR
          (
              EndWorkDetailsCTE.EmployeeId IS NULL
              AND PR_SalaryMain.SalaryMonth = @SalaryMonth
              AND PR_SalaryMain.SalaryYear = @SalaryYear
          )
      )
      AND
      (
          (
              @DepartmentId = ''
              AND PR_Department.DepartmentId IN
                  (
                      SELECT DepartmentId FROM PR_Department
                  )
          )
          OR
          (
              @DepartmentId <> ''
              AND PR_Department.DepartmentId IN
                  (
                      SELECT number FROM dbo.Acc_ConvertStringListToTable(@DepartmentId)
                  )
          )
      )
      AND
      (
          (
              @BranchId = ''
              AND PR_Branch_1.BranchId IN
                  (
                      SELECT BranchId FROM PR_Branch
                  )
          )
          OR
          (
              @BranchId <> ''
              AND PR_Branch_1.BranchId IN
                  (
                      SELECT number FROM dbo.Acc_ConvertStringListToTable(@BranchId)
                  )
          )
      )
      AND PR_Employee.EmployeeSecurityLevel <= @UserSecurityLevel
```

Semantics to reproduce. These are subtle; read them together with the SQL.

- **Row source**: every `PR_Salaries` row (INNER JOIN `PR_SalaryMain`), LEFT-joined to:
  - employee, job, department, branch
  - `Acc_Currency`, using `PR_Salaries.CurrencyId`
  - `PrepaidVacationsCTE`: the salary run has `IsVacationSalary = 1`
  - `EndWorkDetailsCTE`: same employee, with `MONTH`/`YEAR(LastWorkingDay)` equal to the parameters and `PR_EmployeeEndWorkDetail.TotalSalary >= 0`
- **WHERE**: (end-work matched) OR (no end-work match AND the run's `SalaryMonth`/`SalaryYear` equal the parameters).
  - Consequence: for an employee whose end-work falls in the selected month, **every** `PR_Salaries` row of that employee, from any month or year, qualifies.
  - Those rows take end-work values (see the CASEs below), so DISTINCT collapses them unless `InsuranceCompany` or currency differ across those historical rows.
- **CASE precedence** (prepaid vacation > end-work > normal) for each output column:

  | Column | Prepaid-vacation run | End-work matched | Normal |
  |---|---|---|---|
  | `TotalAdditions` ("Total Accruals") | `SUM(PR_SalaryDetail.IncomeAmount)` where `EmployeeIncomeId <> 9994 AND PR_SalaryDetail.Deduction = 0` | `SalaryFromEndWork + TotalAdvance + TotalPenalty + TotalPurchase` | `PR_Salaries.TotalAdditions` |
  | `TotalDeductions` | `SUM(UserAmount)` where `PR_SalaryDetail.Deduction = 1` | `TotalAdvance + TotalPenalty + TotalPurchase` | `PR_Salaries.TotalDeductions` |
  | `TotalSalary` ("Net Salary") | `SUM(UserAmount, non-deduction, ≠9994) − SUM(UserAmount, deduction)` | `SalaryFromEndWork` (= `PR_EmployeeEndWorkDetail.TotalSalary`) | `PR_Salaries.TotalAdditions − PR_Salaries.TotalDeductions` (**not** `PR_Salaries.Total`) |
  | `SalaryMonth` / `SalaryYear` | run's | `MONTH`/`YEAR(LastWorkingDay)` | run's |
  | `SalarySource` (Arabic) / `SalarySourceEng` | إجازة مدفوعة مقدماً / Prepaid Vacation | اخلاء طرف / End of Work | راتب شهري / Monthly Salary |

  All three amount columns are wrapped in `COALESCE(...,0)` in the prepaid-vacation and end-work branches.
- **Mixed amount sources in the prepaid-vacation branch**: Additions use `IncomeAmount`, while Deductions and Net use `UserAmount`. The `Deduction` flag here is the line-level `PR_SalaryDetail.Deduction`, not `PR_Income.Deduction`.
- `InsuranceCompany` ("Expected Sal.") always comes from `PR_Salaries`, even on end-work rows. The currency always comes from `PR_Salaries.CurrencyId`; the end-work detail's own `CurrencyId` is ignored.
- **`SELECT DISTINCT`** applies over all 18 output columns (FillBy does not select `IDNumber`).
- **Filters**:
  - `@DepartmentId = ''` → `PR_Department.DepartmentId IN (SELECT DepartmentId FROM PR_Department)`, which in effect makes the LEFT joins to employee and department inner. Otherwise it uses the CSV through `dbo.Acc_ConvertStringListToTable` (nvarchar `number`, implicitly converted to int).
  - The branch filter works the same way.
  - Security: `PR_Employee.EmployeeSecurityLevel <= @UserSecurityLevel`.
  - The department and branch are the employee's **current** `PR_Employee.DepartmentId`/`BranchId`, not the salary-time `PR_Salaries.DepartmentId` or `PR_SalaryMain.BranchId`.
- **Not filtered**:
  - `PR_Salaries.Posted` (unposted or draft salaries are included)
  - `PR_SalaryMain.IsDeleted`
  - `PR_EmployeeEndWork.Approved` (unapproved end-work is included)
  - `PR_Employee.EndWork`
- Several `PR_EmployeeEndWorkDetail` rows (e.g. one per currency), or several end-works in the month, multiply the rows.
- An end-work employee who has no `PR_Salaries` row at all does not appear.

### d. Printed output

Layout: designer `rptDepartmentSalary.Designer.cs`, DX version 20.2, A4 portrait, margins 50. Alternatively a per-user `ACFX_ReportLayout` row named `rptDepartmentSalary`.

- **ReportHeader** (inherited): company header.
- **PageHeader**:
  - `lblReportTitle` "Departments Monthly Salaries " / "تقرير المرتبات الشهريه للادارات"
  - "For Month" / "لشهر"
  - `lblDate`: the month name in the `en` or `ar-EG` culture, then ` / ` and the year, from the first row. It stays blank when there are no rows.
- **GroupHeader2**: `GroupFields` = `BranchId` ASC, `DepartmentId` ASC, with `RepeatEveryPage = true`. It shows:
  - "Branch" (الفرع) → `BranchName`
  - "Department" (الاداره) → `DepartmentName`
  - the column-header row (light gray), in order:
    1. Code (الرقم الوظيفي)
    2. Employee (الموظف)
    3. Job (الوظيفة)
    4. Currency (العملة)
    5. Expected Sal. (المرتب المتوقع)
    6. Total Accruals (اجمالي المستحقات)
    7. Total Deductions (اجمالي الاستقطاعات)
    8. Net Salary (صافي المرتب)
    9. Salary Source (مصدر الراتب)
- **DetailMain** (`xrTable7`) cells, in order:
  1. `EmployeeNumber`
  2. `EmployeeName`
  3. `JobName`
  4. **`CurrencyNameArabic`**, used in both languages
  5. `InsuranceCompany`, formatted `{0:n2}`
  6. `TotalAdditions`, formatted `{0:0.00}`
  7. `TotalDeductions`, formatted `{0:0.00}`
  8. `TotalSalary`: cell Text is `"[TotalSalary]"` with no binding or format, i.e. mail-merge with the default decimal text
  9. **`SalarySource`**, the Arabic text, used in both languages
- **No sort fields** inside a group. Rows follow the DISTINCT output order, which is unspecified.
- **GroupFooter3** (level 0) is empty: a spacer only, with **no per-department or per-branch subtotals**.
- **GroupFooter4** (`Level = 1`; there is no level-1 header, so it prints once at the report end), "Grand Total" / "الاجمالي" row:
  - Σ`InsuranceCompany` `{0:n2}`
  - Σ`TotalAdditions` `{0:0.00}`
  - Σ`TotalDeductions` `{0:0.00}`
  - Σ`TotalSalary` `{0:0.00}`
  - All use `Running = Report` and **sum across currencies**.
  - Footer cell widths do not align with the detail columns.
- The unused `Detail` band field (height 60) is not in `Bands`.

**Columns vs. OData**: the column set is fixed and there are no month columns. An OData entity can mirror the 18 FillBy columns directly.

### e. Cloud DB dependencies

Same root path as report 5; every object below is registered in the sqlproj.

| Object | Exists | Path | Notes |
|---|---|---|---|
| `PR_Salaries` | Y | `dbo/Tables/PR_Salaries.sql` | `InsuranceCompany`, `TotalAdditions`, `TotalDeductions`, `Total`, `CurrencyId`, `Posted` (all MONEY/BIT NOT NULL); extra `DepartmentId` that legacy ignores |
| `PR_SalaryMain` | Y | `dbo/Tables/PR_SalaryMain.sql` | `SalaryMonth`, `SalaryYear`, `IsVacationSalary`; `IsDeleted` present but not used by legacy |
| `PR_SalaryDetail` | Y | `dbo/Tables/PR_SalaryDetail.sql` | `IncomeAmount`, `UserAmount` (MONEY), `Deduction BIT`, `EmployeeIncomeId` present |
| `PR_Employee` | Y | `dbo/Tables/PR_Employee.sql` | `JobId`, `BranchId`, `DepartmentId` (NOT NULL), `EmployeeSecurityLevel` (default 1), `IDNumber`, `EmployeeNumber` |
| `PR_Job` | Y | `dbo/Tables/PR_Job.sql` | `JobName nvarchar(50)` |
| `PR_Department` | Y | `dbo/Tables/PR_Department.sql` | |
| `PR_Branch` | Y | `dbo/Tables/PR_Branch.sql` | |
| `Acc_Currency` | Y | `dbo/Tables/Acc_Currency.sql` | `CurrencyName`, `CurrencyNameArabic` nvarchar(50) NOT NULL |
| `PR_EmployeeEndWork` | Y | `dbo/Tables/PR_EmployeeEndWork.sql` | `EmployeeId`, `LastWorkingDay DATETIME NOT NULL`; extra `Approved` that legacy ignores |
| `PR_EmployeeEndWorkDetail` | Y | `dbo/Tables/PR_EmployeeEndWorkDetail.sql` | `TotalSalary`, `TotalPostedNotPaidSalary`, `TotalAdvance`, `TotalPurchase`, `TotalPenalty`, `TotalBouns`, `CurrencyId` (MONEY NOT NULL) |
| `dbo.Acc_ConvertStringListToTable` | Y | `dbo/Functions/Acc_ConvertStringListToTable.sql` | returns `number NVARCHAR(MAX)`; NULL input becomes `'0'` |
| (alt.) `dbo.Acc_ConvertIntListToTable` | Y | `dbo/Functions/Acc_ConvertIntListToTable.sql` | same algorithm with an int result (used by the precedent TVF); equivalent for int CSVs |

The legacy MVC runs on the tenant's own (cloud) connection string, so every dependency is the same physical object. No legacy-only SQL objects are involved: both reports use inline TableAdapter SQL, with no procs or views.

### f. Route / permission

- Route `accounting-reports/departments-monthly-salaries-report` → `DepartmentSalaryShellComponent`, `data: { ModuleId: 540 }`, guards `[CanActivateRouteGuard, AccflexAuthGuard]` (`accounting-reports.module.ts` ~91-96).
- Menu:
  - `WebMenuItem.cs:115`: `Department_Salaries = new WebMenuItem("8_5_1", Module.Departmentsmonthlysalariesreport, …)`
  - `Module.cs:489`: `Departmentsmonthlysalariesreport = new Module(540, "Departments monthly salaries report", "Accounting Report", …, 4, 41)`

### g. Ambiguities and risks

1. **End-work fan-out** (biggest 1:1 trap): an employee with an end-work in month M drags in all of their historical `PR_Salaries` rows.
   - Each row is relabelled with end-work amounts and month M, then DISTINCT-collapsed.
   - Rows survive separately whenever `InsuranceCompany` or the salary currency differed historically, so the same end-work net prints more than once and is summed more than once in the grand total.
   - Historical prepaid-vacation runs of that employee also appear, with the PV branch values.
   - This must be ported **verbatim**, including the join-predicate placement and DISTINCT. A "cleaner" rewrite will not match.
2. **DISTINCT can also hide real duplicates**: two genuine salary rows for the same employee and month with identical values print once.
   - A TVF needs a key for OData. Add `ROW_NUMBER()` *after* the DISTINCT (as in the precedent's outer SELECT), never a SalaryId inside it.
3. **Inclusions the new TVF must keep:**
   - unposted salaries
   - soft-deleted runs (`IsDeleted`)
   - unapproved end-works
4. **Security level** is a parameter (`@UserSecurityLevel`, 5 for admin). The TVF needs `@SecurityLevel` like the precedent, fed from the token claim with the same admin → 5 rule.
5. **Filter semantics**: `''` means all, but the "all" path still requires the employee's department and branch to exist in `PR_Department`/`PR_Branch`. With NOT NULL FKs this is effectively an inner join.
   - Pass `NULL` or `''` for "all" in the new screen. The legacy front sends `''` when nothing is selected, despite the `*` on Branch.
6. **Display quirks**:
   - Currency shows `CurrencyNameArabic` and Salary Source shows Arabic text even in English.
   - Net Salary is unformatted.
   - The grand total mixes currencies.
   - The header month comes from row 0. That is always = M here, because end-work rows take `MONTH(LastWorkingDay)` = M.
   - Decide which quirks to keep in the new layout and record the decision.
7. **Month/Year parameter types are `SqlDbType.Decimal`**. This is harmless (comparison with INT); use INT in the TVF.
8. **Prepaid-vacation inconsistency** (`IncomeAmount` for additions vs `UserAmount` for net) means Additions − Deductions ≠ Net on PV rows. This must be reproduced, not "fixed".

---

## Reuse of the precedent `dbo.PR_EmployeeTotalSalariesReport`

File: `AccFlex_Cloud_Database_State/AccFlex_Cloud_Database_State/dbo/Functions/PR_EmployeeTotalSalariesReport.sql`, sqlproj-registered. Its layout is seeded by `Scripts/ReferenceDataScripts/0405_PR_EmployeeTotalSalariesReportLayout.sql`.

What the precedent computes:

- Grain: per salary (employee) for one month.
- PIVOTs `PR_SalaryDetail.IncomeAmount` by a hard-coded `IncomeId` list.
- **Excludes** prepaid-vacation runs (`IsVacationSalary = 0`).
- Computes its own TotalAdditions / TotalDeductions / NetSalary from specific income ids.
- Filters by `@SecurityLevel` and `@EmployeeIds` (through `Acc_ConvertIntListToTable`) and by `@InServiceFilter`.

Neither report can compose over it:

- **Report 5** has a different grain: one row per salary detail line, filtered by income group, posted only, including PV runs, with no security filter. It must query `PR_SalaryDetail` ⋈ `PR_Income` ⋈ `PR_IncomeGroup` ⋈ `PR_Salaries` ⋈ `PR_SalaryMain` ⋈ `PR_Employee` (+ `PR_Projects`/`PR_Branch`/`PR_Department`) directly, as the legacy SQL does.
- **Report 6** uses `PR_Salaries` header totals plus the end-work and prepaid-vacation overrides. Its totals are not the precedent's formulas, and the precedent drops PV runs. Reusing it would change the numbers.

Reuse the **pattern** only:

- an inline TVF over the same base tables
- `@Month`/`@Year`/`@SecurityLevel` params
- the CSV → `Acc_ConvertIntListToTable` helper
- `ROW_NUMBER()` as the key in the outer SELECT
- a reference-data layout script

Suggested TVF parameters for 1:1 output:

- **#5**: `(@Month INT, @Year INT, @IncomeGroupId INT, @EmployeeIds NVARCHAR(MAX) = NULL)`. NULL means all, as legacy.
- **#6**: `(@Month INT, @Year INT, @SecurityLevel INT, @DepartmentIds NVARCHAR(MAX) = NULL, @BranchIds NVARCHAR(MAX) = NULL)`. NULL or `''` means all, keeping the "exists in `PR_Department`/`PR_Branch`" semantics.
