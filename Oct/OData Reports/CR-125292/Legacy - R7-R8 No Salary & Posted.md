# CR 125292 inventory: reports 7 and 8 (NoSalaryByIssued, PostedSalary)

All sources were read from `origin/Master_Stable` with `git show`. Nothing was checked out or changed.
Repos are under `D:\Hadaf\`. Paths are repo-relative.

Files shared by both reports:
- Controller: `AccFlex_ERP:AccFlexContainer/AccFlexContainer.MVC/Controllers/PayrollReports/AccountingReportsController.cs`
- Base controller (security level and culture): `AccFlex_ERP:AccFlexContainer/AccFlexContainer.MVC/Controllers/BaseController.cs`
- Report base class (company header): `AccFlex_ERP:HRManagement/Payroll.Reports/rptMainReport.cs`. Its BeforePrint fills `PR_SystemConfiguration` (CompanyName, Logo, Email, Fax, Telephone, Address) and adds the machine name and user name.
- Static config: `AccFlex_ERP:HRManagement/Payroll.Reports/MainConfigrationData.cs`. Both `SecurityLevel` and `ConnectionString` are **static** fields.
- Viewer: `AccFlex_ERP:AccFlexContainer/AccFlexContainer.MVC/Views/Report/ReportView.cshtml`. Layout store: `.../Services/ReportLayoutDatabaseStore.cs`.
- Front form shared by both shells: `AccFlex_Cloud_Front:accflex-erp/projects/payroll/src/app/modules/accounting-reports/components/salary-report-form/salary-report-form.component.{ts,html}`
- Front transport:
  - `accflex-erp/src/app/shared/services/report-src-handler/report-src-handler.service.ts`
  - `.../query-serialize/query-serialize.service.ts`
  - `.../clean-object/clean-object.service.ts`
  - `accflex-erp/src/app/shared/components/report-iframe-post/report-iframe-post.component.{ts,html}`
- Routes: `AccFlex_Cloud_Front:accflex-erp/projects/payroll/src/app/modules/accounting-reports/accounting-reports.module.ts`
- Menu: `AccFlex_Cloud_ERP:AccFlex_Cloud_ERP/Payroll/Payroll.Service/MenuList/WebMenuItem.cs`
- Module ids: `AccFlex_Cloud_ERP:AccFlex_Cloud_ERP/Shared/SharedKernel.Logic/Modules/Module.cs` and `AccFlex_Cloud_Database:.../Scripts/ReferenceDataScripts/0002_Acc_Module_Data.sql`

## Common transport facts (both reports)

- `ReportSrcHandlerService.getIframeSrc(path, query)` builds `${printRedirectUrl}${path}?lang=<ar-EG|en-US>&<query>`. Outside production it also appends `&access_token=...`.
- `lang` is `en-US` only when the app language is `en-US`. Null or any other value becomes `ar-EG`. Server side, `ChangeThreadCulture` maps anything other than `"en-US"` to `ar-EG`.
- **The parameters are sent by form POST, not in the query string.** `accflex-report-iframe-post` splits the URL on `?`, runs `deSerialize(decodeURIComponent(query))` into an object, and renders one `<input type=hidden name=key value=value>` per key. It then `submit()`s a `method=POST` form into the iframe. The MVC actions carry no verb attribute, so MVC binds the simple-type parameters from the form.
- `QuerySerializeService.serialize`:
  - A `Date` is sent as `addHoursUTCDifferent(date).toISOString()`, which shifts the date by the browser's UTC offset. The result is the **local wall-clock time with a `Z` suffix**, e.g. `2026-10-14T10:30:00.000Z`. The value keeps the current time of day and the current day of month, because the form defaults `Month = new Date()`.
  - An array goes through `encodeURIComponent(array)`, i.e. `Array.toString()`, which produces a CSV such as `1,2,3`.
  - A boolean is sent as `true` or `false`.
- The controller uses only `month.Month` and `month.Year` from the DateTime, so the day and time do not matter. They would matter only if the server shifted the `Z` value across a month boundary, e.g. on the 1st just after local midnight on a server whose time zone is not UTC. That is a low but real edge for 1:1 comparison.

---

## Report 7: Employees With No Issued Salaries (`AccountingReports/NoSalaryByIssued`)

### a. Input contract

Shell: `accflex-erp/projects/payroll/src/app/modules/accounting-reports/containers/employee-no-salary-issued-shell/employee-no-salary-issued-shell.component.{ts,html}`

The form is shown with `isShowBranch=true` and `branchSelectionMode='single'`. Department, income, the employee list and the posted check are hidden. `isInPeriodDate=false`.

The form's `collectReportData` takes the `isShowBranch || isShowDepartment` path:
- `isShowBranch && !this.BranchIdList`: this check is never true, because an empty array `[]` is truthy.
- Then `isFormValid()`, which requires `Month`.
- It emits `{ Month, BranchIdList, DepartmentIdList }`.

The shell's `OnSubmit` returns early if `!e.BranchIdList.length`, so a branch is required. `handleReportSrc` then sends `serialize({ branchId: BranchIdList, month: Month })`.

| Key | Type sent | Example | Notes |
|---|---|---|---|
| `lang` | string | `ar-EG` / `en-US` | |
| `branchId` | CSV of 1 element (`selectedRowKeys` array) | `3` | Required. Single selection. The values come from Payroll API `GET api/Branch` (Payroll `BranchController.GetBranchList`), i.e. PR_Branch ids. That presumption is consistent with the PR_Employee FK below. |
| `month` | ISO string, local wall-clock + `Z` | `2026-10-14T10:30:00.000Z` | Required. Picked with `displayFormat="MM/yyyy"` and `maxZoomLevel: 'year'`. Only the month and year are used. |

`DepartmentIdList` is emitted by the form but dropped by the shell.

### b. Controller action

```csharp
[Route("mvc/AccountingReports/NoSalaryByIssued")]
public IActionResult NoSalaryByIssued(string lang, int branchId, DateTime month)
{
    ChangeThreadCulture(lang);
    var report = new Payroll.Reports.Accounting.Salary.rptEmployee(branchId, month.Month, month.Year);
    return View(REPORTS_ROOT_VIEW, report);
}
```

Report class: `AccFlex_ERP:HRManagement/Payroll.Reports/Accounting/Salary/rptEmployee.cs`, plus `.Designer.cs` and `.resx`. The desktop WinForms copy `HRManagement/PayRoll/Report/rptEmployee.*` is not used by MVC.

The constructor takes `(int _branchId, int _month, int _year)`. If a parameter is missing, binding gives `branchId=0` (no rows) and `month=DateTime.MinValue` (month 1, year 1).

### c. SQL and C#

`rptEmployee_BeforePrint`:
- Sets RTL when Arabic.
- Sets the connection string, falling back to `MainConfigrationData.ConnectionString`.
- `lblSalaryYear.Text = year.ToString(); lblMonth.Text = month.ToString();`. These are plain integers; there is no month name.
- `pR_EmployeeTableAdapterNoIssued1.FillByNoSalaryIssued(dsEmployee1.PR_Employee, branchId, month, year);`

There are **no C# rollups, no extra filters and no rounding.** The report applies no security level, although the base controller sets one.

Typed DataSet: `AccFlex_ERP:HRManagement/Payroll.Reports/Accounting/Salary/dsEmployee.xsd`. The generated `dsEmployee.Designer.cs` `_commandCollection[1]` is identical. Its parameters are `@branchId int`, `@month int` and `@year int`. The `PR_Employee` DataTable has a PK on `EmployeeId`.

Query `FillByNoSalaryIssued`, verbatim:

```sql
SELECT  PR_Employee.EmployeeId ,
        PR_Employee.EmployeeName ,
        PR_Employee.GenderId ,
        PR_Employee.JobId ,
        PR_Employee.DepartmentId ,
        PR_Employee.DateOfBirth ,
        PR_Employee.BankAccountNum ,
        PR_Employee.InsuranceNum ,
        PR_Employee.DateOfWork ,
        PR_Employee.GraduationDate ,
        PR_Employee.EndWorkingDate ,
        PR_Employee.EmployeeDegree ,
        PR_Employee.IDNumber ,
        PR_Employee.Telephone ,
        PR_Employee.Mobile ,
        PR_Employee.SalaryPerAttend ,
        PR_Employee.EmployeeNumber ,
        PR_Employee.DeductionLimit ,
        PR_Employee.PenaltyLimit ,
        PR_Employee.AdvanceLimit ,
        PR_Employee.MedicalInsurance ,
        PR_Employee.MedicalInsuranceValue ,
        PR_Employee.FridayWork ,
        PR_Employee.SaturdayWork ,
        PR_Employee.SundayWork ,
        PR_Employee.MondayWork ,
        PR_Employee.TuesdayWork ,
        PR_Employee.WednesdayWork ,
        PR_Employee.ThursdayWork ,
        PR_Employee.SearchName ,
        PR_Employee.EndWork ,
        PR_Employee.NationalityId ,
        PR_Department.DepartmentName ,
        Acc_Branch.BranchName ,
        PR_Projects.ProjectName ,
        PR_Job.JobName
