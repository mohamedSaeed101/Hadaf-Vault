---
type: analysis
cr: 125307
updated: 2026-10-15
---

# Legacy prints — dissection (explorers, 2026-10-15)

Paths relative to `C:\Hadaf_Work\AccFlex_ERP`. HRS = `AccFlexContainer\AccFlexContainer.MVC\Controllers\PayrollReports\HRScreensController.cs`; PR = `HRManagement\Payroll.Reports`.

Common: action → `ChangeThreadCulture(lang)` → `View(REPORTS_ROOT_VIEW, report)`. Arabic from `MainConfigrationData.IsArabic` (thread culture), not a param. Layout DB-overridable by the report `Name`. No tafqeet. Totals are layout summaries unless noted. `C:\Work\Hadaf\ReportLayout` not present on this machine — layouts read from `.Designer.cs`.

## 1. HRScreens/EmployeeIncome (Salary Items) — one employee's income list
- HRS:124 `EmployeeIncome(lang, int EmployeeId)` → `rptEmployeeIncomeDetails(EmployeeId.ToString())` PR\HR\EmployeesFinancials\rptEmployeeIncomeDetails.cs:9-47; Name `rptEmployeeIncomeDetails`/`…Areg`; title "Employees Salaries Items" / "مفردات مرتبات الموظفين". No C# math.
- SQL `PR_Emp_Income` (dsEmployeeFinance.xsd, `@empIds`, `@IsArabic`): EmployeeIncome {Id, EmployeeId, IncomeId, IncomeCurrency, IncomeAmount, IncomeStartDate, IncomeTaxRoleId, SocialInsuranceRoleId, EmployeeInsuranceAmount, CompanyInsuranceAmount}, CurrencyName, IncomeName, Deduction, EmployeeName (ar/en), SocialInsuranceRole, Department, Job, Branch, DateOfWork, EmployeeNumber, IDNumber, ProjectName — PR_Branch ⋈ PR_Employee ⋈ Dept ⋈ Job ⟖ PR_EmployeeIncome ⟕ PR_SocialInsurance ⟕ PR_Income ⟕ Acc_Currency ⟕ PR_Projects — WHERE employee in `Acc_ConvertStringListToTable(@empIds)` (or All/AllInService/AllTerminated) AND IncomeEndDate IS NULL.
- Note: INNER joins to Branch/Department/Job → an employee missing one of those prints nothing (must be reproduced).
- Layout: logo, title; group header Employee, Code, Job, Department, Branch, Date Of Work; detail Income, Amount, Currency, Start Date, Insurance Policy, Insurance Amount; no totals/signatures.

## 2. HRScreens/EmployeeAllowance (Employee Allowances) — single document + detail
- HRS:25 `(lang, int employeeAllowanceId)` → `rptEmployeeAllowance(id)` PR\Accounting\EmployeeAllowance\rptEmployeeAllowance.cs; Name `rptEmployeeAllowance` (no Areg, no IReportLayoutProvider). No C# math.
- Header SQL (dsEmployeeAllowance.xsd:15): EmployeeAllowanceId, TypeName (ar/en), CurrencyName (ar/en), SerialNumber, AllowanceDate, CreatedBy, CreatedOn, ModifiedBy, LastModifiedOn, HistoricalSeverancePackage ✓/X.
- Detail SQL (:65): CTEs EmployeeDetails / LastTransactionDate (prior docs of same type+currency, date ≤ current) / AccumulatedBalances (Σ ApprovedAmount, date ≤ current, **no type/currency filter** — reproduce as-is) → Serial, EmployeeName, WorkDate, AccrualAmount, AllowanceDays, ApprovedAmount, TransactionDate, LastTransactionDate, AccumulatedBalance, DateOfWork.
- Layout: logo, "Employee Allowance"; header Document NO, Allowance Type, Document Date, Created By, Creation Date, Last Modified By, Modification Date, Historical Severance Package; detail Serial, Employee, Hiring Date, Last Accrual Date, Accrual Amount, Allowance Days, Accumulated Balance, Approval Amount, Effective Notice Date; footer totals (4 summaries).

## 3. HrReports/AllowanceSerial (Allowances) — single document + detail
- HrReportsController.cs:23 `(lang, int allowanceId)` → `rptAllowanceSerial` PR\HR\Allowance\rptAllowanceSerial.cs; Name `rptAllowanceSerial`/`…Areg`; currency cell ar/en rebind.
- **C#**: `AllowancePercentage /= 100` when IsPercentage (display format percent) → in SQL return the stored value and format in layout, or divide in SQL to keep the same printed figure.
- Header SQL (dsAllowanceSerial.xsd:15): PR_Allowance.*, EmployeeName (ar/en), CurrencyName/Arabic, ReceivedToEmployee ✓.
- Detail SQL (:68): AllowanceTypeId, AllowanceValue, Description, IsPercentage, AllowancePercentage, Incomes (STUFF/FOR XML of PR_Income names via PR_AllowanceIncomeDetail), AllowanceTypeName.
- Layout: "Allowances"; header Serial, Currency Factor, Allowance Date dd/MM/yyyy, Currency, Employee, Description, Journal Number, ReceivedToEmployee; detail Allowance Type, Amount n2, Notes, Percent, Income Type; footer Total = Σ AllowanceValue.

