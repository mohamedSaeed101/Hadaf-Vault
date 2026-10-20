# CR 125292: legacy inventory, payroll "Employee Salaries" and "Employee Summarized Salaries"

All sources were read from `origin/Master_Stable` with `git show`. Nothing was checked out or changed.

| # | Legacy MVC route | rpt class (runtime type name = layout key) | Front shell | Web route | Menu ModuleId |
|---|---|---|---|---|---|
| 1 | `mvc/AccountingReports/EmployeeSalaries` | `Payroll.Reports.Accounting.Salary.rptSalarySignature` | `containers/employee-salary-shell` | `accounting-reports/salary-report` | 514 (`EmployeeSalarieReport`) |
| 2 | `mvc/AccountingReports/EmployeeSalaryDetails` | `Payroll.Reports.Accounting.Salary.rptEmployeeSalaryDetails` | `containers/employee-salary-details-shell` | `accounting-reports/salary-details-report` | 537 (`EmployeeSummarizedSalariesReport`) |

Both reports use the **same typed DataSet** `dsSalary` and the same `PR_SalariesTableAdapter` base SQL. Each one appends its own WHERE clause in C#.

### Key files
- Controller: `D:\Hadaf\AccFlex_ERP\AccFlexContainer\AccFlexContainer.MVC\Controllers\PayrollReports\AccountingReportsController.cs` (lines 21-37)
- Report code-behind:
  - `D:\Hadaf\AccFlex_ERP\HRManagement\Payroll.Reports\Accounting\Salary\rptSalarySignature.cs` and `.Designer.cs`
  - `D:\Hadaf\AccFlex_ERP\HRManagement\Payroll.Reports\Accounting\Salary\rptEmployeeSalaryDetails.cs` and `.Designer.cs`
- DataSet:
  - `D:\Hadaf\AccFlex_ERP\HRManagement\Payroll.Reports\Accounting\Salary\dsSalary.xsd`. The generated `dsSalary1.Designer.cs` CommandTexts match the xsd byte-for-byte; checked.
  - `dsSalary.cs` holds the `FillByWhere` partials.
- Base report: `D:\Hadaf\AccFlex_ERP\HRManagement\Payroll.Reports\rptMainReport.cs` and `.designer.cs`. It provides the company header from `PR_SystemConfiguration` (logo, name, email, fax, tel, address), plus "PC:"/"User:" and the page info.
- Report view and layout store:
  - `AccFlexContainer.MVC\Views\Report\ReportView.cshtml`
  - `AccFlexContainer.MVC\Services\ReportLayoutDatabaseStore.cs`
- Desktop twins exist and are out of scope:
  - `HRManagement\PayRoll\Accounting\Reports\rptSalarySignature.*`
  - `HRManagement\PayRoll\Report\rptEmployeeSalaryDetails.*`