FROM    PR_Employee
        INNER JOIN PR_Job ON PR_Employee.JobId = PR_Job.JobId
        INNER JOIN PR_Department ON PR_Employee.DepartmentId = PR_Department.DepartmentId
        LEFT JOIN dbo.Acc_Branch ON Acc_Branch.BranchId = PR_Employee.BranchId
        LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
WHERE   PR_Employee.BranchId = @branchId
        AND PR_Employee.EmployeeId NOT IN (
        SELECT  PR_Salaries.EmployeeId
        FROM    PR_Salaries
                INNER JOIN PR_SalaryMain ON PR_Salaries.SalaryMainId = PR_SalaryMain.SalaryMainId
        WHERE   PR_SalaryMain.SalaryMonth = @month
                AND PR_SalaryMain.SalaryYear = @year
                AND PR_Salaries.Posted = 1 )
ORDER BY TRY_CAST(EmployeeNumber AS INT);
```

The layout uses only `EmployeeNumber, EmployeeName, DepartmentName, JobName, Mobile, DateOfWork`.

### d. Printed output (designer `rptEmployee.Designer.cs`, DevExpress 19.1, A4 portrait, margins 50)

Bands:
- **ReportHeader** (inherited from `rptMainReport`): company logo, name, address, tel, fax, email, PC and user labels, from `PR_SystemConfiguration`.
- **PageHeader**:
  - Title cell `lblReportHeader`: "Employees with No salary Issued" / "الموظفين الذين لم يتم اصدار مرتباتهم".
  - `xrTable4`: "Salary Year" / "السنة" followed by `lblSalaryYear`.
  - `xrTable5`: "Salary Month" / "الشهر" followed by `lblMonth`.
- **GroupHeader1**: no GroupFields; `RepeatEveryPage=true`. It is only the column-caption row, in this order:
  1. Code / الرقم
  2. Employee / الموظف
  3. Department / الادارة
  4. Job / الوظيفة
  5. Mobile / الموبايل
  6. Start Work Date / تاريخ بدء العمل
- **DetailMain**: one row per employee.

| # | Caption | Binding | Format |
|---|---|---|---|
| 1 | Code | `PR_Employee.EmployeeNumber` | none |
| 2 | Employee | `PR_Employee.EmployeeName` | none |
| 3 | Department | `PR_Employee.DepartmentName` | none |
| 4 | Job | `PR_Employee.JobName` | none |
| 5 | Mobile | `PR_Employee.Mobile` | none |
| 6 | Start Work Date | `PR_Employee.DateOfWork` | `{0:dd/MM/yyyy}` |

- **No totals, no count, no ReportFooter.**
- Arabic and English share one class. The `Localizer` (`localizer1.ApplyArabic()`) swaps captions and sets RTL.
- `Name` = `rptEmployee` / `rptEmployeeAreg`. `ReportTitle` = "Employees with No salary Issued Report" / "تقرير الموظفين الذين لم يتم اصدار مرتباتهم".

**Where the layout lives:** in the designer `.cs`. `ReportView.cshtml` may override it with a **per-user** layout from `dbo.ACFX_ReportLayout`, matched on `Name = Model.GetType().Name` (`rptEmployee`), `UserId = logged user` and `Language = CurrentUICulture.Name` (`ar-EG` / `en-US`). No `.repx` exists in the repo or in `D:\Hadaf\ReportLayout`.

### e. Cloud DB dependencies (AccFlex_Cloud_Database, `AccFlex_Cloud_Database_State/AccFlex_Cloud_Database_State/`)

| Object | Exists | Path | Notes |
|---|---|---|---|
| dbo.PR_Employee | Y | dbo/Tables/PR_Employee.sql | All selected columns exist. `BranchId INT NOT NULL` has **FK to PR_Branch**, not to Acc_Branch. `JobId` and `DepartmentId` are NOT NULL with FKs, so the INNER JOINs drop nothing. `EmployeeNumber NVARCHAR(100) NOT NULL`. `EmployeeSecurityLevel INT` and `EndWork BIT` exist but this query does not use them. |
| dbo.PR_Job | Y | dbo/Tables/PR_Job.sql | `JobName NVARCHAR(50) NULL` |
| dbo.PR_Department | Y | dbo/Tables/PR_Department.sql | `DepartmentName NVARCHAR(50) NULL` |
| dbo.Acc_Branch | Y | dbo/Tables/Acc_Branch.sql | The legacy query joins it on `PR_Employee.BranchId`, but the FK says PR_Branch. The resulting `BranchName` is wrong-table data, but it is **not printed**. |
| dbo.PR_Projects | Y | dbo/Tables/PR_Projects.sql | Joined only; not printed. |
| dbo.PR_Salaries | Y | dbo/Tables/PR_Salaries.sql | `EmployeeId INT NOT NULL`, so the NOT IN has no NULL trap. `Posted BIT NOT NULL`. |
| dbo.PR_SalaryMain | Y | dbo/Tables/PR_SalaryMain.sql | `SalaryMonth` and `SalaryYear` are INT NOT NULL. It has `IsDeleted BIT` and `IsVacationSalary BIT`, and the legacy query ignores both. |
| dbo.PR_SystemConfiguration | Y | dbo/Tables/PR_SystemConfiguration.sql | Company header data only. |
| dbo.ACFX_ReportLayout | Y | dbo/Tables/ACFX_ReportLayout.sql | The **same table** the legacy MVC store reads (see g). |

All of them are registered in the `.sqlproj`. Several, e.g. PR_Employee and Acc_Branch, are listed twice; that duplication is pre-existing.

### f. Route, ModuleId, permission

- Route `accounting-reports/no-salary-issued-report` uses `EmployeeNoSalaryIssuedShellComponent` with `canActivate: [CanActivateRouteGuard, AccflexAuthGuard]`. **It has no `data: { ModuleId }`**, so the route has no module-level permission check. The sibling route posted-salary has `ModuleId: 541`.
- The menu item is `WebMenuItem.Employees_With_No_Issued_Salaries`: `("4_6_2", Module.EmployeesWithNoIssuedSalariesReport, ..., "accounting-reports/no-salary-issued-report")`.
- `Module.EmployeesWithNoIssuedSalariesReport` = **538**, "Employees With No Issued Salaries Report", category "Accounting Report", group 4, parent 41. It is also present in the `Acc_Module` reference data.
- The new route should carry `data: { ModuleId: 538 }`.

### g. Ambiguities and risks

1. **"Issued" means posted.** An employee whose salary was issued but not posted (`Posted=0`) still appears.
2. Posted vacation salaries (`IsVacationSalary=1`) count as issued.
3. Soft-deleted salary mains (`PR_SalaryMain.IsDeleted=1`) are not excluded, so a posted salary under a deleted main still hides the employee.
4. **No `EndWork` / in-service filter.** Terminated employees of the branch are listed for every month after they leave, and also before they were hired. The query does not check DateOfWork or EndWorkingDate. Reproduce this verbatim and flag it to the business.
5. **No security-level filter.** All other HR reports filter on `EmployeeSecurityLevel <= @SecurityLevel`. This one does not, which is a data-exposure gap. A 1:1 port must omit the filter, or the business must accept a difference.
6. The branch filter uses the employee's **current** `PR_Employee.BranchId`, not `PR_SalaryMain.BranchId`.
7. Sort order is `TRY_CAST(EmployeeNumber AS INT)`. Non-numeric numbers become NULL and sort first. Ties and NULLs have an undefined order. A TVF cannot carry ORDER BY, so expose an `EmployeeNumberInt` / `RowNo` (as in the precedent) and sort in OData or the layout. Values beyond INT range (EmployeeNumber is nvarchar(100)) also become NULL; keep INT, not BIGINT, to match.
8. The Acc_Branch vs PR_Branch join is a latent bug but harmless here, because BranchName is not printed. If the new layout shows a branch, decide which table to use.
9. Year and month are printed as raw ints, e.g. "10", not a month name.
10. The single-select branch is sent as a CSV of one element. A multi-select in a new screen would change the contract, because the controller is `int branchId`.

### Precedent `dbo.PR_EmployeeTotalSalariesReport`

It is not reusable. That TVF pivots salary detail for the month and excludes vacation salaries; this report is an anti-join over PR_Employee. The only shared conventions are the param naming, `RowNo` / `EmployeeNumberInt` and inline-TVF style. A new small inline TVF over the same base tables (PR_Employee, PR_Salaries, PR_SalaryMain, PR_Job, PR_Department) is the straightforward port.

---

## Report 8: Posted Salaries (`AccountingReports/PostedSalary`)

### a. Input contract

Shell: `accflex-erp/projects/payroll/src/app/modules/accounting-reports/containers/posted-salary-shell/posted-salary-shell.component.{ts,html}`

The form is shown with `isShowSharedEmployeeList=true` and `isShowPostedSalaryCheck=true`. Branch, department and income are hidden. `isInPeriodDate=false`. The employee list is `pay-shared-employee-list` with `selection="multiple"` and `[inServiceOnly]="false"`, so it lists all employees, including terminated ones.

The form takes the `collectEmployeesSalaryReport` path:
- `isFormValid()` requires `Month`.
- If no employee is selected, `EmployeeIdList = getAllEmployeeIds().split(',')`, i.e. **every EmployeeId loaded in the shared list**.
- It emits `{ Month, EmployeeIdList, IncomeId, IsPosted }`.

The shell's `handleReportSrc` builds `{ employeeIds: EmployeeIdList.length ? EmployeeIdList : ReportFormRef.getAllEmployeeIds(), month: Month, isPost: IsPosted }`, then `cleanNullAndEmptyString`, then `serialize`.

| Key | Type sent | Example | Notes |
|---|---|---|---|
| `lang` | string | `ar-EG` | |
| `employeeIds` | CSV | `12,15,301,...` | Never empty in practice: it is either the selection or **all** employees in the list. |
| `month` | ISO string, wall-clock + `Z` | `2026-10-14T10:30:00.000Z` | Required. Only the month and year are used. |
| `isPost` | `true` / `false` | `false` | Checkbox "Posted Salary" / "راتب معتمد". **Defaults to false.** `false` is not stripped by `cleanNullAndEmptyString`. |

### b. Controller action

```csharp
[Route("mvc/AccountingReports/PostedSalary")]
public IActionResult PostedSalary(string lang, string employeeIds, DateTime month, bool isPost)
{
    ChangeThreadCulture(lang);
    var report = new Payroll.Reports.Accounting.Salary.rptPostedSalaryFormReport(month.Month, month.Year, employeeIds, isPost);
    return View(REPORTS_ROOT_VIEW, report);
}
```

Report class: `AccFlex_ERP:HRManagement/Payroll.Reports/Accounting/Salary/rptPostedSalaryFormReport.cs`, plus `.Designer.cs` and `.resx`. A desktop copy exists under `HRManagement/PayRoll/Accounting/Reports/Salaries/EmployeesSalaries/` but is not used by MVC.

The constructor is `(int _month, int _salaryYear, string _employeeIdList, bool _isPost)`. A null or empty `employeeIds` becomes `string.Empty`.

The default ctor sets `UserSecurityLevel = MainConfigrationData.SecurityLevel`. That value is static and set in `BaseController`'s ctor: `isAdmin` claim true gives `5`; otherwise it is `int.Parse(securityLevel claim)`.

### c. SQL and C#

`rptSalaryFormReport_BeforePrint`:
- Sets RTL and the connection string.
- `monthSalaryTableAdapter.ClearBeforeFill = true; monthSalaryTableAdapter.FillPosted(dsDepartmentSalary1.MonthSalary, salaryMonth, salaryYear, employeeIdList, isPost, UserSecurityLevel);`
- `lblDate.Text = $"{CultureInfo.CreateSpecificCulture(isArabic ? "ar-EG" : "en").DateTimeFormat.GetMonthName(salaryMonth)} / {salaryYear}"`. This is a header label only.

There are **no C# rollups or filters.** The totals are DevExpress summaries (see d).

Typed DataSet: `AccFlex_ERP:HRManagement/Payroll.Reports/Accounting/Salary/dsDepartmentSalary.xsd`. The generated code is `dsDepartmentSalary1.Designer.cs`, `_commandCollection[2]`. It was spot-checked fragment by fragment and is identical to the xsd.

Generated parameters:
- `@SalaryMonth` SqlDbType.Decimal
- `@SalaryYear` SqlDbType.Decimal
- `@EmployeeIdList` **SqlDbType.VarChar, Size 1024**
- `@IsPosted` Bit
- `@UserSecurityLevel` Int

Method signature: `FillPosted(table, decimal SalaryMonth, decimal SalaryYear, string EmployeeIdList, bool IsPosted, int UserSecurityLevel)`. `IsPosted` is a **non-nullable** bool.

Query `FillPosted`, verbatim:

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
    WHERE PR_EmployeeEndWorkDetail.TotalSalary >= 0
	AND MONTH(LastWorkingDay)=
	@SalaryMonth AND YEAR(LastWorkingDay)=@SalaryYear),
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
       END AS SalarySourceEng,
	   PR_Employee.IDNumber
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
WHERE (
          (
              MONTH(EndWorkDetailsCTE.LastWorkingDay) = @SalaryMonth
              AND YEAR(EndWorkDetailsCTE.LastWorkingDay) = @SalaryYear
          )
          OR
          (
              PR_SalaryMain.SalaryMonth = @SalaryMonth
              AND PR_SalaryMain.SalaryYear = @SalaryYear
          )
      )
      AND
      (
          (@EmployeeIdList = '')
          OR (PR_Employee.EmployeeId IN
              (
                  SELECT number
                  FROM dbo.Acc_ConvertStringListToTable(@EmployeeIdList) AS Acc_ConvertStringListToTable_1
              )
             )
      )
      AND
      (
          (@IsPosted IS NULL)
          OR (PR_Salaries.Posted = @IsPosted)
      )
      AND PR_Employee.EmployeeSecurityLevel <= @UserSecurityLevel;
```

