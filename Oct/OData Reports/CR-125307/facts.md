---
type: intake
work_item: 125307
kind: CR
workItemType: Change Request
stagebranch: Stage_Beta
mergeDeskVersion: Beta
repos: [db, erp, front]
parent: 9751 (Feature, New — "مفردات المرتب - Salary Items")
updated: 2026-10-15
---

# CR-125307 — Facts

Title: تحويل طباعة شاشات المرتبات والمستحقات والسلف القديمة الى الطباعة الجديدة
(Payroll / accruals / advance screen prints → the new print)

## Facts — numbered, one source each

| # | Fact | Source |
|---|---|---|
| 1 | 8 Payroll screens still print through the legacy print viewer (`accflex-report-iframe`); their print must move to the new print, **AngularPrints in AnalyticsReader**, with the same document content | description |
| 2 | Salary Items (مفردات المرتب) — route `salary-items` — old endpoint `HRScreens/EmployeeIncome` | description row 1 |
| 3 | Employee Allowances (بدلات الموظفين) — `employee-allowances` — `HRScreens/EmployeeAllowance` | description row 2 |
| 4 | Allowances (البدلات) — `allowances` — `HrReports/AllowanceSerial` | description row 3 |
| 5 | Bonus (المكافآت) — `bonus` — `HRScreens/Bonus` | description row 4 |
| 6 | Advance (السلف) — `advance` — `HRScreens/EmployeeAdvance` | description row 5 |
| 7 | Employee Purchase (مشتريات الموظفين) — `purchase` — `HRScreens/EmployeePurchase` | description row 6 |
| 8 | Salary Payments Request (طلب صرف المرتبات) — `payments-request` — two prints: `HRScreens/SalaryExchange` and `AccountingReports/BankSalaryPrint` | description row 7 |
| 9 | Employee Accruals (مستحقات الموظفين) — `employee-accruals` — `HRScreens/EmployeeAccrual` | description row 8 |
| 10 | AC1: the print button on every listed screen opens the new print, without `accflex-report-iframe` | acceptance criteria |
| 11 | AC2: the printed document matches the old print — data, totals and logo | acceptance criteria |
| 12 | AC3: the print works in Arabic and English | acceptance criteria |
| 13 | Precedent: monthly-salary print was already converted in CR **125157**; reuse the same approach | Custom.DependenciesandRisks |
| 14 | The bank-salary print ("مرتبات جهة الصرف") already exists as OData (`bank-salary-print-report`) and is to be reused for payments-request | Custom.DependenciesandRisks |
| 15 | Needs AnalyticsReader (AngularPrints) + Web | Custom.DependenciesandRisks |
| 16 | Why: customers cannot edit the old print in the report designer, the look is not unified, and it blocks retiring the old print service | Custom.BusinessJustification |
| 17 | Category Internal Development, customer INTERNAL, environment Beta, work type Web | custom fields |

## Environment
`Custom.Environment = Beta` → Stage Beta; agrees with the CR stage branch `Stage_Beta`.

## Module / screen / tenant
AccFlex Cloud / Payroll / the 8 screens above. No tenant named (internal); number check tenant to choose (sibling CRs used UNP-Ali on db-all).

## Expected vs actual
Expected: new AngularPrints print, same content (fact 1, 11). Actual: legacy iframe print. Not a defect; a migration.

## Attachments
None (no `AttachedFile` relations, no inline images, 0 comments).

## Related
- Sibling CR-125294 (Advance & Purchase **reports** → OData) — different artifacts (accounting-reports list reports), same module; watch for overlap with screens 6–7 here.
- Precedent CR-125157 (monthly-salary print → AngularPrints).

## Open questions
None at intake.