- Front: everything is under `D:\Hadaf\AccFlex_Cloud_Front\accflex-erp\`:
  - `projects/payroll/src/app/modules/accounting-reports/accounting-reports.module.ts`
  - `.../containers/employee-salary-shell/employee-salary-shell.component.{ts,html}`
  - `.../containers/employee-salary-details-shell/employee-salary-details-shell.component.{ts,html}`
  - `.../components/salary-report-form/salary-report-form.component.{ts,html}`
  - `projects/payroll/src/app/shared/components/shared-employee-list/shared-employee-list.component.ts`
  - `src/app/shared/services/report-src-handler/report-src-handler.service.ts`
  - `src/app/shared/services/query-serialize/query-serialize.service.ts`
  - `src/app/shared/services/global-methods.ts`
  - `src/app/shared/services/clean-object/clean-object.service.ts`
  - `src/app/shared/components/report-iframe-post/report-iframe-post.component.{ts,html}`
- Menu and modules:
  - `D:\Hadaf\AccFlex_Cloud_ERP\AccFlex_Cloud_ERP\Payroll\Payroll.Service\MenuList\WebMenuItem.cs` (lines 109-110)
  - `D:\Hadaf\AccFlex_Cloud_ERP\AccFlex_Cloud_ERP\Shared\SharedKernel.Logic\Modules\Module.cs` (lines 463, 486)

---

## Shared input pipeline (both reports, identical code)

The two shells are identical except for the MVC path and the heading i18n key. Report 1 uses `ACCOUNTINGREPORTS._EmployeeSalariesReport_` and report 2 uses `ACCOUNTINGREPORTS._EmployeeSummarizedSalaries_`.

1. **Form** `pay-salary-report-form` is used with these inputs: `isShowBranch=false`, `isShowIncome=false`, `isShowDepartment=false`, `isShowSharedEmployeeList=true`, `isShowPostedSalaryCheck=false`, `isInPeriodDate=false`. Visible controls:
   - **Employee multi-select** (`pay-shared-employee-list`, `selection="multiple"`, `[inServiceOnly]="false"`).
     - The list comes from `GET /Payroll/Employee/false/WorkingDate/{today yyyy-MM-dd}`, which maps to `EmployeeRepo.GetAllEmployees(isInServiceOnly:false, untilWorkingDate)`.
     - That query uses `.IgnoreQueryFilters()`, so there is **no security-level filter**. It returns in-service and terminated employees with `HiringDate <= today`.
   - **Month** (`dx-date-box`, `displayFormat="MM/yyyy"`, `maxZoomLevel: 'year'`, required). It defaults to `new Date()` (today plus the current time).
2. **Submit** (`collectReportData` → `collectEmployeesSalaryReport`):
   - Validation is `Month` truthy only.
   - If no employee is selected, `EmployeeIdList = getAllEmployeeIds().split(',')`, which means **every employee in the picker**.
   - It emits `{ Month, EmployeeIdList, IncomeId:null, IsPosted:false }`.
3. **Shell `handleReportSrc`**:
   - Builds `{ employeeIds: data.EmployeeIdList, month: data.Month }`. If `employeeIds.length` is 0, it falls back to `getAllEmployeeIds()` (a CSV string).
   - `cleanNullAndEmptyString` runs next, then `QuerySerializeService.serialize`:
     - A `Date` becomes `addHoursUTCDifferent(date).toISOString()`. The browser's TZ offset is added first, so the "Z" string carries the **local wall-clock** time, e.g. `2026-10-14T13:45:12.000Z`.
     - An array goes through `encodeURIComponent(array)`, which turns it into a **comma CSV** (`Array.toString`), e.g. `12,15,40`.
4. **URL** (`ReportSrcHandlerService.getIframeSrc`): `${printRedirectUrl}AccountingReports/<Name>?lang=<ar-EG|en-US>&employeeIds=<csv>&month=<iso>`. In non-production, `&access_token=…` is appended.
5. **Transport** (`accflex-report-iframe-post`): the URL is split and the query is de-serialized into hidden inputs. It is then sent as an **HTML form POST** (`target="reportFrame"`) to the MVC endpoint, not as a GET.

**Effective input contract**

| Key | Type | Format | Required |
|---|---|---|---|
| `lang` | string | `ar-EG` / `en-US` | yes (always sent) |
| `employeeIds` | string | CSV of ints, no spaces | effectively always non-empty from the UI; the server tolerates empty |
| `month` | DateTime | ISO with `Z`; only `.Year` / `.Month` are used | yes |

There is no branch, department, posted or currency filter.

---

## Report 1: Employee Salaries (`EmployeeSalaries` → `rptSalarySignature`)

### a. Input contract
See the shared pipeline above: `lang`, `employeeIds` (CSV), `month` (ISO DateTime). Only year and month are used.

### b. Controller

```csharp
[Route("mvc/AccountingReports/EmployeeSalaries")]
public IActionResult EmployeeSalaries(string lang, string employeeIds, DateTime month)
{
    ChangeThreadCulture(lang);
    var report = new Payroll.Reports.Accounting.Salary.rptSalarySignature(month.Year, month.Month, employeeIds);
    return View(REPORTS_ROOT_VIEW, report);
}
```

The constructor is `(int salaryYear, int salaryMonth, string employeesIds)`. There are no hard-coded arguments.

### c. SQL and C# logic

**Constructor:**
- `Name = isArabic ? "rptSalarySignatureAreg" : "rptSalarySignature"`.
- `lblReportHeader.Text = isArabic ? " مرتبات الموظفين" : "Employees Salaries "`, and `ReportTitle` is set to the same text.
- `localizer1.ApplyArabic()` runs when the language is Arabic.

**`rptSalarySignature_BeforePrint`:**
- Sets RTL when Arabic.
- Sets `pR_SalariesTableAdapter` to use the connection string.
- If `employeesIds` is not empty, it calls `FillByWhere(dsSalary1.PR_Salaries, quary, "")` with the clause shown verbatim below. `FillByWhere` appends it directly to the base SELECT and sends no ORDER BY.
  ```
   LEFT JOIN dbo.PR_SalaryMain ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId WHERE PR_Salaries.EmployeeId IN ({employeesIds}) AND PR_SalaryMain.IsDeleted <> 1 AND  PR_SalaryMain.SalaryYear = {salaryYear} AND PR_SalaryMain.SalaryMonth = {salaryMonth} 
  ```
  The values are string-formatted straight into the SQL. There are no SQL parameters, so the input is open to SQL injection.
- Else: `pR_SalariesTableAdapter.Fill(...)`, which runs the base SELECT with **no filter at all**: every salary row of every month in the DB.
- **C# computation:** `Serial` is set to 1..N in DataTable order, which is the SQL return order. Serial is **not bound** to any control in the designer layout.
- `lblDate.Text = $"{CultureInfo.CreateSpecificCulture(isArabic ? "ar-EG" : "en").DateTimeFormat.GetMonthName(salaryMonth)} / {salaryYear}"`, e.g. `October / 2026` or `أكتوبر / 2026`.
- `PR_SalaryMainTableAdapter` is **never filled**, even though the report's own `DataMember = "PR_SalaryMain"`.

**Base SELECT** (`dsSalary.xsd`, TableAdapter `PR_Salaries`, verbatim, no parameters):
```sql
SELECT  PR_Salaries.SalaryId ,
        PR_Salaries.SalaryMainId ,
        PR_Salaries.EmployeeId ,
        PR_Salaries.Suspend ,
        PR_Salaries.Total ,
        PR_Salaries.Remarks ,
        PR_Salaries.InsuranceCompany ,
        PR_Salaries.Posted ,
        PR_Salaries.TotalAdditions ,
        PR_Salaries.TotalDeductions ,
        PR_Salaries.CurrencyId ,
        PR_Salaries.PostDate ,
        Acc_Currencies.CurrencyName ,
        PR_Job.JobName ,
        dbo.PR_EmployeeGroup.EmployeeGroupName AS CategoryName ,
        dbo.PR_EmployeeGroup.EmployeeGroupNameSecondLanguage AS CategoryNameSecondLanguage ,
        PR_Employee.EmployeeId ,
        PR_Employee.EmployeeName ,
        PR_Employee.EduDegreeId ,
        PR_Employee.GenderId ,
        PR_Employee.JobId ,
        PR_Employee.MaritalStatusId ,
        PR_Employee.BranchId ,
        PR_Employee.DepartmentId ,
        PR_Employee.DateOfBirth ,
        PR_Employee.BankAccountNum ,
        PR_Employee.InsuranceNum ,
        PR_Employee.DateOfWork ,
        PR_Employee.GraduationDate ,
        PR_Employee.EndWorkingDate ,
        PR_Employee.EmployeeDegree ,
        PR_Employee.Address ,
        PR_Employee.IDNumber ,
        PR_Employee.PerImage ,
        PR_Employee.Telephone ,
        PR_Employee.Mobile ,
        PR_Employee.VacationDays ,
        PR_Employee.Remarks ,
        PR_Employee.IncentivesPolicyId ,
        PR_Employee.OverTimePolicyId ,
        PR_Employee.LatenessPolicyId ,
        PR_Employee.AbsencePolicyId ,
        PR_Employee.EarlyQuitPolicyId ,
        PR_Employee.BankId ,
        PR_Employee.SalaryPerAttend ,
        PR_Employee.DeductionLimit ,
        PR_Employee.DeductionLimit AS PurchaseLimit,
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
        PR_Employee.Email ,
        PR_Employee.CostCenterId ,
        PR_Employee.AccountId ,
        PR_Employee.ManagerId ,
        PR_Employee.OfficalHolidaysBalance ,
        PR_Employee.EmployeeArabicName ,
        PR_Employee.OfficailVacationDays ,
        PR_Employee.VacationRuleTypeId ,
        PR_Employee.InningsVacationId ,
        PR_Employee.InningsVacationBalance ,
        PR_Employee.FingerPrintCode ,
        PR_Employee.RelegionId ,
        PR_Employee.EmployeeNumber ,
        PR_Employee.Age ,
        PR_Employee.JobGrade ,
        PR_Employee.Bonus ,
        PR_Employee.Disapility ,
        PR_Employee.ChronicDisease ,
        PR_Employee.IDPlaceOfExtraction ,
        PR_Employee.CanUseComputer ,
        PR_Employee.IncomeTaxId ,
        PR_Employee.EndServicePolicyId ,
        PR_Employee.VacationWorkPolicyId ,
        PR_Employee.EmployeeSecurityLevel ,
        PR_Employee.AnnualVacationSystemId ,
        PR_Employee.AttachmentGuidNumber ,
        PR_Employee.UserGuidNumber ,
        PR_Employee.WorkDate ,
        PR_Employee.IsCompanyPayEmployeeTax ,
        PR_Employee.EmployeeGroupId ,
        PR_Employee.LeavePermissionPolicyId ,
        PR_Employee.SocialInsuranceStartDate ,
        PR_Employee.DefaultProjectId ,
        PR_Projects.ProjectName ,
        empManger.EmployeeName AS MangerName ,
        PR_EduDegree.EduDegreeName ,
        PR_Department.DepartmentName ,
        PR_Branch.BranchName ,
        ( SELECT    STUFF(( SELECT  ' ,  ' + QualifationName
                            FROM    dbo.Pr_Qualifications
                                    LEFT JOIN dbo.PR_Employee AS emp ON emp.EmployeeId = Pr_Qualifications.EmployeeId
                            WHERE   emp.EmployeeId = PR_Employee.EmployeeId
                          FOR
                            XML PATH('')
                          ), 1, 2, '')
        ) AS Qualifations ,
        ROW_NUMBER() OVER ( PARTITION BY PR_Salaries.SalaryMainId ORDER BY empManger.EmployeeId ) AS roeNum
