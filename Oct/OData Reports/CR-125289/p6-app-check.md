# CR-125289 — P6 app check (2026-10-15)

Clears review-1 row 1 (block, AC3), apart from the layout finding below.

## Setup

- **Tenant:** `unp-ali`, database `UNP-Ali` on `db-all`, company **UNP-Ali**, signed in through the localbeta identity. The identity session already existed in Chrome; the agent only picked UNP-Ali on SelectTenant. No credentials were typed.
- **Targeted deploy (no full dacpac, nothing else touched):** sqlcmd `-f 65001`, all exit 0.
  - The 9 TVFs did not exist on UNP-Ali, so the files ran as-is (`CREATE FUNCTION`): Acc_BriefIncomeStatementReport, Acc_CostCenterBriefIncomeStatementReport, Acc_BranchBriefIncomeStatementReport, Acc_IncomeStatementByBranchReport, Acc_IncomeStatementByBranchProductionReport, Acc_IncomeStatementByCostCenterReport, Acc_IncomeStatementCostCenterPeriodReport, Acc_IncomeStatementBranchPeriodReport, Acc_IncomeStatementPerPeriodReport.
  - Seeds `0431` and `0432` ran: 18 rows, no earlier layouts with these names existed.
  - **Layout ids 2840–2857**, ar-EG then en-US: R1 2840/2841, R2 2842/2843, R3 2844/2845, R4 2846/2847, R5 2848/2849, R6 2850/2851, R7 2852/2853, R8 2854/2855, R9 2856/2857. ApplicationId 1, IsDefault 1. Arabic text stored intact (checked in 2840).
- **Local services** (cr125289 worktree build, Debug, `BaseOutputPath` in the session scratchpad, 0 errors):
  - AnalyticsReader on `https://localhost:5555` and GL API on `https://localhost:5502` (offset 500).
  - Overrides were process environment variables only: `ASPNETCORE_ENVIRONMENT=Development`, `Authority=https://accesscontrol.localbeta.hadaf.website/`, `ConnectionStrings__DebugTenantConnection` → db-all / UNP-Ali, Serilog Debug. No `appsettings*.json` or `launchSettings.json` was edited. `HKLM\Software\Hadaf\Apis` has no SQLSERVER* values.
  - GL API's Hangfire logs SQL error 1326 against its configured server (unrelated to this check; GL lookups worked).
  - Front `npm run dev` on `http://localhost:4200`; `config.json` `analyticsreaderapi` → `https://localhost:5555/`, `generalledgerapi` → `https://localhost:5502/api`.
