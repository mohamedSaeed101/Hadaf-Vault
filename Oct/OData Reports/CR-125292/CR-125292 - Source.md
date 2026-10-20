---
type: cr-source
cr: 125292
customer: INTERNAL
tags: [cr, cr-125292, source, payroll, odata, report-migration]
---

> [!note] Facts read from ADO work item 125292 on 2026-10-14. The plan is in [[CR-125292 - Plan]]; the legacy analysis per report is in the four `Legacy - …` notes.

# CR #125292 — تحويل تقارير المرتبات الى ODATA

| Field | Value |
|---|---|
| Type | Change Request → `cr125292`, stage `Stage_Beta`, Merge Desk version `Beta` |
| State | New (board column New), created by Muhammed Tariq 2026-10-13 |
| Program | PayRoll; work type Web; environment Stable |
| Area | AccFlex_ERP\3- Customer Issues; Category Internal Development; customer INTERNAL |
| Parent | 68516 |
| Due date | 2026-12-31 |
| Precedent named by the ticket | Total Salaries: fx123253 (OData, print-only) + fx124062 (legacy print kept alongside) |
| Sibling CR | 125294 (advance and purchase payroll reports to OData), set `worktrees\cr125294`, uncommitted, local branch only |

## Scope (from the description)

Convert from the legacy print viewer (iframe) to AnalyticsReader OData (entity + EF config + DbSet + Angular report) with a Report Grid screen, **same filters, columns and results**.

| # | Report (AR) | Report (EN) | Web route | Legacy MVC route |
|---|---|---|---|---|
| 1 | مرتبات الموظفين | Employee Salaries | `accounting-reports/salary-report` | `AccountingReports/EmployeeSalaries` |
| 2 | مرتبات الموظفين ملخص | Employee Summarized Salaries | `accounting-reports/salary-details-report` | `AccountingReports/EmployeeSalaryDetails` |
| 3 | مرتبات الموظفين تفصيلي | Employees Detailed Salaries | `accounting-reports/employees-detailed-salaries-report` | `AccountingReports/EmployeesDetailedSalaries` |
| 4 | مرتبات الموظفين خلال فترة | Employees Salaries In Period | `accounting-reports/employees-salaries-in-peroid-report` | `AccountingReports/EmployeeSalariesInPeroid` |
| 5 | المرتبات بفئة الدخل | Salaries By Income Group | `accounting-reports/salary-by-income-report` | `AccountingReports/SalaryByIncome` |
| 6 | تقرير المرتبات الشهرية للإدارات | Departments Monthly Salaries | `accounting-reports/departments-monthly-salaries-report` | `AccountingReports/DepartmentSalary` |
| 7 | الموظفين الذين لم يتم اصدار مرتباتهم | Employees With No Issued Salaries | `accounting-reports/no-salary-issued-report` | `AccountingReports/NoSalaryByIssued` |
| 8 | المرتبات المعتمدة | Posted Salaries | `accounting-reports/posted-salary-report` | `AccountingReports/PostedSalary` |

## Acceptance criteria

1. Each report reads from `analyticsreaderapi/odata`, no `accflex-report-iframe`.
2. Same filters, results and totals as the legacy print, compared on the same data.
3. Print and export (Excel / PDF) from the Report Grid work in Arabic and English.
4. Same permissions as today (ModuleId) per report.

## Business value / justification (summary)

Users cannot filter, sort, group or export from the iframe screens and do not get the new print designs. Moving to OData unifies report screens across programs and lets the legacy print service be switched off later.

## Dependencies and risks (from the ticket)

- Needs DB (TVFs) + AnalyticsReader + Web.
- Numbers must be compared with the legacy print on the same data before delivery.
- Keep the legacy print temporarily, as done for Total Salaries (123253 / 124062).

## Legacy facts (summary of the four analysis notes)

| # | rpt class (= saved-layout key) | DataSet | Menu ModuleId | Route ModuleId today | Security-level filter |
|---|---|---|---|---|---|
| 1 | `rptSalarySignature` | `dsSalary` | 514 | none (admins only) | no |
| 2 | `rptEmployeeSalaryDetails` | `dsSalary` | 537 | 537 | no |
| 3 | `rptEmployeesSalariesDetails` | header + income lines | 542 | 542 | no |
| 4 | `rptEmployeeSalariesBetweenPeriod` | single query, AR/EN variants | 543 | inherits 285 | yes |
| 5 | income-group report | embedded SQL | 539 | none (admins only) | no |
| 6 | department salary report | embedded SQL | 540 | 540 | yes |
| 7 | `rptEmployee` (`FillByNoSalaryIssued`) | `dsEmployee` | 538 | none (admins only) | no |
| 8 | `rptPostedSalaryFormReport` (`FillPosted`) | `dsDepartmentSalary` | 541 | 541 | yes (static) |

- Every SQL table and function the legacy queries use exists in `AccFlex_Cloud_Database` on `origin/Master_Stable` (8a3f097c5) and is in the `.sqlproj`. Nothing is missing.
- `PR_EmployeeTotalSalariesReport` cannot be reused by any of the 8 (different grain, excludes vacation salaries, own totals). Each report gets a new TVF over the same base tables; only its conventions carry over (inline TVF, `@Month`/`@Year`/`@SecurityLevel`, `Acc_ConvertIntListToTable`, `ROW_NUMBER` key, layout seed).
- No report pivots salary items into columns; every entity has a fixed column set. Reports 2 and 3 are master-detail (employee → income lines).
- Legacy parameters arrive by form POST (`report-iframe-post`), lists as CSV, `month` as an ISO date of which only month and year are used.
- Legacy layouts live in the designer `.cs` files (no `.repx` on disk). A per-user override is read from `dbo.ACFX_ReportLayout`, the same table the cloud uses, keyed by the rpt class name: new layout names must not reuse these keys. (The skill's `legacy-anatomy.md` says these are separate stores; that is wrong for this controller.)
- Several reports have no `ORDER BY`: parity is a set comparison, not a row-by-row one.

## Legacy defects found (fidelity decisions, see [[open-questions]] Q4)

- **R6, R8:** the end-of-work join is by `EmployeeId` only. An employee whose end of work falls in the month pulls in all of their historical salary rows relabelled with the end-work amounts; `SELECT DISTINCT` then both inflates and collapses totals.
- **R8:** `@EmployeeIdList` is `VarChar(1024)`; "all employees" on a large tenant is silently truncated (and a cut-off id can match another employee).
- **R3:** an employee with more than one bank account in the salary currency prints twice; the company-insurance total is double-counted.
- **R4:** the "Main Salary" column and its footer are bound to `InsuranceCompany`, not `BasicSalary`.
- **R5:** the employee header band has no group field, so only the first employee's header prints (layout only).
- **R6:** Currency and Salary Source print in Arabic in English too.