FROM    PR_Salaries
        INNER JOIN PR_Employee ON PR_Salaries.EmployeeId = PR_Employee.EmployeeId
        LEFT OUTER JOIN PR_Job ON PR_Employee.JobId = PR_Job.JobId
        LEFT OUTER JOIN Acc_Currencies ON PR_Salaries.CurrencyId = Acc_Currencies.CurrencyId
        LEFT OUTER JOIN dbo.PR_EmployeeGroup ON PR_EmployeeGroup.EmployeeGroupId = PR_Employee.EmployeeGroupId
        LEFT JOIN dbo.PR_Projects ON PR_Projects.ProjectId = PR_Employee.DefaultProjectId
        LEFT JOIN dbo.PR_Employee AS empManger ON empManger.EmployeeId = PR_Employee.ManagerId
        LEFT JOIN dbo.PR_Department ON PR_Department.DepartmentId = PR_Employee.DepartmentId
        LEFT JOIN dbo.PR_Branch ON PR_Branch.BranchId = PR_Employee.BranchId
        LEFT JOIN dbo.PR_EduDegree ON PR_EduDegree.EduDegreeId = PR_Employee.EduDegreeId
```

The effective query for report 1 is the base SELECT plus the `LEFT JOIN PR_SalaryMain … WHERE …` clause above. The WHERE makes that LEFT JOIN behave as an INNER JOIN.
- No `Posted` filter.
- No `IsVacationSalary` filter.
- No `EmployeeSecurityLevel` filter.
- No ORDER BY.

The DataSet's primary key on PR_Salaries is `SalaryId`, and every join in the base SELECT is on a PK, so there are no fan-out duplicates.

### d. Printed output (designer layout in `rptSalarySignature.Designer.cs`; no `.repx` on disk, no DB seed)

**Bands:** `ReportHeader` (base company header), `PageHeader`, `DetailReport`, `DetailMain` (base, height 0), plus margins.

The class also declares a `Detail` band with `lblReportTitle` ("Employees Salaries" / "مرتبات الموظفين"), but that band is **not** in `Bands.AddRange`. It is orphaned and does not print.

- **PageHeader:** `lblReportHeader`, the title set in the constructor.
- **DetailReport** (`DataSource=dsSalary1`, `DataMember="PR_Salaries"`, independent of the empty `PR_SalaryMain` master). It prints once, because an empty master data source still prints one detail.
  - **GroupHeader1** (no group fields, `RepeatEveryPage=true`):
    - `lblDate`: "MonthName / Year".
    - Header row, in order:
      1. **Employee** (الموظف)
      2. **Department** (الادارة)
      3. **Job** (الوظيفة)
      4. **Signature** (التوقيع)
  - **Detail1**, one row per PR_Salaries row:
    1. `PR_Salaries.EmployeeName`
    2. `PR_Salaries.DepartmentName` (the employee's **current** department, `PR_Employee.DepartmentId`)
    3. `PR_Salaries.JobName`
    4. An empty cell for the signature
  - **GroupFooter1:** signature lines "Accounting Manager" (مدير الحسابات) and "Excutive Manager" (المدير التنفيذي).
- **Not shown:** amounts, totals, Serial and the employee number. This is a **signature sheet**. It prints no money values.

**Layout source at runtime:** `ReportView.cshtml` calls `GetReportLayoutByNameAndLanguage(Model.GetType().Name, culture)`:
- The lookup key is the **class name** `rptSalarySignature`, not the `Name` property.
- It reads `dbo.ACFX_ReportLayout` with `WHERE Name=@Name AND UserId=@UserId AND Language=@Language`. That is a **per-user** custom design saved through the MVC "View designer".
- If no row exists, the compiled designer layout described above is used.
- A user may therefore have a customized layout that shows other columns.

### e. Cloud DB dependencies
See the combined table below. Every object exists on `origin/Master_Stable`.

### f. Route ModuleId and permission
- Front route `salary-report` has `canActivate: [CanActivateRouteGuard, AccflexAuthGuard]` and **no `data.ModuleId`**.
- `CanActivateRouteGuard` (`projects/payroll/src/app/core/interceptors/can-activate/can-activate-route.guard.ts`) looks up `UserPermissions…find(ModuleId === undefined)`, so **non-admin users are always denied**. Only users with the admin role from the JWT get in.
- The server menu entry is `WebMenuItem.Employee_Salaries` (`"8_1_1"`, `Module.EmployeeSalarieReport` = **514**, "Salaries Receives" / "رواتب الموظفين", route `accounting-reports/salary-report`).
- The home quick-tile "Monthly salary / المرتب الشهرى" (`core/components/home/home.component.ts:91`) also links to this route.

### g. Risks
See the combined list at the end. The ones specific to report 1:
- It prints all salary rows of the month, **including unposted and vacation salaries** and multiple SalaryMain runs in the same month, so one employee can appear more than once.
- Department is the employee's current department, not `PR_Salaries.DepartmentId`.
- The name is always `EmployeeName`, with no Arabic-name switch.
- Row order is undefined because there is no ORDER BY.

---

## Report 2: Employee Summarized Salaries (`EmployeeSalaryDetails` → `rptEmployeeSalaryDetails`)

### a. Input contract
Identical to report 1: `lang`, `employeeIds` (CSV), `month` (ISO DateTime). Only year and month are used.

### b. Controller

```csharp
[Route("mvc/AccountingReports/EmployeeSalaryDetails")]
public IActionResult EmployeeSalaryDetails(string lang, string employeeIds, DateTime month)
{
    ChangeThreadCulture(lang);
    var report = new Payroll.Reports.Accounting.Salary.rptEmployeeSalaryDetails(month.Year, month.Month, employeeIds);
    return View(REPORTS_ROOT_VIEW, report);
}
```

The constructor is `(int salaryYear, int salaryMonth, string employeesIds)`.

### c. SQL and C# logic

**Constructor:**
- `ReportTitle = isArabic ? "تقرير ملخص رواتب الموظفيين" : "Employee's Summarized Salaries Report"`.
- `Name = isArabic ? "rptEmployeesSummarizedSalariesAreg" : "rptEmployeesSummarizedSalaries"`. This is the `Name` property only; the layout key is still the class name `rptEmployeeSalaryDetails`.

**`rptEmployeeSalaryDetails_BeforePrint`:**
1. Sets RTL when Arabic, and sets the connection string on `pR_SalariesTableAdapter` and `pR_SalaryDetailTableAdapter`.
2. If `employeesIds` is not empty, it calls `pR_SalariesTableAdapter.FillByWhere(PR_Salaries, headerQuery, "")` with this clause (verbatim):
   ```
    INNER JOIN PR_SalaryMain ON PR_SalaryMain.SalaryMainId = PR_Salaries.SalaryMainId Where PR_Salaries.EmployeeId IN ({employeesIds}) AND PR_SalaryMain.IsDeleted = 0 AND PR_SalaryMain.SalaryYear = {salaryYear} AND PR_SalaryMain.SalaryMonth = {salaryMonth} AND Posted = 1 
   ```
   It is appended to the same base SELECT as report 1. The unqualified `Posted` resolves only to `PR_Salaries.Posted`; I checked every joined table in the cloud DB, and none of the others has a `Posted` column.

   Else: `Fill()`, which returns all salaries of all months with no filter.
3. `salaryIds = string.Join(",", PR_Salaries.Select(x => x.SalaryId))`.
4. `detailQuery = salaryIds != "" ? " AND PR_SalaryDetail.SalaryId IN ({salaryIds})" : ""`. It then calls `pR_SalaryDetailTableAdapter.FillByWhere(PR_SalaryDetail, detailQuery, "")`. When the header is empty, this loads **every** salary-detail row with an amount above 0 in the DB. That costs time only; nothing extra prints.

There are no rollups in C#. The totals come from XRSummary in the layout (see d).

**PR_SalaryDetail SELECT** (`dsSalary.xsd`, TableAdapter `PR_SalaryDetail`, verbatim, no parameters):
```sql
SELECT        PR_SalaryDetail.SalaryDetailId, PR_SalaryDetail.SalaryId, PR_SalaryDetail.EmployeeIncomeId, PR_SalaryDetail.IncomeAmount, PR_SalaryDetail.Suspend, 
                         PR_Income.IncomeName, PR_Income.Deduction