## 4. HRScreens/Bonus — single document (one row)
- HRS:201 `(lang, int bonusId)` → `Payroll.Reports.HR.EmployeeBonus.rptEmployeeBonus` (not the Accounting one); Name `rptEmployeeBonus`/`…Areg`; BonusTypeName and Currency rebound ar/en in C#.
- SQL (dsEmployeeBonus.xsd, `@EmployeeBonusId`): EmployeeBonusId, SerialNumber, EmployeeNumber, EmployeeName (**English only — no ar CASE**), BonusName, BonusDate, BonusTypeName/SecondLanguage, BonusAmount, CurrencyName/Arabic, Paid, BounsTotalValue, Description, IDNumber, Nationality, ManagerName — PR_EmployeeBonus ⋈ PR_Employee ⋈ Acc_Currency ⋈ PR_Bonus ⟕ PR_EmployeeBonusType ⟕ PR_Nationality ⟕ manager.
- Layout: logo, "Employee Bonus"; Employee Code, Employee Name, Serial Number, Bonus Type, Bonus Date, Bonus Amount Type, Bonus Value 0.00, Currency, Paid; no totals.

## 5. HRScreens/EmployeeAdvance — single voucher
- HRS:42-49, params `lang, int advanceId`. `rptEmployeeAdvance(int)` PR\HR\EmployeeAdvance\rptEmployeeAdvance.cs:56; Name `rptEmployeeAdvanceMain`/`…Areg`.
- `employeeAdvanceTableAdapter.FillBy(advanceId, IsArabic)`; `pR_AdvanceRepaymentTableAdapter.Fill()` (all rows, relation filters).
- SQL (dsEmployeeAdvance2.xsd:77-117): EmployeeId, EmployeeName (ar/en CASE), EmployeeNumber, AdvanceAmount, Acc_Currency.EnglishLetter, AdvanceAmountCurrency, Discription, NoRepayment, Approved, ApplayingStartDate, ApproxEndDate, Returned, IsAdvance, AdvanceId, Age, RequestDate, DepartmentName, BranchName, EmployeeArabicName — FROM Acc_Currency ⋈ PR_Advance ⋈ PR_Employee ⟕ PR_Department ⟕ PR_Branch WHERE AdvanceId=@AdvanceId.
- Repayments (:169-196): RepaymentId, AdvanceId, PaymentDate, Amount, PaidDate, Paid, Amount AS PaiedAmount, PaidInSalaryMainId FROM PR_AdvanceRepayment ⟕ PR_SalaryMain.
- Layout: title "Employee Advance", logo; header Code, Start Date, Request Date, Amount `0.00`, Currency, No of Payments, Employee, Description, Payment End Date, Confirmed ☐; detail Payment Date, Payment Amount n2, Paid Amount n2, Paid Date, Is Paid ☐; footer Total = Σ Amount.

## 6. HRScreens/EmployeePurchase — single voucher
- HRS:131-137, `lang, int purchaseId`. `rptEmployeeDeduction(int)` PR\HR\EmployeeDeductions\rptEmployeeDeduction.cs:25; Name `rptEmployeeDeduction`/`…Areg` (no IReportLayoutProvider).
- BeforePrint: Currency cell bound to EnglishLetter (en) / ArabicLetter (ar).
- SQL FillByPurchaseId (dsEmployeeDecucations.xsd:75-118): EmployeeId, EmployeeName (ar/en), ProjectName, DepartmentName, JobName, BranchName, PurchaseAmount, EnglishLetter, ArabicLetter, RequestDate, PurchaseAmountCurrency, Discription, NoRepayment, Accepted, ApplayingStartDate, ApproxEndDate, Returned, PurchaseId — PR_Employee ⟕ PR_Purchase ⟕ Acc_Currency ⟕ PR_Projects(DefaultProjectId) ⟕ Dept ⟕ Job ⟕ Branch WHERE PurchaseId=@PurchaseId.
- Repayments (:158-177): RepaymentId, PurchaseId, PaymentDate, Amount, PaidDate, Paid, PaiedAmount, PaidInSalaryMainId FROM PR_PurchaseRepayment WHERE PurchaseId IN iter$simple_intlist_to_tbl(@PurchaseId).
- Layout: title "Employee Purchase", no logo control found; header Code (EmployeeId), Start Date, Request Date, Amount `0.00`, No of Payments, Currency, Employee, Description, Approved ☐, Payment End Date; detail as advance; footer Total = Σ Amount.