Effective semantics:
- `@IsPosted` is never NULL, so the filter is always `Posted = isPost`.
- `@EmployeeIdList` is effectively never `''`.
- The security-level predicate makes the `LEFT JOIN PR_Employee` behave as an INNER join.

### d. Printed output (designer `rptPostedSalaryFormReport.Designer.cs`, DevExpress 20.2, A4 portrait, margins 50)

Bands:
- **ReportHeader** (inherited): company header from `PR_SystemConfiguration`.
- **PageHeader**:
  - Title `lblReportHeader`: "Posted Salary Report" / " تقرير المرتبات المعتمدة".
  - `lblDate`: "<MonthName> / <Year>". The month name is localized (en or ar-EG).
  - The column header table `xrTable12`, repeated on every page.
- **DetailMain** (`xrTable7`): one row per DISTINCT result row, in data order. The report has **no ORDER BY, no SortFields and no grouping.**

| # | Caption (EN / AR) | Binding | Format |
|---|---|---|---|
| 1 | Code / الرقم الوظيفي | `MonthSalary.EmployeeNumber` | none |
| 2 | Employee Name / الموظف | `MonthSalary.EmployeeName` | none |
| 3 | Job / الوظيفة | `MonthSalary.JobName` | none |
| 4 | Currency / العملة | `MonthSalary.CurrencyNameArabic` | none. **The Arabic name is shown in English too.** |
| 5 | Expected Sal. / المرتب المتوقع | `MonthSalary.InsuranceCompany` | none. **The caption says "expected salary" but the value is `PR_Salaries.InsuranceCompany`.** |
| 6 | Total Accruals / اجمالي المستحقات | `MonthSalary.TotalAdditions` | `{0:n2}` |
| 7 | Total Deductions / اجمالي الاستقطاعات | `MonthSalary.TotalDeductions` | `{0:0.00}` |
| 8 | Net Salary / صافي الراتب | `MonthSalary.TotalSalary` | `{0:0.00}` |
| 9 | Salary Source / مصدر الراتب | `MonthSalary.SalarySource` | **Arabic text in English too.** `SalarySourceEng` is unused. |

