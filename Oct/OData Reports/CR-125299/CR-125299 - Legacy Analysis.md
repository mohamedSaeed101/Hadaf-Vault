# CR 125299 — MVC → OData migration of 4 HR reports: legacy inventory (Step 1)

Skill: mvc-to-odata-report-migration. Template: cr125294 (worktrees\cr125294; DB objects on origin/cr125294).
Vault D:\accflex-features absent on this machine → no vault notes.

## Decisions (user, 2026-10-14)
- Screen: grid + print (report-grid with grid, Excel/PDF export, seeded .repx) — same as cr125294, NOT printOnlyMode.
- Fidelity: same numbers as legacy; fix only display bugs (Medical empty employee headers + serial gaps, Risk crash on missing vacation row). List each in the PR.
- Branch: user sets up Merge Desk (MERGEDESK_ADO_PAT in .env.local) first; then create ticket/branch via Merge Desk, then new-cr.ps1.
- Security level: filter only where legacy did (Employee Save). Not for Medical / Statistics / Risk.
- Size: L → plan gate before implementation.

## cr125294 pattern to copy
TVF in dbo\Functions (+ .sqlproj) → entity ODataViews\Payroll\<X>Rpt\<X>.cs (long RowNo key, nullable cols)
→ config ODataViewsConfigurations\Payroll\... (HasKey(RowNo), ToFunction) → DbSet in Models\DataContext.cs
→ AngularReports\Payroll\...\<X>RptAng.cs (IAngularReport, ReportName=nameof(T), FromSqlInterpolated TVF, empty on parse fail, Parameters dict)
→ PayrollOdataController action [Route("odata/<X>")] + ModuleIds enum + PermissionModuleId + ViewPolicy
→ Front: report-grid [ApplicationId]="4", endpoint==ReportName, QueryOptions on OnPreviewClick, i18n block in {ar-EG,en-US}\payroll.json, route data ModuleId
→ ReferenceDataScripts\04xx_PR_...Layout.sql: EXEC dbo.InsertLayout ar-EG + en-US, ApplicationId=4.

## 1. Medical Insurance — /mvc/HrReports/EmployeesMedicalInsurance (web human-resource-reports/insurance-report)
- Controller HrReportsController.cs:104-129; params lang, selcetedEmplyeesIds (CSV; web always sends all ids if empty), cardReceive 0=all/1=true/2=false.
- Report AccFlex_ERP\HRManagement\Payroll.Reports\HR\EmployeesMedicalInsuranceReport\rptEmployeesMedicalInsurance.cs; xsd dsEmployeeMedicalInsurance.xsd.
- SQL: Employees (PR_Employee.* + PR_Department INNER, PR_Branch/PR_Job/PR_Projects LEFT, @employees NULL or IN Acc_ConvertIntListToTable);
  PR_MedicalInsurance (cols MedicalInsuranceId, MedicalInsuranceType, Name, Age, InsuranceAmount, RelativeRelation, CardRecieved, InsurancePercentage, employeeId, ChildId, InsuranceCompanyName, InsuranceEndDate, CardNumber) INNER PR_Employee, same id filter, AND (InsuranceEndDate IS NULL OR > GETDATE()).
- C#: Serial = global ++counter in row order; Detail_BeforePrint cancels rows where CardRecieved != filter.
- Layout (Designer.cs, A4 landscape): per-employee header (Employee, Emp Number, Department, Branch, Job) + detail cols Serial, Name, Age, Relation, Insurance Type, Insurance Amount, Card (checkbox), Company, End Date dd/MM/yyyy, Card No. No totals.
- Target: flat TVF one row per insurance line with employee fields; card filter in SQL; ROW_NUMBER serial (display fix: no gaps, no empty employees).

## 2. Employee Save — /mvc/HrReports/EmployeeSaveReport (web human-resource-reports/employee-save-report)
- Controller :388-394; params lang, employeeIds (CSV, null=all). rptEmployeeSaveRpt.cs; dsEmployeeSaveRpt.xsd:15-43.
- SQL: Pr_EmployeeSave LEFT PR_Employee emp, LEFT PR_Employee mgr; RowNo ROW_NUMBER over EmployeeSaveId; IsReturnedStr via @isArabic;
  WHERE emp.EndWork=0 AND emp.EmployeeSecurityLevel <= @empSecurityLevel AND (@employeeIds IS NULL OR IN list).
- No C# math. Layout cols: #, Save Name, Employee Name, Manager, Description, Save Date, Is Returned, Return Date. No totals.

## 3. Employee Statistics — /mvc/HrReports/EmployeeStatistics (web employee-statistics)
- Controller :75-82; params lang, fromDate (00:00), toDate (23:59:59.997), employeeIds CSV.
- Procs dbo.Pr_GetEmployee_Statistics(@employeeIds,@dateFrom,@dateTo) and dbo.Pr_GetEmployee_Vacation_Statistics(@employeeIds,@dateTo) (Stored Procedures\*.sql) → port to TVFs.
- C#: parent VacationBalance = SUM(child VacationBalance) per employee.
- Known legacy oddity (keep, same numbers): vacation proc groups by VacationDays.
- Layout: master row Employee, Advance/Purchase/Bonus/Penalty/Vacation Count, Vacation Balance; detail per vacation type (type name, balance). Front already has a grid via Payroll API EmployeeStatisticsService.

## 4. Risk Analysis — /mvc/HrReports/RiskAnalysis (web risk-analysis-settlements, ModuleId 343)
- Controller :84-94; params lang, EmployeeIdList CSV, RiskDate (MinValue→Now).
- rptRiskAnalysis.cs BeforePrint 42-138; dsRiskAnalysis.xsd. Adapters: PR_Employee (×currency via DISTINCT IncomeCurrency CTE), PR_EmployeeIncome (SelectSeparateInsuranceItem filter), Pr_EndServicePolicyDetail, Pr_IncomeEndServicePolicyDetail, proc Pr_VacationBalance(@EmployeeIds, vacDate=end of previous month, NULL, @IsArabic).
- C# math: salary=Σ IncomeAmount where StartDate<=atDate & currency match; DateDifference calendar y/m/d (Payroll.Reports\Helper\DateDiffrence.cs);
  NetYears = Years + 1 if (D>0||M>0) && span>90d; Risk = round(salary*2,2) if span>90d; Compensation = round(Σ policy-band incomes * BounsMonthesPerYear * YearsOfWork, 0) by stage WorkingYearsFrom<=yrs<=To;
  VacationBalance = round(21/12*vacDate.Month - PaidVactions + max(0, VacationBalance-21), 2); Vacations = round(salary/30*VacationBalance, 2); Total = Risk+Others+Compensation+Vacations (Others never set — CHECK its DefaultValue / legacy output).
- Layout landscape, group by CurrencyId with per-currency totals (Compensation, Risk, Vacations, Total). 13 cols.
- Display fix: no crash when vacation row missing (treat as 0).