- **Params used everywhere** (the screens' defaults): from 2025-10-01, to 2026-10-15, revised = both, all 95 journal types, all 17 branches; cost center 1 (the only one) where the screen requires it (R2 UI, R7).

## Override proof

- AnalyticsReader log 20:19:42: `DEBUG: Overriding tenant connection string with DebugTenantConnection` (GL log: 6 such lines).
- `sys.dm_exec_sessions` on db-all for `UNP-Ali`: 5 sessions from `DESKTOP-KPT7EFB`, program "Core Microsoft SqlClient Data Provider", last request 20:20:34, which is the R1 grid request in the API log.
- The R1 grid shows Operating income 1,876,185.13 / expenses 4,195,321.985 / net 2,319,136.855, the same as the TVF on UNP-Ali.

## Results

Data on UNP-Ali: `Acc_IncomeStatmentSubItem` is empty and no account has `IncomeStatment` set, so R4, R5, R6 and R9 return 0 rows (legacy behaviour; their numbers rest on P5 parity). Journals carry no cost center, so R2 and R7 values are 0 / NULL.

| Report (route) | Screen: ar title, "طباعة (التصميم السابق)" | Grid `$query` vs SQL | PDF ar / en (pages) | XLS ar / en | Print totals vs SQL |
|---|---|---|---|---|---|
| R1 BriefIncomeStatementReport (`brief-income-statment-report`) | OK, grid in UI 9 rows | 200, 9 = 9 | 200 / 200 (5 / **27**) | 200 / 200 | Net profit (2,319,136.85) ar and en = SQL 2,319,136.8548, parentheses rule applied |
| R2 CostCenterBriefIncomeStatementReport (`brief-income-statment-costcenter-report`) | OK; cost center is required before Show (legacy form); grid in UI 7 rows with cc 1 | 200, 7 = 7 | 200 / 200 (3 / 21) | 200 / 200 | — |
| R3 BranchBriefIncomeStatementReport (`brief-income-statment-branche-report`) | OK, grid in UI with ar captions | 200, 21 = 21 | 200 / 200 (10 / **77**) | 200 / 200 | Net profit -2,319,136.85 (ar) = SQL -2,319,136.8548 |
| R4 IncomeStatementByBranchReport (`income-statment-branche-report?report=IncomeStatemetBranchs`) | OK | 200, 0 = 0 | 200 / 200 (1 / 5, empty) | 200 / 200 | no data (0 = 0) |
| R5 IncomeStatementByBranchProductionReport (`income-statment-branche-report-production?report=IncomeStatemetBranchsProduction`) | OK | 200, 0 = 0 | 200 / 200 (1 / 11, empty) | 200 / 200 | — |
| R6 IncomeStatementByCostCenterReport (`income-statment-costcenter-report?report=IncomeStatementCostCenter`) | OK | 200, 0 = 0 | 200 / 200 (1 / 6, empty) | 200 / 200 | — |
| R7 IncomeStatementCostCenterPeriodReport (`income-statment-activity-detail-report?report=IncomeStatementActivityDetail`) | OK | 200, 6 = 6 (cc 1) | 200 / 200 (2 / 18) | 200 / 200 | Net profit 0.00 ×3 periods = SQL 0.0000; period headers 2025/10/01–2026/10/15, 2024/09/16–2025/10/01, 2024/10/01–2025/10/15 |
| R8 IncomeStatementBranchPeriodReport (`income-statment-barnche-detail-report?report=IncomeStatmentBranchPeriod`) | OK, grid in UI with the 12 ar period captions | 200, 21 = 21 | 200 / 200 (9 / **77**) | 200 / 200 | — |
| R9 IncomeStatementPerPeriodReport (`income-statment-arbic-period-report?report=IncomeStatemetPerPeriod`) | OK | 200, 0 = 0 | 200 / 200 (1 / 4, empty) | 200 / 200 | no data (0 = 0) |

All 18 layouts loaded and rendered; no missing-field or layout-load error appeared in a response or in the API log. Every PDF starts `%PDF`, and every XLS is an xlsx zip (`PK`).

Grid preview and exports were called with the signed-in token from the page (`POST odata/<Name>/$query`, `POST angular/AngularReportPdf|Xls?reportName=&layoutId=` with the grid's `{filters, queryOptions}` body), as in cr125288. R1, R2, R3 and R8 grids were also loaded through the screens' Show button.

Screenshots: `p6-R1-en-pdf-p1.jpg`, `p6-R1-en-pdf-p27.jpg`, `p6-R1-ar-pdf-p5.jpg`, `p6-R3-ar-pdf-p10.jpg`, `p6-R7-ar-pdf-p2.jpg`, `p6-R2-grid-ar.jpg`.

## Findings

1. **Journal-type filter cell blows up the page header (all 18 layouts, worst in en).** The screens preselect all journal types, so `journalTypeFilter` lists all 95 names. That cell sits in the PageHeader and grows until the header fills almost the whole page, which leaves room for about one detail band per page:
   - R1 en: 27 pages for 9 rows, and page 27 is a header only. The Net Profit row is drawn under the next header at the page foot, and the journal-type text is cut off at the cell bottom ("…Good Receipt From Cancellation Good Issue").
   - R3 en and R8 en: 77 pages for 21 rows. R4, R5, R6 and R9 en are 4–11 pages with 0 rows.
   - ar is smaller but has the same shape: R1 5 pages, R3 10 pages, R8 9 pages.
   - With `journalTypes` empty, R1 en is 1 page, R3 en 2 pages and R4 en 1 page, which confirms the cause.
   - Fix direction (not applied, per the instructions): the same treatment cr125288 gave the branch cell, i.e. `TextFitMode="ShrinkOnly"` plus a fixed height, or move the filter block to ReportHeader. A print "All" text when every type is selected would be a separate front/Ang change.
2. **Cost-center screens require a cost center before Show** (R2, R6, R7). This is the legacy form's own validation, and it is unchanged.
3. Branch names print `Branch_N` in ar and `فرع_N` in en. This is the data, not a bug: on UNP-Ali `BranchName` is English and `BranchNameSecondLanguage` is Arabic.

## Restored

- `config.json` restored with `git restore`. No appsettings or launchSettings edits were made; the overrides were process env vars only.
- AnalyticsReader (5555), GL (5502) and `npm run dev` (4200) were stopped and confirmed down.
- The TVFs and layouts 2840–2857 stay on UNP-Ali, as in cr125288. Nothing was committed.