- **ReportFooter**, totals row `xrTable8`. These are report-level summaries; the function is the default Sum, with `Running=Report`. The cells do not align with the detail columns.
  - "Total" / "الاجمالي", spanning width 1.379.
  - Sum(`InsuranceCompany`) `{0:n2}`
  - Sum(`TotalAdditions`) `{0:0.00}`, IgnoreNullValues
  - Sum(`TotalDeductions`) `{0:0.00}`, IgnoreNullValues
  - Sum(`TotalSalary`) `{0:0.00}`, IgnoreNullValues
- The footer also holds signature lines "Excutive Manager" / "المدير التنفيذي" and "Accounting Manager" / "مدير الحسابات".
- Totals are a **single grand total across all currencies**; there is no per-currency subtotal.
- `Name` = `rptPostedSalaryFormReport` / `rptPostedSalaryFormReportAreg`. The layout source is the designer `.cs`, optionally overridden by a per-user `ACFX_ReportLayout` row with `Name='rptPostedSalaryFormReport'`. No `.repx` exists on disk.

### e. Cloud DB dependencies

| Object | Exists | Path | Notes |
|---|---|---|---|
| dbo.PR_Salaries | Y | dbo/Tables/PR_Salaries.sql | `InsuranceCompany`, `TotalAdditions` and `TotalDeductions` are MONEY NOT NULL. `Posted BIT NOT NULL`. `CurrencyId INT NOT NULL`. `EmployeeId NOT NULL`. |
| dbo.PR_SalaryMain | Y | dbo/Tables/PR_SalaryMain.sql | `SalaryMonth`, `SalaryYear` and `IsVacationSalary` exist. `IsDeleted` exists and is **not filtered** by the legacy query. |
| dbo.PR_SalaryDetail | Y | dbo/Tables/PR_SalaryDetail.sql | `EmployeeIncomeId`, `Deduction BIT`, `UserAmount MONEY` and `IncomeAmount MONEY` exist. Income 9994 is hard-coded as excluded. |
| dbo.PR_EmployeeEndWork | Y | dbo/Tables/PR_EmployeeEndWork.sql | `EmployeeId` and `LastWorkingDay DATETIME NOT NULL` exist. `Approved BIT` exists and is **not filtered**. |
| dbo.PR_EmployeeEndWorkDetail | Y | dbo/Tables/PR_EmployeeEndWorkDetail.sql | `TotalSalary`, `TotalAdvance`, `TotalPenalty`, `TotalPurchase`, `TotalBouns`, `TotalPostedNotPaidSalary` and `CurrencyId` exist; all are MONEY/INT NOT NULL. There can be several rows per EndWork, one per currency. |
| dbo.PR_Employee | Y | dbo/Tables/PR_Employee.sql | `EmployeeSecurityLevel INT NOT NULL DEFAULT 1`. `BranchId` has an FK to PR_Branch. `IDNumber` exists. |
| dbo.PR_Job | Y | dbo/Tables/PR_Job.sql | |
| dbo.PR_Department | Y | dbo/Tables/PR_Department.sql | |
| dbo.PR_Branch | Y | dbo/Tables/PR_Branch.sql | `BranchName NVARCHAR(1000)`. This is the correct FK target. It is selected but not printed. |
| dbo.Acc_Currency | Y | dbo/Tables/Acc_Currency.sql | `CurrencyName` and `CurrencyNameArabic` are NVARCHAR(50) NOT NULL. |
| dbo.Acc_ConvertStringListToTable | Y | dbo/Functions/Acc_ConvertStringListToTable.sql | Multi-statement TVF. It returns `number NVARCHAR(MAX)`, which is compared to int EmployeeId through an implicit conversion. A NULL list becomes `'0'`. The precedent uses `Acc_ConvertIntListToTable` instead; it exists at dbo/Functions/Acc_ConvertIntListToTable.sql. |
| dbo.PR_SystemConfiguration | Y | dbo/Tables/PR_SystemConfiguration.sql | Header only. |
| dbo.ACFX_ReportLayout | Y | dbo/Tables/ACFX_ReportLayout.sql | Legacy per-user override store; same table as cloud layouts. |

