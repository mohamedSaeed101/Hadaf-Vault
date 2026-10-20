# CR-125288 — facts (ticket)

Source: ADO 125288, read 2026-10-15.
- Type: Change Request.
- Program: General Accounting.
- Board: State In Development, assigned to Mohamed Saeed.
- Parent: 67920.
- Title: تحويل تقارير أرصدة أول المدة والموازنة التقديرية الى ODATA.
- The ticket has no comments and no attachments.
- The engineer settled the decisions in [[decisions]] (D1–D3). Where the ticket text is open, those decisions win.

## Scope (ticket table)

| # | Report | Web route | Legacy print |
|---|---|---|---|
| R1 | تقرير ارصدة اول المدة / Period Balance Report | `advanced-reports/period-balance` | PeriodBalance |
| R2 | الموازنه التقديرية خلال فترة / Period Estimated Budget | `advanced-reports/period-estimated-budget` | EstimatedBudgetPeriodcs |
| R3 | الموازنه التقديرية بالشهر / Estimated Budget By Month | `advanced-reports/estimated-budget-month` | EstimatedBudgetByMonth |
| R4 | الموازنه التقديرية باليوم / Estimated Budget By Day | `advanced-reports/estimated-budget-day` | EstimatedBudgetByDay |

The target pattern is an OData report in AnalyticsReader (entity, EF config, DbSet, Angular report) plus a Report Grid screen on the web. Filters, columns and results stay the same as today.

## Acceptance (ticket, numbered here)

- **A1** Each report reads its data from `analyticsreaderapi/odata`, without `accflex-report-iframe`.
- **A2** Filters, results and totals are the same as the old print, compared on the same data.
- **A3** Print and export (Excel / PDF) from the Report Grid work in Arabic and English.
- **A4** Each report keeps its current permissions (ModuleId): R1 361, R2–R4 362.

## Dependencies and risks (ticket)

- The work touches DB TVFs, AnalyticsReader and the Web.
- Numbers must be compared with the old print on the same data before delivery.
- Keep the old print as legacy for now, as was done for the balance sheet (123513) and total salaries.

## Where the evidence is

- Parity for A2: [[parity-125288]].
- App check for A1, A3 and A4: [[p6-app-check]].
- Contracts: [[CR-125288 - Plan]].
- No `spec.md` exists. The plan's contracts plus [[decisions]] serve as the spec.
