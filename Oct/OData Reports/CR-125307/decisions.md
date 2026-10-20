---
type: decisions
cr: 125307
updated: 2026-10-15
---

# CR-125307 — Decisions

Sources: [[facts]], [[legacy-analysis]], [[front-print-buttons]], precedent CR 125157 (commits db a718bd38c, erp 971ca353df, front 12372f1b03).

## Size: L
Evidence: 3 repos (db, erp, front); 9 prints (8 screens, payments-request has 2) × (TVF + seed layout ar/en + entity + EF config + DbSet + IAngularPrint + screen wiring) ≈ 60+ files; new SQL objects; new behaviour on 8 screens. → every step, plan gate.

## Decided from the sources
- **D1 Target = AngularPrints, not report-grid printOnlyMode.** The ticket names AngularPrints and 125157 is the precedent: `IAngularPrint<T>` (`AnalyticsReader.Api\Reports\AngularReportHelper\IAngularReport.cs:11-31`), auto-registered by Scrutor, TVF `(@HeaderId INT, @IsArabic BIT)` via `FromSqlInterpolated`, layout from `ACFX_ReportLayout` by ReportName + ApplicationId 4 + language, company header injected by the creator. Front: `<log-lgx-print [ApplicationId]="4" [HeaderId] [ReportName]>` + `ProcessPrint()`. Bends the mvc-to-odata-report-migration skill step 4 (report-grid) — the skill's data-fidelity rule (step 2, 6) still applies in full.
- **D2 Placement / naming** (copy 125157): TVF `dbo\Functions\PR_<Name>Print.sql`; entity `AR\ODataViews\Payroll\<Name>Print.cs`; config `AR\ODataViewsConfigurations\Payroll\<Name>PrintConfigs.cs`; `DbSet` in `Models\DataContext.cs`; print `AR\AngularPrints\Payroll\<Name>PrintAng.cs`; ReportName `<Name>Print` identical in seed, ERP and front.
- **D3 The 9 prints** and their HeaderId:

| # | Screen | ReportName | HeaderId | TVF |
|---|---|---|---|---|
| 1 | salary-items | `EmployeeIncomePrint` | EmployeeId | `PR_EmployeeIncomePrint` |
| 2 | employee-allowances | `EmployeeAllowancePrint` | EmployeeAllowanceId | `PR_EmployeeAllowancePrint` (detail rows + header columns repeated) |
| 3 | allowances | `AllowanceSerialPrint` | AllowanceId | `PR_AllowanceSerialPrint` |
| 4 | bonus | `EmployeeBonusPrint` | EmployeeBonusId | `PR_EmployeeBonusPrint` |
| 5 | advance | `EmployeeAdvancePrint` | AdvanceId | `PR_EmployeeAdvancePrint` (repayment rows + header) |
| 6 | purchase | `EmployeePurchasePrint` | PurchaseId | `PR_EmployeePurchasePrint` (repayment rows + header) |
| 7a | payments-request | `SalaryExchangePrint` | SalaryExchangeId (PayingSalariesId) | `PR_SalaryExchangePrint` |
| 7b | payments-request (bank) | `BankSalaryPrint` | SalaryExchangeId | `PR_BankSalaryPrint` — see Q1 |
| 8 | employee-accruals | `EmployeeAccrualPrint` | EmployeeId | `PR_EmployeeAccrualPrint` (per-currency header + transaction rows) |

  Master-detail prints (2, 3, 5, 6, 8) return one flat row per detail line with the header columns repeated, plus a RowNo; a header with no detail lines still returns one row (detail columns NULL) so the header prints — mirrors the legacy outer relation.