All are registered in the `.sqlproj`. There is no existing cloud object for this logic: a grep for `PrepaidVacationDetails` / `EndWorkDetailsCTE` found nothing.

### f. Route, ModuleId, permission

- Route `accounting-reports/posted-salary-report` uses `PostedSalaryShellComponent` with `canActivate: [CanActivateRouteGuard, AccflexAuthGuard]` and **`data: { ModuleId: 541 }`**.
- The menu item is `WebMenuItem.Posted_Salaries`: `("8_1_5", Module.PostedSalariesReport, "Posted Salaries", "المرتبات المعتمدة", ..., "accounting-reports/posted-salary-report")`.
- `Module.PostedSalariesReport` = **541**, "Posted Salaries Report", group 4, parent 41. It is also in the `Acc_Module` reference data.

### g. Ambiguities and risks (high impact for 1:1)

1. **`@EmployeeIdList` is truncated to 1024 characters.** The generated SqlParameter is `VarChar, Size=1024`, and an explicit Size truncates longer input silently. The front sends **all** employee ids when nothing is selected. On any tenant where that CSV exceeds 1024 characters (about 200 or more employees, depending on id length):
   - Legacy silently drops the employees past the cut.
   - The last token can be a **partial id**, e.g. `"1234"` cut to `"12"`, which pulls in a wrong employee.

   An NVARCHAR(MAX) TVF param will return **more rows** than legacy on large tenants. Decide whether to reproduce the bug, which is not recommended, or document the difference. For the diff, compare with lists under 1024 characters.