## 7a. HRScreens/SalaryExchange — single document (header + employee lines)
- HRS:185-191, `lang, int salaryExchangeId` (= PayingSalariesId). `rptPayingSalariesReport(int)` PR\Accounting\Salary\rptPayingSalariesReport.cs:34. Name/RTL logic looks inverted (Name `rptPayingSalariesReport` when Arabic, `… ar-EG` when English; RTL set when NOT Arabic).
- SQL (dsPayingSalary.xsd:15-104): CTE defaultBank (first PR_EmployeeBank per employee) → PayingSalariesId, BankName, TypeName/TypeNameSecondLanguage, Serial, Description, CurrencyName/CurrencyNameArabic, TotalSalaries, PayingSalariesMonth, PayingSalaryYear, PayingSalariesDetailId, EmployeeName (ar/en), EmployeeSalary, PayingSalariesDate, EmployeeArabicName, EmployeeNumber, CAST AS BIGINT, AccountNo — Pr_PayingSalaries ⟕ PR_Bank ⟕ Acc_Currency ⋈ Pr_PayingSalariesDetail ⟕ PR_Employee ⟕ PR_TransactionType ⟕ defaultBank(num=1) WHERE PayingSalariesId=@id.
- Layout: title "PayCheck"; labels Employee, Salary, Currency, Exc. Destination, Month, Year, Total Salaries; no logo found. Detail column order **not yet confirmed**.

## 7b. AccountingReports/BankSalaryPrint — list (one bank / month / currency)
- AccountingReportsController.cs:101-108 `lang, bankId, int? currencyId, string employeeIds, DateTime month`; variant `BankSalaryPrintWithPayingSalaryId` :109-116 (+payingsalaryid). The payments-request front passes `payingsalaryid` → check which action the route resolves to.
- `rptBankSalaryPrint` PR\Accounting\Salary\rptBankSalaryPrint.cs; Name `rptBankSalaryPrint`/`…Areg`; title "Payment Authority Salary" / "مرتبات جهة الصرف". C#: RowNumber = index+1.
- SQL (dsBankSalaryPrint.xsd:15-129): from `Vw_SalaryHeader` ⟕ PR_Employee, Suspend=0, security level, BankId, month/year, currency, employeeIds (`Acc_ConvertStringListToTable`); Basic (IncomeId 1), Housing (3), Other (Σ other) from PR_EmployeeIncome (respecting `PR_SystemConfiguration.SelectSeparateInsuranceItem`). FillBy adds ⋈ Pr_PayingSalaries on BankId AND PayingSalariesId=@id.
- Layout: group BankName + SalaryDate `MMMM/yyyy`; columns RowNo, AccountNo, ID Number, Branch, Currency, Department, Description, Employee Name, Salary (Total). Orientation must not change (banks use it).

## 8. HRScreens/EmployeeAccrual — one employee statement, grouped by currency
- HRS:162-168, `lang, int employeeId`. `rptEmployeeAccrual(int)` PR\Accounting\EmployeeAccrual\rptEmployeeAccrual.cs:25; Name `rptEmployeeAccrual`/`…Areg`.
- Header adapter EmployeeCurrencyTransaction (dsEmployeeAccruals.xsd:83-224): per currency — EmployeeId, Nationality, EmployeeName, CurrencyId/Name, StartDate = ISNULL(ContractStartDate, DateOfWork); totals by TransactionTypeId: Salary {4,10,11,14}, Paid {7,8,9,12,13,15}, PreviousAccrued {1}, Severance {2,6,10,11}, Vacation {3,5,10,11}; TotalAccural = Prev+Salary+Vacation+Severance; Net = TotalAccural − Paid.
- **C#**: WorkLength Days/Years/Months from `DateDifference(StartDate, DateTime.Now)` → must be reproduced in SQL (same algorithm).
- Detail adapter EmployeeAccruals (:15-76), one fill per currency: EmployeeTransactionId, TypeName, Accrual/Paid label (ar/en), TransactionAmount, TransactionDate, Description, CurrencyName, JournalSerial — PR_EmployeeTransactions ⋈ Acc_Currency ⟕ Acc_Journal(GuidNumber) ⋈ PR_TransactionType WHERE EmployeeId, CurrencyId ORDER BY date DESC, id DESC.
- Layout: title "Employee Accruals", logo; group per currency: Employee, Nationality, Work Date, Working Period (Y/M/D), Total salary `N4`; summary Currency, Prev accrued, Vacation, End of Service, Total Expense, Net `N4`; detail Serial, Transaction, accrual/paid, value `N4`, Date, description, Journal No; footer Total Accruals.

## Still to confirm
- Layout-store lookup (how `Name` maps to a DB-stored layout) — only matters if tenants have customised legacy layouts.
- 7a detail bindings; signature blocks on all.
- tail of the EmployeeCurrencyTransaction FROM/WHERE.
