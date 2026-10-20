---
type: source
cr: 125299
updated: 2026-10-14
---

# CR-125299 — Source

- ADO: https://hadafsolutions.visualstudio.com/AccFlex_ERP/_workitems/edit/125299 — Change Request, **New**, assigned Mohamed Saeed, area `AccFlex_ERP\3- Customer Issues`, parent 68226.
- Kind `cr` → branch `cr125299` off `Master_Stable`; first PR `Stage_Beta`, second `Master_Stable` (Merge Desk opens both on Solved).
- Title (Arabic, lost by az cp1252 output): "… ODATA". Description: move the legacy print viewer / iframe reports to OData on AnalyticsReader (OData Entity + EF Config + DbSet + Angular Report) shown in the Report Grid.

| # | Report | Web route | Old print report | Route ModuleId |
|---|---|---|---|---|
| 1 | Medical Insurance | `human-resource-reports/insurance-report` | `HrReports/EmployeesMedicalInsurance` | none on route (to find) |
| 2 | Employee Save | `human-resource-reports/employee-save-report` | `HrReports/EmployeeSaveReport` | 767 |
| 3 | Employee Statistics | `employee-statistics` | `HrReports/EmployeeStatistics` | 459 |
| 4 | Risk Analysis - Settlements | `risk-analysis-settlements` | `HrReports/RiskAnalysis` | 343 |

Acceptance criteria (Arabic text partly lost; English parts):
- Data served from `analyticsreaderapi/odata`, no `accflex-report-iframe`.
- Same data as the old report (same filters).
- Export (Excel / PDF) and print from the Report Grid.
- Permissions by ModuleId.