2. **The default run shows unposted salaries.** The checkbox defaults to `false`, so the filter is `Posted = 0`, despite the title "Posted Salary Report". There is no "both" option: the `@IsPosted IS NULL` branch is dead code.
3. **End-of-work fan-out.**
   - `EndWorkDetailsCTE` is joined by EmployeeId only. Once an employee's `LastWorkingDay` falls in the month, the OR in WHERE admits **every PR_Salaries row of that employee from any month or year**, subject to the posted filter.
   - Each such row then shows the end-of-work amounts, because the CASE prefers EndWork unless the row is a vacation salary. Its `SalaryMonth` / `SalaryYear` are those of LastWorkingDay.
   - `SELECT DISTINCT` collapses these rows only when every selected column is equal. `InsuranceCompany` and `CurrencyName` come from each PR_Salaries row, so differing values leave **duplicate end-of-work rows**, and the footer totals inflate.
   - Prepaid-vacation salaries from other months also leak in through this path.
   - Several EndWorkDetail currencies multiply the rows.
   - The same-month monthly salary of an end-of-work employee is **replaced** by the end-of-work figure (`SalarySource = اخلاء طرف`).
4. **DISTINCT can under-count.** Two genuinely different salary rows that select identical values collapse into one. For example, an employee with two salary batches in the same month with the same amounts and currency: one row disappears and the totals drop. A port must keep DISTINCT over **exactly the same column list**, including the unprinted columns DepartmentId, BranchName, BranchId, CurrencyName, SalaryMonth, SalaryYear, SalarySourceEng and IDNumber. Adding a key such as SalaryId would change the numbers.
5. Rows are not filtered on `PR_SalaryMain.IsDeleted` or on `PR_EmployeeEndWork.Approved`. Unapproved end-of-work records count.
6. End-of-work rows require a `PR_Salaries` row: the FROM clause is `PR_Salaries`. An employee whose only activity in the month is the end-of-work, with no salary row at all, does not appear. An employee with an end-of-work in the month and only older salary rows does appear, through the fan-out in point 3.
7. Several values are fixed regardless of language:
   - The Currency column is always `CurrencyNameArabic`.
   - Salary Source is always Arabic.
   - "Expected Sal." is really `InsuranceCompany`.

   A faithful port keeps the bindings. A layout improvement can switch on language, but that is a visual change, not a data change.
