---
type: analysis
cr: 125294
updated: 2026-10-13
---

# CR-125294 — Legacy analysis (MVC container reports)

The web iframe calls `AccFlex_ERP\AccFlexContainer\AccFlexContainer.MVC\Controllers\PayrollReports\AccountingReportsController.cs`, which builds reports from **`AccFlex_ERP\HRManagement\Payroll.Reports\HR\*`** — a separate copy from the desktop `PayRoll\Accounting\Reports\*` (different signatures, e.g. `inServiceFilter`). The `Payroll.Reports` copy is the source of truth.

## Input contract (Angular shells → iframe URL)

All three used `pay-employee-from-to-form` with `isEmployeeRequired = false`. The form sends `EmployeeList = null` when nothing or "select all" is chosen.

| Report | Params |
|---|---|
| Unpaid | `employeesIds`, `fromDate`, `toDate`, `inServiceFilter`. When the selection equals every in-service (or every terminated) employee under the picker toggle, it sends `inServiceFilter = AllInService / AllTerminated` and **no** employee list |
| Advance | `employeeIds`, `fromDate`, `toDate` |
| Purchase | `employeesIds`, `fromDate`, `toDate` (yyyy-MM-dd) |

## 1. Unpaid advance payments — `rptUnPaidAdvancesPayments`

- Dates: from = 00:00:00, to = 23:59:59. Fill: `(employees, inServiceFilter, from, to)`.
- SQL (`dsEmployeeUnPaidAdvancesPayments.xsd`), per employee:
  - `BeforeDateAmount` = Σ repayment `Amount` where `Paid = 0`, advance `IsAdvance=1, IsPaid=1, Approved=1`, `ApplayingStartDate < @from`
  - `periodPayment` = Σ repayment `Amount` where `Paid = 1`, same advance flags, `@from <= ApplayingStartDate < @to`
  - `periodAdvance` = Σ repayment `Amount` (all), same advance flags, same window
  - `EndDateAmount` = Before + periodAdvance − periodPayment
  - `TotalEmployeeAmount` = Σ `PR_Advance.AdvanceAmount` (all advances, no filter)
  - Inner joins to Department and Branch; employee list filter on `AllAdvances.EmployeeId`; in-service filter on `PR_Employee.EndWork`.
- No C# rollups. Layout: group header/footer, `{0:n2}` totals of Before / periodAdvance / periodPayment / EndDate, record number.

## 2. Employees advance — `rptEmployeeAdvance`

- Dates: `fromDate.Date` .. `toDate.Date + 1 day − 1 s`.
- Header SQL (`dsEmployeeAdvance2.xsd`, `FillByEmployeeID`): `PR_Advance` ⋈ `Acc_Currency` ⋈ `PR_Employee`, left joins Department/Branch/Projects/Job.
  ```
  WHERE (@EmployeeId IS NULL OR @EmployeeId = '')
     OR (EmployeeId IN list) AND (ApplayingStartDate BETWEEN …) AND IsAdvance = 1 AND Confirmed = 1
  ```
  **Precedence bug:** with no employee selected, the date range and the `IsAdvance` / `Confirmed` filters are all skipped, so every `PR_Advance` row is returned.
- Detail: `PR_AdvanceRepayment` (all rows, related by `AdvanceId`), `Amount AS PaiedAmount`.
- Layout: master (employee, number, job, request date, amount, currency, installments, start/end, description) + detail band (payment date, amount, paid, paid date, paid amount).

## 3. Employee purchase — `rptEmployeeDeduction`

- Dates as report 2. Header SQL (`dsEmployeeDecucations.xsd`, `FillBy`): `PR_Employee` LEFT JOIN `PR_Purchase`, currency, projects, department, job, branch.
  ```
  WHERE (@EmployeeId IS NULL)
     OR (@EmployeeId = '' AND PurchaseId IS NOT NULL)
     OR (EmployeeId IN list) AND (ApplayingStartDate BETWEEN …)
  ```
  **Same precedence bug:** with no employee selected, every purchase is returned regardless of date. No `Accepted` filter.
- Detail: `PR_PurchaseRepayment` for the returned `PurchaseId`s, real `PaiedAmount` column.
- Currency letter bound to `ArabicLetter` / `EnglishLetter` by language.

## Cloud DB dependencies

All tables and columns used exist in `AccFlex_Cloud_Database`. `iter$simple_intlist_to_tbl` does not exist in the cloud DB; `Acc_ConvertIntListToTable` is used instead (same int-list semantics).

## ModuleIds (desktop `Module.cs` = cloud `SharedKernel.Logic.Modules.Module`)

- 547 Employee Deduction Report (تقرير المشتريات)
- 549 UnPaid Advanced Payments Report
- 551 Advance Report

Before this CR the three web routes had no `ModuleId`, so `CanActivateRouteGuard` let only admins through.

## Sibling template

`advance-transactions` (`EmployeeAdvanceShellComponent`, `PR_EmployeeAdvanceTransactionsReport`, `EmployeeAdvanceTransactionsRptAng`) is the already-migrated interactive `report-grid`. It takes `SecurityLevel` from a client query option (spoofable); the new reports use the server session instead. Master-detail sibling: `employee-accurals-details-shell`.
