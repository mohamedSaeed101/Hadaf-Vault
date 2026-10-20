# CR-125291 — facts

Ticket: https://hadafsolutions.visualstudio.com/AccFlex_ERP/_workitems/edit/125291
Type: Change Request (General Accounting, Web, Stable lane). State New, assigned Mohamed Saeed. Parent 27458. Due 2026-12-31.
Title: تحويل تقارير القوائم المالية (الميزانية المختصرة والمقارنة - المركز المالي - التدفقات النقدية - حقوق الملكية) الى ODATA

Kind cr → branch `cr125291` off `Master_Stable`; first PR → `Stage_Beta`, second → `Master_Stable`.
Merge Desk ticket 12513 (Beta, Acknowledge), created 2026-10-15 with Database / API / WebContainer branches; components Database, AnalyticsReader, Web Container.
Set: `D:\Hadaf\worktrees\cr125291` (db, erp, front), port offset 600. Front `node_modules` is not linked (package.json differs); run `npm install` with `SKIP_INSTALL_SIMPLE_GIT_HOOKS=1` before the front gate.

## Scope (5 reports)
| # | ar | en | route | shell |
|---|---|---|---|---|
| 1 | الميزانية المختصرة | Brief Balance Sheet | financial-reports/brief-general-balance | OneDateShell |
| 2 | الميزانية المقارنة | Comparative Balance Sheet | financial-reports/compare-balance-sheet | OneDateShell |
| 3 | قائمة المركز المالي | Statement of Financial Position | financial-reports/financial-position-statement | OneDateShell |
| 4 | تقرير التدفقات النقدية | Cash Flow Report | financial-reports/cash-flow | CashFlowShell |
| 5 | تقرير التغير في حقوق المساهمين | Equity Changing Report | financial-reports/equity-changing | EquityChangingShell |

## Acceptance
1. Each report reads from analyticsreaderapi/odata, no accflex-report-iframe.
2. Same filters, same results and totals as the legacy print (compared on the same data).
3. Print and export (Excel / PDF) from the Report Grid work in Arabic and English.
4. Same permissions (ModuleId) per report.

## Risks / notes from the ticket
- DB (TVFs) + AnalyticsReader + Web.
- Numbers must be compared against the legacy print on the same data before delivery.
- Balance sheet (financial-reports/balance-sheet) was migrated in 123513 (on Stage_Stable / CurrentRelease). Reports 1–3 use the same OneDateShell; reuse 123513's work where possible.

## Found at intake
- `origin/fx123513` is **not** in `Master_Stable` (checked 2026-10-15). Its files (`Acc_BalanceSheetReport`, layout seed `0408`, `BalanceSheetReport*`, `balance-sheet-print-report-shell`, and a 1-line change in `one-date-form`) are a pattern to copy, not a base. `one-date-form` is a merge-overlap point with fx123513.
- Sibling CRs in the same family: 125288, 125289, 125290, 125292, 125294 (vault `Oct\OData Reports\CR-<id>`). Their decisions D1 (full grid, not printOnlyMode), D2 (exact numbers, English variant as reference), D3 (old print kept as "Print (previous design)") are the house precedent for this family.