8. **The grand totals mix currencies.**
9. Formatting is inconsistent: `n2`, with thousands separators, for Additions and the InsuranceCompany sum; `0.00`, without separators, for the others. The values are not rounded beyond display.
10. **Security level comes from a static field.** `MainConfigrationData.SecurityLevel` is a static set in each request's controller ctor, so concurrent requests from other users or tenants can race it. The admin claim gives 5. The cloud TVF should take `@SecurityLevel` from the logged user, as the precedent does: `isAdmin` → 5, else the claim. For the diff, use a single user.
11. Sort order is undefined: there is no ORDER BY and no SortFields, so the row order comes from DISTINCT's plan. It cannot be matched exactly; diff as sets.
12. `@SalaryMonth` and `@SalaryYear` are sent as SQL `decimal`. Comparisons with INT and with `MONTH()` are equivalent, so there is no impact.

### Precedent `dbo.PR_EmployeeTotalSalariesReport`

It **cannot** be reused or composed over. It:
- excludes `IsVacationSalary=1`;
- has no Posted filter and no end-of-work logic;
- derives totals from the PR_SalaryDetail pivot with its own formulas, where this report reads `PR_Salaries.TotalAdditions` / `TotalDeductions`;
- has no DISTINCT.

What carries over are the conventions:
- inline TVF with `@Month`, `@Year`, `@SecurityLevel` and `@EmployeeIds NVARCHAR(MAX) = NULL`;
- `ROW_NUMBER() ... AS RowNo` for ordering;
- `EmployeeNumberInt`;
- an `EmployeeSecurityLevel <= @SecurityLevel` predicate.

For 1:1 fidelity, port the FillPosted SQL verbatim into an inline TVF:
- Wrap the DISTINCT select in a CTE, then add RowNo outside it so DISTINCT semantics are preserved.
- Keep `Acc_ConvertStringListToTable`, or switch to the Int variant. The Int variant is equivalent for clean numeric CSVs, but the string variant turns an empty token from `''` into 0.
- Map `@IsPosted BIT`, with no NULL branch needed, and keep the 1024-character caveat documented.

---

## Cross-cutting note on layout storage

The legacy MVC per-user layout override reads **`dbo.ACFX_ReportLayout` in the tenant DB**: `ReportLayoutDatabaseStore.GetReportLayoutByNameAndLanguage`, matched on `Name` (the CLR type name), `UserId` and `Language`. That is the same table the cloud OData layouts use, so the "different table" statement in `legacy-anatomy.md` §6 does not hold for this controller.

The legacy rows use the Names `rptEmployee` / `rptPostedSalaryFormReport` with a non-null UserId. New seeded layouts must use distinct Names to avoid clashing with any user-saved legacy override.
