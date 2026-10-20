# CR-125289 — facts

Ticket: https://hadafsolutions.visualstudio.com/AccFlex_ERP/_workitems/edit/125289
- Type: **Change Request**. Program: General Accounting. State: New. Assigned to Mohamed Saeed. Parent: 67934. Due 2026-12-31.
- Title: تحويل تقارير قائمة الدخل (المختصر والتفصيلي بالفروع ومراكز التكلفة) الى ODATA
- Stage branch: `Stage_Beta` (Change Request). Base: `Master_Stable`.
- Set: `D:\Hadaf\worktrees\cr125289` (db, erp, front). Branch `cr125289`. Port offset 500. Created 2026-10-15.

## Scope: 9 reports

| # | Name | Route | Shell |
|---|---|---|---|
| 1 | Brief Income Statement | financial-reports/brief-income-statment-report | BrifIncomeStatmentReportShell |
| 2 | Brief Income Statement by Cost Center | financial-reports/brief-income-statment-costcenter-report | BrifIncomeStatmentCostcenterReportShell |
| 3 | Brief Income Statement by Branch | financial-reports/brief-income-statment-branche-report | BrifIncomeStatmentBrancheReportShell |
| 4 | Income Statement by Branch | financial-reports/income-statment-branche-report (report=IncomeStatemetBranchs) | BrifIncomeStatmentBrancheReportShell |
| 5 | Income Statement by Branch (Production) | financial-reports/income-statment-branche-report-production (IncomeStatemetBranchsProduction) | BrifIncomeStatmentBrancheReportShell |
| 6 | Income Statement by Cost Center | financial-reports/income-statment-costcenter-report (IncomeStatementCostCenter) | BrifIncomeStatmentCostcenterReportShell |
| 7 | Income Statement Activity Detail | financial-reports/income-statment-activity-detail-report (IncomeStatementActivityDetail) | BrifIncomeStatmentCostcenterReportShell |
| 8 | Income Statement Branch Detail | financial-reports/income-statment-barnche-detail-report (IncomeStatmentBranchPeriod) | BrifIncomeStatmentBrancheReportShell |
| 9 | Income Statement (Arabic) per Period | financial-reports/income-statment-arbic-period-report (IncomeStatemetPerPeriod) | BrifIncomeStatmentReportShell |

## Acceptance criteria (from the ticket)
1. Every report reads from analyticsreaderapi/odata. It does not use accflex-report-iframe.
2. Same filters, results and totals as the legacy print on the same data.
3. Print and export (Excel / PDF) from the Report Grid work in Arabic and English.
4. Same permissions (ModuleId) per report.

## Dependencies and risks (from the ticket)
- Needs DB TVFs, AnalyticsReader and Web changes.
- Numbers are compared to the legacy print on the same data before delivery.
- Keep the legacy print temporarily, as in 123513 (balance sheet) and the payroll totals report.
- `income-statment-report` was already migrated in 123252. Reuse its OData and layout where possible. Several routes share one screen with different ModuleIds.

## Notes
- The main checkout `D:\Hadaf\AccFlex_ERP` (legacy) is on branch `cr94062`. Legacy sources are read against `origin/Master_Stable`.
- `az boards` is unavailable (no azure-devops extension), so the ticket was read through the ado MCP.
