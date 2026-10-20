---
type: plan
cr: 125307
updated: 2026-10-15
status: running (phase-loop)
gate: approved by the engineer 2026-10-15 ("always continue"), depends-on column as below
set: C:\Hadaf_Work\worktrees\cr125307 (db, erp, front; port offset 200)
---

# CR-125307 — Plan

Inputs for every phase: [[spec]], [[decisions]] (D1–D17), [[business-check-1]], [[legacy-analysis]], [[front-print-buttons]], precedent CR 125157 (`git show a718bd38c` db, `971ca353df` erp, `12372f1b03` front).
Paths: DB = `AccFlex_Cloud_Database\AccFlex_Cloud_Database_State\AccFlex_Cloud_Database_State`; AR = `AccFlex_Cloud_ERP\AccFlex_Cloud_ERP\AnalyticsReader\AnalyticsReader.Api`; FE = `AccFlex_Cloud_Front\accflex-erp`.
Rules: DB `report-database-functions.md` (RowNo BIGINT first, `PR_` prefix, inline TVF preferred), `sqlproj-registration.md` (`<Build>` for functions, `<None>` for scripts); ERP `report-backend.md` (§IAngularPrint, nullable props, HasKey RowNo, auto-discovery); FE `core.md`, `template-bound-getters.md`; root Karpathy guidelines (surgical: only each screen's own print code).

## D12 — BankSalaryPrint contract (fixed here so phases 3, 5, 7 run in parallel)
- TVF `PR_BankSalaryPrint(@PayingSalariesId INT, @BankId INT, @Month DATE, @CurrencyId INT = NULL, @EmployeeIds NVARCHAR(MAX) = NULL, @SecurityLevel INT, @IsArabic BIT)` = legacy `dsBankSalaryPrint.xsd` FillBy; RowNumber reproduced as `ROW_NUMBER()` in the legacy order.
- `printData` (front `moreDataWithPrint`) = ~~JSON~~ **revised in phase 8**: `bankId|yyyy-MM-dd|currencyId|employeeIds(dash-separated)` — the viewer's `HeaderPrintData` is read with `Split(":").Last`, so no ':' or ',,' may appear. HeaderId = SalaryExchangeId; SecurityLevel from `_userSession.SecurityLevel`. Bad input → empty data source (no throw).

## Status (phase-loop, 2026-10-15)
| # | Status | Commit |
|---|---|---|
| 1 | done | db eda42aae9 |
| 2 | done | db ec722825b |
| 3 | done | db 6cd6d5fd7 |
| 7 | done | front d0355119a8 |
| 5 | done | erp a0c5ea609c |
| 6a | done | db 11f15cc26 (+ fix 39577eb37) |
| 6b | done | db 901ea342f |
| 4 | done | db 3f08ed829 |
| 8 | done (with gaps, see [[in-app-check]]) | bank print-data fix: erp bee584ccc6, front 6729358a50 |
- All other TVFs: `PR_<Name>Print(@HeaderId INT, @IsArabic BIT)`.

## Phases

| # | Phase | Files | Done when | Depends on | Wave |
|---|---|---|---|---|---|
| 1 | DB TVFs A + number check: `PR_EmployeeIncomePrint`, `PR_EmployeeAllowancePrint`, `PR_AllowanceSerialPrint`, `PR_EmployeeBonusPrint` (D3, D4, D10) | DB `dbo\Functions\PR_*Print.sql` (4 new); vault `parity\parity-A.sql` | parity-A on UNP-Ali / db-all (CR-125292 `parity\run.sh` pattern, TVF bodies run inline — nothing created on the tenant): 0 divergent rows per print for ≥ 2 real ids each, or "no data" recorded; results in `parity-results.md` | — | 1 |
| 2 | DB TVFs B + number check: `PR_EmployeeAdvancePrint`, `PR_EmployeePurchasePrint`, `PR_SalaryExchangePrint`, `PR_EmployeeAccrualPrint` (incl. C# `DateDifference` in SQL, read from the legacy class; accrual totals copied verbatim from the full `.xsd` text per D13, plus a re-hired and a terminated employee in parity) | DB `dbo\Functions\` (4 new); vault `parity\parity-B.sql` | same as 1 for these 4 | — | 1 |
| 3 | DB TVF C + number check: `PR_BankSalaryPrint` (D12) | DB `dbo\Functions\PR_BankSalaryPrint.sql`; vault `parity\parity-C.sql` | same as 1 | — | 1 |
| 7 | Front: 8 screens → `<log-lgx-print [ApplicationId]="4" [HeaderId] [ReportName] [moreDataWithPrint]>` per D3/D12; remove only each screen's iframe code (D6); payments-request keeps two buttons | FE `projects\payroll\src\app\modules\{employees-incomes,employee-allowances,allowances,bonus,advance,purchase,payments-request,employee-accruals}\…` (files in [[front-print-buttons]]) | `front-verify-build` passes (no new errors vs baseline, prettier clean) | — | 1 |
| 5 | AnalyticsReader: 9 entities + 9 EF configs (`ToFunction`, HasKey RowNo) + 9 `DbSet`s + 9 `IAngularPrint<T>` (`AngularPrints\Payroll\<Name>PrintAng.cs`, ReportName per D3) | AR `ODataViews\Payroll\`, `ODataViewsConfigurations\Payroll\`, `Models\DataContext.cs`, `AngularPrints\Payroll\` | `dotnet build AnalyticsReader.sln` exits 0; each ReportName string grep-equal to D3 | 1, 2, 3 (column lists) | 2 |
| 6a | Layout seeds A (accflex-report-layout): prints 1–4, ar RTL master + en LTR mirror, legacy fields / columns / totals, logo | DB `Scripts\ReferenceDataScripts\0416…0419_PR_<Name>PrintLayout.sql` | 4 files, 2 `InsertLayout` each, ReportName = D3, ApplicationId 4; every bound field exists in the phase-1 TVF | 1 | 2 |
| 6b | Layout seeds B: prints 5, 6, 7a, 7b, 8 (7b landscape kept as legacy) | DB `…\0420…0424_PR_<Name>PrintLayout.sql` | 5 files, same checks against phases 2–3 | 2, 3 | 2 |
| 4 | DB registration + build: 9 `<Build Include="dbo\Functions\…">`, 9 `<None Include="Scripts\ReferenceDataScripts\…">`; re-check no seed number collides with `origin/Master_Stable` | DB `AccFlex_Cloud_Database_State.sqlproj` | VS MSBuild sqlproj 0 errors; dacpac `model.xml` contains the 9 functions | 1, 2, 3, 6a, 6b | 3 |
| 8 | Publish + in-app check: `publish-db.ps1 -Id cr125307` to the test tenant (UNP-Ali), AnalyticsReader on port +200, front on 4200 → print each of the 9 in ar and en | — (vault `in-app-check.md`) | 18 rows (9 × ar/en): opens without iframe, same values as legacy, names/direction per language | 4, 5, 7 | 4 |

Waves: **1** = 1, 2, 3, 7 in parallel · **2** = 5, 6a, 6b · **3** = 4 · **4** = 8. Then the review stop (gate 6: `/review-code 125307`), remove-redundant, ship, Stage Beta deploy (engineer's request).

Commit rules: each implementer commits only its own paths as `cr125307: <phase title>`; parallel phases in one repo touch disjoint files (shared `sqlproj` only in phase 4, `DataContext.cs` only in phase 5); on `index.lock` wait and retry.

## Risks
- Phase 8 publishes the set's DB schema (9 new functions + seed rows) to the test tenant UNP-Ali on db-all — the same tenant the sibling CRs used.
- Accrual working period depends on today's date (legacy `DateTime.Now`): parity compares on the same day.
- Legacy prints with no data on UNP-Ali stay "untested" in parity-results — reported, not passed.