- **D4 Fidelity rules carried into SQL**: 1 keeps the INNER joins to Branch/Department/Job and `IncomeEndDate IS NULL`; 2 keeps AccumulatedBalance without type/currency filter (legacy as-is); 3 returns `AllowancePercentage / 100` when IsPercentage (the C# step); 7b keeps `Suspend = 0`, security level (`_userSession.SecurityLevel`), `SelectSeparateInsuranceItem` and RowNumber = row index; 8 reproduces the C# `DateDifference(StartDate, today)` years/months/days in SQL (algorithm read from the legacy class during the phase) and the per-currency totals by TransactionTypeId.
- **D5 Layout seeds**: one `ReferenceDataScripts` file per print, two `InsertLayout` calls each (ar-EG `الافتراضي` RTL master, en-US `Default` LTR mirror), ApplicationId 4, registered `<None Include>` in the `.sqlproj`. Numbers start at **0416**: 0412 is 125157; 0413–0415 are taken by CR-125294 (pushed, not merged). Re-check the last number before committing.
- **D6 Front**: per screen replace `<accflex-report-iframe-post>` with `<log-lgx-print>`, keep the id the screen already stores on record load, remove only that screen's iframe code (ReportSrc / handleReportSrc / show/hide iframe / now-unused injected services). Shared iframe components and the other 96 usages untouched. Legacy MVC endpoints untouched.
- **D7 Number check**: per print, legacy `.xsd` SQL (+ C# math) vs new TVF on the same tenant and ids, zero divergence; reuse the CR-125292/125294 parity pattern on **UNP-Ali / db-all**; a print with no data there is recorded as untested, not passed.
- **D8 Overlap with CR-125294**: it built list *reports* (`PR_EmployeesAdvanceReport`, `PR_EmployeePurchaseReport`, …); this CR builds per-document *prints* — different objects. Only shared files: `DataContext.cs`, the `.sqlproj`, seed numbering → expect trivial merge conflicts.

## Answers (engineer, 2026-10-15): "yes" — all three recommendations accepted
- **D9 (Q1)** New AngularPrint `BankSalaryPrint`, HeaderId = SalaryExchangeId, bank / month / currency / employeeIds via `moreDataWithPrint`; standalone `bank-salary-print-report` stays legacy.
- **D10 (Q2)** Numbers and rows identical to legacy; names and direction follow the print language (Bonus employee name ar/en; SalaryExchange not inverted).
- **D11 (Q3)** Tenant-customised legacy layouts are not migrated; new prints start from the seeded defaults.

## From business check round 1 ([[business-check-1]], 2026-10-15)
- **D13 (row 3, precision)** Accrual totals: copy the exact column expressions of the legacy `EmployeeCurrencyTransaction` query (incl. the split columns `SalaryAmount` / `VacationAllowanceAmount` / `SeverancePackageAmount` for types 10/11 if the legacy uses them); phase 2 reads the full `.xsd` text, the explorer summary is not the source. Second parity target: the screen's `GetEmployeeTransactionHeaderQuery` totals, reported (a mismatch with the legacy print is a finding, not a blocker).
- **D14 (row 2)** Each screen keeps its existing Print-permission gating (`[checkPrintPermission]` default true on `log-lgx-print`, as 125157).
- **D15 (rows 9, 11)** D10 per PG-40: Arabic prints read `EmployeeArabicName` (fallback `EmployeeName`) in all 9 TVFs. AllowancePercentage: divide by 100 in SQL **or** format as percent in the layout — never both.
  - Applied (phase 6a): TVF returns AllowancePercentage/100, layout keeps the legacy `{0:0.00%}` format → prints 12.50% exactly as legacy. One division, one display scaling — same as legacy.
- **D18 (phase 3)** BankSalaryPrint RowNo order = `CurrencyNameArabic, AccountNo, Description, Total, EmployeeId`: legacy `DISTINCT` had no ORDER BY, so its numbering followed the query plan's sort; this order reproduced it on every row of both tenants and makes it deterministic. Legacy production actually ran `Fill` (the front's `payingsalaryid` was ignored); the TVF follows `FillBy` per D12 — 0 Fill vs FillBy differences measured, they can differ only if the document's BankId ≠ the passed bankId, which the front never sends.
- **D16 (row 8)** Housing = IncomeId 3 in 7b is a tenant assumption carried from legacy, same as OData `BankSalaryReport`.
- **D17 (rows 1, 4, 5, 6, 7) — known legacy behaviour, reproduced, not fixed here** (the CR's acceptance is "identical to the old print"): (1) prints 1 and 8 apply no security level — the screen already scopes which employee is open; (4) accrual working period runs to today, also for terminated staff; contract row picked as legacy does; (5) Employee Allowance AccumulatedBalance ignores type/currency; (6) SalaryExchange AccountNo = the employee's first bank account, not the one for the request's bank; (7) customised legacy bank-sheet layouts must be re-done in the designer after release (roll-out note in the ship report); (8) Advance print "Paid Amount" = the repayment `Amount` (legacy aliases `Amount AS PaiedAmount`), not a separate paid figure (review-1 row 4); (9) BankSalaryPrint parses `@EmployeeIds` with `Acc_ConvertStringListToTable` like the legacy query and `PR_BankSalaryReport`, not the rule's IntList helper (review-1 rows 5/7). Listed for a PO follow-up; proposed as a separate ticket, not part of 125307.

## Questions for the engineer (one message, 2026-10-15)
- Q1 Bank-salary print: the ticket says reuse an existing OData `bank-salary-print-report`, but only the grid report `BankSalaryReport` exists; the print is still legacy (`bank-salary-print-shell.component.ts:97`). Recommended: new AngularPrint `BankSalaryPrint`, HeaderId = SalaryExchangeId, bank / month / currency / employeeIds passed through `moreDataWithPrint` (the `printData` arg), reproducing legacy `FillBy`; the standalone `bank-salary-print-report` screen stays on the legacy print (not in the ticket's table).
- Q2 Legacy language quirks: Bonus prints the English employee name in Arabic; SalaryExchange has its Arabic/English layout key and RTL inverted. Recommended: keep every number and row identical, but let names and direction follow the print language (AC3).
- Q3 Tenant-customised legacy layouts (stored by the old report `Name`) are not migrated; the new prints start from the seeded defaults. Recommended: yes.

- **D19 (review-1)** BankSalaryPrint needs its print data, which only the DevExpress viewer path passes (`HeaderPrintData`); AnalyticsReader's server PDF / XLS / email export paths call `GetDataSource(headerId, string.Empty)` and get an empty print — the same pre-existing limitation as BarcodePrintPrinter / QuotationRequestPrint. payments-request uses the viewer (`printWithServerPdf` false), so the screen works; don't switch it to server PDF without extending those paths.
