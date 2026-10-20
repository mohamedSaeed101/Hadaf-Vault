---
type: source
cr: 125294
read: 2026-10-13
---

# CR-125294 — Source (ADO work item)

**Title:** تحويل تقارير السلف والمشتريات الى ODATA
**Type / state:** Change Request, In Development (board column: acknowledged, lane STABLE)
**Created by:** Muhammed Tariq, 2026-10-13 · **Assigned:** Mohamed Saeed · **Due:** 2026-12-31
**Program:** PayRoll · **Work type:** Web · **Customer:** INTERNAL · **Category:** Internal Development · **Parent:** 68514
**Comments / attachments:** none

## Description (summary)

Move these reports from the legacy print viewer (iframe) to the AnalyticsReader OData pattern (OData entity + EF config + DbSet + Angular report) with a Report Grid web screen, keeping the same filters, columns and results.

| # | Arabic | Name | Web route | Old print report |
|---|---|---|---|---|
| 1 | رصيد سلف الموظفين | Unpaid Advance Payments | `accounting-reports/unpaid-advanced-payments` | `AccountingReports/EmployeeUnPaidAdvancedPaymentsBalance` |
| 2 | تقرير السلف | Employees Advance Report | `accounting-reports/advance-report` | `AccountingReports/EmployeesAdvance` |
| 3 | المشتريات | Employee Purchase | `accounting-reports/employee-purchase` | `AccountingReports` (iframe-post) → `EmployeeDecucations` |

## Acceptance criteria

1. Each report reads from `analyticsreaderapi/odata`, no `accflex-report-iframe`.
2. Same filters, same results and totals as the old print (compared on the same data).
3. Print and export (Excel / PDF) from the Report Grid work in Arabic and English.
4. Same permissions (ModuleId) per report.

## Dependencies / risks (from the ticket)

- Needs DB (TVFs) + AnalyticsReader + Web changes.
- Numbers must be compared with the old print on the same data before delivery.
- `advance-transactions` was already migrated to OData — reuse it where possible (it is the sibling template used here).
