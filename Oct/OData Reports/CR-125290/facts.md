# CR-125290 — facts

Ticket: https://hadafsolutions.visualstudio.com/AccFlex_ERP/_workitems/edit/125290
Type: Change Request (General Accounting, Web, Stable lane). State In Development, assigned Mohamed Saeed. Parent 67933.
Title: تحويل تقارير قائمة الدخل بالفترات والمقارنة بالموازنة الى ODATA

Kind cr → branch `cr125290` off `Master_Stable`; first PR → `Stage_Beta`, second → `Master_Stable`.
Set: `D:\Hadaf\worktrees\cr125290` (db, erp, front), port offset 400.

## Scope (5 reports)
| # | ar | en | route | shell |
|---|---|---|---|---|
| 1 | تقرير قائمة الدخل مراكز تكلفة شهر / سنة | Income Statement by Cost Center Month / Year | financial-reports/income-statment-activity-budget-report | IncomeStatmentPeriodsReportShell |
| 2 | تقرير قائمة الدخل فروع شهر / سنة | Income Statement by Branch Month / Year | financial-reports/income-statment-branch-budget-report | IncomeStatmentPeriodsBranchReportShell |
| 3 | تقرير قائمة الدخل بمركز التكلفة مقارن تقديري | Cost Center Income Statement vs Budget | financial-reports/costcenter-income-statment-budget-report | CostcenterIncomeBudgetShell |
| 4 | تقرير قائمة الدخل بالفرع مقارن تقديري | Branch Income Statement vs Budget | financial-reports/branch-income-statment-budget-report | BranchIncomeBudgetShell |
| 5 | تقرير قائمة الدخل التفصيلي بالشهور (عربي) | Income Statement Arabic per Month | financial-reports/branch-statment-arbic-month-report | BranchStatmentMonthReportShell |

## Acceptance
1. Each report reads from analyticsreaderapi/odata, no accflex-report-iframe.
2. Same filters, same results and totals as the legacy print (compared on the same data).
3. Print and export (Excel / PDF) from the Report Grid work in Arabic and English.
4. Same permissions (ModuleId) per report.

## Risks / notes from the ticket
- DB (TVFs) + AnalyticsReader + Web.
- Numbers must be compared against the legacy print before delivery.
- Keep the legacy print temporarily (as in 123513 balance sheet and total salaries).
- Detailed income statement (income-statment-report) was migrated in 123252; reuse its OData where possible.