FROM            PR_SalaryDetail INNER JOIN
                         PR_Income ON PR_SalaryDetail.EmployeeIncomeId = PR_Income.IncomeId LEFT OUTER JOIN
                         PR_IncomeGroup ON PR_Income.IncomeTypeId = PR_IncomeGroup.IncomeTypeId
                         LEFT JOIN PR_Salaries ON PR_Salaries.SalaryId = PR_SalaryDetail.SalaryId
WHERE        PR_SalaryDetail.IncomeAmount > 0
```

The effective detail query is that SELECT followed by `AND PR_SalaryDetail.SalaryId IN (<salaryIds of the header rows>)`.
- `PR_IncomeGroup` and `PR_Salaries` are joined on their PKs and their columns are not used, so they produce no fan-out.
- Lines with `IncomeAmount <= 0` are **dropped**.
- `Deduction` here is **`PR_Income.Deduction`** (the income definition), not `PR_SalaryDetail.Deduction`.

**DataSet relation:** `FK_PR_SalaryDetail_PR_Salaries` (`PR_Salaries.SalaryId` → `PR_SalaryDetail.SalaryId`) drives the nested band.

The other two adapters in dsSalary are not used by either report:
- `PR_SalaryMain`: `PR_Employee ⋈ PR_Branch` on `BranchManagerId`, right-joined to `PR_SalaryMain`.
- `PR_SalaryDeduction`: `PR_SalaryDetail ⋈ PR_Income WHERE PR_Income.Deduction = 1`.

### d. Printed output (designer layout in `rptEmployeeSalaryDetails.Designer.cs`; no `.repx` on disk, no DB seed)

**Report:** `DataSource=dsSalary1`, `DataMember="PR_Salaries"`.

**Bands:** `ReportHeader` (base company header), `PageHeader`, `DetailReport`, `DetailMain` (base, height 0), plus margins.

The class also declares a `Detail` band with "Salary For" (unbound) and "Salary Date" (bound to `PR_SalaryMain.SalaryDate {0:dd/MM/yyyy}`, which is never filled). That band is **not** in `Bands.AddRange`, so it does not print.

- **PageHeader:** `lblReportTitle` = "Employee's Summarized Salaries " / "ملخص رواتب الموظفيين".
- **DetailReport** (`DataMember="PR_Salaries"`, no own DataSource, so it inherits the report's):
  - **GroupHeader1** (no group fields, `RepeatEveryPage`). Header row, in order:
    1. **Code** (الرقم)
    2. **Employee** (اسم الموظف)
    3. **Job** (الوظيفة)
    4. **Additions** (الاضافات)
    5. **Deductions** (الاستقطاعات)
    6. **Total** (الاجمالي)
  - **Detail1**, one row per PR_Salaries row (`KeepTogether`, `KeepTogetherWithDetailReports`):
    1. `EmployeeNumber`
    2. `EmployeeName`
    3. `JobName`
    4. `TotalAdditions {0:0.00}`
    5. `TotalDeductions {0:0.00}`
    6. `Total {0:0.00}`

    All three amounts are the **stored** `PR_Salaries` columns. Nothing is recomputed.
  - **DetailReport1** (`DataMember="PR_Salaries.FK_PR_SalaryDetail_PR_Salaries"`): the nested income lines of that salary.
    - **GroupHeader2** (`RepeatEveryPage`). Header row:
      1. **Income** (البند)
      2. **Amount** (القيمة)
      3. **Deduction** (الاستقطاع)
    - **Detail2**, per salary-detail line:
      1. `IncomeName`
      2. `IncomeAmount {0:0.00}`
      3. CheckBox bound to `Deduction` (from PR_Income)
  - **GroupFooter2**, printed once after all employees:
    - **Grand Totals** (الاجمالي) row with three `XRSummary` cells, each `Sum`, `Running=Report`, format `{0:0.00}`:
      - Σ `PR_Salaries.TotalAdditions`
      - Σ `PR_Salaries.TotalDeductions`
      - Σ `PR_Salaries.Total`
    - Signature lines "Accounting Manager" and "Excutive Manager".
- There are **no per-line totals** for the income lines and **no currency grouping**: the grand totals add up mixed currencies.

**Layout source:** same mechanism as report 1. `dbo.ACFX_ReportLayout` is looked up by class name `rptEmployeeSalaryDetails`, UserId and Language, with a fallback to the compiled designer. When a DB layout exists, `ReportView.cshtml` also re-assigns `DataSource` on the top-level `DetailReport` bands.

### e. Cloud DB dependencies
See the combined table below.

### f. Route ModuleId and permission
- Front route `salary-details-report` has `data: { ModuleId: 537 }` with `CanActivateRouteGuard` and `AccflexAuthGuard`.
- Menu entry: `WebMenuItem.Employee_Summarized_Salaries` (`"8_1_2"`, `Module.EmployeeSummarizedSalariesReport` = **537**, "Employee Summarized Salaries" / "مرتبات الموظفين ملخص").
- Module.cs (cloud, line 486) puts 537 in group "Accounting Report".

---

## e. Cloud DB dependency table (`AccFlex_Cloud_Database`, `origin/Master_Stable`, root `AccFlex_Cloud_Database_State/AccFlex_Cloud_Database_State/`)

| Object | Used by | Exists | Path | In .sqlproj | Notes vs legacy expectation |
|---|---|---|---|---|---|
| `dbo.PR_Salaries` | 1, 2 | Y | `dbo/Tables/PR_Salaries.sql` | Y | Has every column the legacy reads. `Total`, `TotalAdditions`, `TotalDeductions` and `InsuranceCompany` are MONEY NOT NULL; `Posted` is BIT NOT NULL. The cloud table also has `BasicSalary, Paid, TotalTax, TotalMartyrsandVictimsFundTax, EmployeeTransactionId, SickLeaveAccrualNote, DepartmentId` (salary-time department), which the legacy ignores. |
| `dbo.PR_SalaryMain` | 1, 2 | Y | `dbo/Tables/PR_SalaryMain.sql` | Y | `SalaryMonth`/`SalaryYear` are INT NOT NULL and `IsDeleted` is BIT NOT NULL DEFAULT 0, so `<> 1` and `= 0` are equivalent. `IsVacationSalary` exists and **the legacy does not filter on it**. |
| `dbo.PR_SalaryDetail` | 2 | Y | `dbo/Tables/PR_SalaryDetail.sql` | Y | `IncomeAmount` is MONEY. It has its own `Deduction` and `UserAmount` columns, but the legacy uses `PR_Income.Deduction`. |
| `dbo.PR_Income` | 2 | Y | `dbo/Tables/PR_Income.sql` | Y | `IncomeName`, `Deduction` and `IncomeTypeId` are present. |
| `dbo.PR_IncomeGroup` | 2 | Y | `dbo/Tables/PR_IncomeGroup.sql` | Y | Joined on its PK `IncomeTypeId`, so there is no fan-out. Its columns are unused, so a port can drop the join. |
| `dbo.PR_Employee` | 1, 2 | Y | `dbo/Tables/PR_Employee.sql` | Y | All ~80 columns referenced by the base SELECT exist (checked one by one). The printed reports only need `EmployeeId, EmployeeName, EmployeeNumber, JobId, DepartmentId`. `EmployeeSecurityLevel` exists but the legacy does not use it. |
| `dbo.PR_Job` | 1, 2 | Y | `dbo/Tables/PR_Job.sql` | Y | `JobName` |
| `dbo.PR_Department` | 1 (printed), 2 (unused) | Y | `dbo/Tables/PR_Department.sql` | Y | Legacy joins on `PR_Employee.DepartmentId`. |
| `dbo.Acc_Currencies` | 1, 2 (not printed) | Y | `dbo/Tables/Acc_Currencies.sql` | Y | The legacy uses `Acc_Currencies`. The precedent TVF uses the different table `Acc_Currency`. |
| `dbo.PR_EmployeeGroup` | not printed | Y | `dbo/Tables/PR_EmployeeGroup.sql` | Y | `EmployeeGroupName`, `EmployeeGroupNameSecondLanguage` |
| `dbo.PR_Projects` | not printed | Y | `dbo/Tables/PR_Projects.sql` | Y | |
| `dbo.PR_Branch` | not printed | Y | `dbo/Tables/PR_Branch.sql` | Y | |
| `dbo.PR_EduDegree` | not printed | Y | `dbo/Tables/PR_EduDegree.sql` | Y | |
| `dbo.Pr_Qualifications` | not printed | Y | `dbo/Tables/Pr_Qualifications.sql` | Y | `QualifationName` (STUFF/FOR XML subquery) |
| `dbo.PR_SystemConfiguration` | header (rptMainReport) | Y | `dbo/Tables/PR_SystemConfiguration.sql` | Y | Company logo, name, email, fax, tel, address. |
| `dbo.ACFX_ReportLayout` | legacy layout store | Y | `dbo/Tables/ACFX_ReportLayout.sql` | Y | The legacy MVC reads `Name/UserId/Language` here. It is the **same table** the cloud uses, not a separate system (contrary to legacy-anatomy.md §6). Legacy keys are `rptSalarySignature` and `rptEmployeeSalaryDetails`. The cloud table adds `IsMobile, ModulePermissionId, ApplicationId, IsSystemLayout`. |
| `dbo.Acc_ConvertIntListToTable` | (for the port) | Y | `dbo/Functions/Acc_ConvertIntListToTable.sql` | Y | CSV → `int`. A NULL list becomes `'0'`, which matches no rows. |
| `dbo.PR_EmployeeTotalSalariesReport` (precedent) | n/a | Y | `dbo/Functions/PR_EmployeeTotalSalariesReport.sql` | Y | See the reuse analysis below. |
| `dbo.PR_MonthlySalaryPrint` (sibling) | n/a | Y | `dbo/Functions/PR_MonthlySalaryPrint.sql` | Y | See the reuse analysis below. |

**No procs, functions or views are called by the legacy SQL.** It is plain table SQL, and every table exists. Nothing is missing.

## Reuse against `dbo.PR_EmployeeTotalSalariesReport` (and siblings)

`PR_EmployeeTotalSalariesReport(@Month, @Year, @SecurityLevel, @EmployeeIds, @InServiceFilter)` is a port of proc `Pr_EmployeeTotalSalaries`. Its semantics differ from both reports in five ways:
- It **pivots `PR_SalaryDetail` by IncomeId**, and its `TotalAdditions`, `TotalDeductions` and `NetSalary` are **recomputed** from fixed income IDs. Report 2 prints the **stored** `PR_Salaries.TotalAdditions`, `TotalDeductions` and `Total`.
- It filters `PR_SalaryMain.IsVacationSalary = 0`. Neither legacy report does.
- It does **not** filter `IsDeleted` or `Posted`. Report 2 requires `IsDeleted = 0 AND Posted = 1`; report 1 requires `IsDeleted <> 1`.
- It applies `EmployeeSecurityLevel <= @SecurityLevel`. Neither legacy report does.
- It uses `Acc_Currency` and the employee's current department, and orders by currency, department and employee number.

**Conclusion: do not compose over it.** The numbers would differ. Reuse only its conventions:
- the parameter shape `@Month, @Year, @EmployeeIds` (CSV via `Acc_ConvertIntListToTable`);
- the `RowNo` and `EmployeeNumberInt` sort pattern;
- the base tables `PR_Salaries ⋈ PR_SalaryMain ⋈ PR_Employee`.

`dbo.PR_MonthlySalaryPrint(@SalaryMainId, @IsArabic)` is the closer sibling: stored `TotalAdditions`, `TotalDeductions` and `Total`, plus `Posted`, `JobName` and `Acc_Currencies`. It is still not reusable as-is, for three reasons:
- It is keyed by `SalaryMainId`, not by month and employee list.
- It switches the name to `EmployeeArabicName` when `@IsArabic`.
- Its department is `ISNULL(PR_Salaries.DepartmentId, PR_Employee.DepartmentId)`.

The legacy reports always use `EmployeeName` and the department from `PR_Employee.DepartmentId`.

A faithful port is two new TVFs, or one TVF plus a detail TVF for report 2, written directly over the base tables with the exact legacy predicates.

---

## g. Ambiguities and risks for a 1:1 reproduction (both reports unless noted)

1. **Security level.** The legacy SQL has no `EmployeeSecurityLevel` filter, and the employee picker uses `IgnoreQueryFilters()`. Any user who can open the screen sees every employee's salary, including managers'. Report 2 prints the amounts.
   - The precedent TVF and `PR_MonthlySalariesDetailedReport` filter `<= @SecurityLevel`.
   - **Decision needed:** keep the legacy behaviour (identical numbers) or add the filter (secure, but it can drop rows compared with the MVC output).
2. **Empty `employeeIds`.** The legacy `Fill()` returns every salary row of **every month** in the DB. The UI never sends an empty list, because it substitutes all picker employees. A TVF with `NULL` employee IDs should not copy this; the `Acc_ConvertIntListToTable(NULL)` case also needs a decision.
3. **"All employees" is the picker list, not "no filter".** It covers all employees with `HiringDate <= today` (in-service and terminated), sent as a long CSV. In the port, decide whether an unselected picker means `NULL` (no employee filter). Results only match if every salaried employee in the month is in that list, i.e. was hired by today.
4. **Multiple salary rows per employee per month.** Neither report filters `IsVacationSalary` or groups by SalaryMain, so an employee with a regular and a vacation salary, or with salary runs by branch or department, appears twice. Reproduce this; do not de-duplicate.
5. **Posted.** Report 2 shows only posted salaries (`Posted = 1`). Report 1 shows posted and unposted.
6. **Row order is undefined.** There is no ORDER BY and no SortFields in either layout, so the order is whatever the SQL plan returns (usually PR_Salaries clustered-index order). Pick and document an explicit order, e.g. `SalaryId` or `EmployeeNumber`. A row-by-row diff should then compare as sets.
7. **Report 2 band binding: must be verified live.**
   - Both the report's DataMember and the DetailReport's DataMember are `"PR_Salaries"`, and the DetailReport has no DataSource of its own unless a DB layout exists, in which case ReportView assigns one.
   - Static reading cannot settle whether DevExpress prints the employee list once or once per master row (N× repetition).
   - Capture a real MVC print with 2 or more employees before you lock the expected output.
   - Report 1 has no such issue. Its master `PR_SalaryMain` is empty, so the detail list prints once.
8. **Per-user custom layouts.** `ACFX_ReportLayout` rows (`Name='rptSalarySignature'` or `'rptEmployeeSalaryDetails'`, per `UserId` and `Language`) may override the designer layout for some users. Run `SELECT Name, UserId, Language, DesignName FROM ACFX_ReportLayout WHERE Name IN ('rptSalarySignature','rptEmployeeSalaryDetails')` on a tenant to see whether customers print extra columns, e.g. the C#-computed `Serial` in report 1. The cloud store is the same table, so choose new layout names that cannot collide with these keys.
9. **Detail-line filter (report 2).** Only `IncomeAmount > 0` is kept, so zero and negative lines are hidden. The checkbox shows `PR_Income.Deduction`, not `PR_SalaryDetail.Deduction`. The two can differ if an income's Deduction flag changed after the salary was issued.
10. **Rounding and format.** Every amount is MONEY (4 dp), displayed `{0:0.00}`. The grand totals sum the **unrounded** values and then format them. Return raw MONEY from the TVF and format only in the layout. Do not ROUND in SQL.
11. **Mixed currencies.** Report 2's grand totals add `Total` across currencies with no grouping. Reproduce this, or flag it as a business change.
12. **Department and name semantics (report 1).** Department is the employee's **current** department, not `PR_Salaries.DepartmentId`. The name is always `EmployeeName`, even in Arabic. The newer cloud TVFs use `ISNULL(PR_Salaries.DepartmentId, …)` and the Arabic-name switch; do not copy those if the goal is identical output.
13. **Month parsing.**
    - The front sends local wall-clock time with a `Z` suffix, and the MVC binds it into a `DateTime`. If the server's timezone is behind UTC and the picked value is the 1st at 00:00, the month could shift. This is low risk, because the default is today plus the current time.
    - The new screen should send integer `Month` and `Year`, or a `yyyy-MM-dd` date, so the issue disappears.
14. **Route permission bug (report 1).** `salary-report` has no `data.ModuleId`, so the guard denies every non-admin. The new route should use `data: { ModuleId: 514 }`, matching the menu. Confirm this behaviour change with the PO.
15. **Header.** The company header comes from `PR_SystemConfiguration`, plus the "PC:"/"User:" labels, the page "Page x of y" and the print date-time. The report-1 month label is a culture month name plus the year (`en` or `ar-EG`).
16. **SQL injection.** `employeeIds` is string-formatted into the SQL. A parameterized TVF port fixes this; it is not a parity concern.
